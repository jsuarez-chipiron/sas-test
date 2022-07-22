/**
 * @param claim a LIA_Claim__c to be automated
 * @param booking a BookingJSON associated with the claim
 *
 * Utility class which handles case/claim automation
 * Contains all information needed (not currently) to automate a claim.
 * Investigate: Can people in the same booking have different amount of flights?
 */
public without sharing class AutomationUtils {
  public class AutomationContainer {
    public String type;
    public LIA_Claim__c claim;
    public BookingJSON booking;
    public Boolean isAutomatable;
    public String originAirport; // Todo: Rethink
    public String destinationAirport;
    private String status; // Unhandled, Rejected, Pending, PaidOut
    private Integer EU261Compensation = 0;
    private Decimal careCompensation = 0.0; // Currently not supported

    public AutomationContainer(LIA_Claim__c claim, BookingJSON booking) {
      this.type = booking.type;
      this.isAutomatable = isSupportedForAutomation(claim, booking);
      this.claim = claim;
      this.booking = booking;
      this.status = 'Unhandled';

      // TODO: Rethink, extend:
      BookingJSON.Flight flight = getRelevantFlight(this);
      this.originAirport = flight.departureAirport;
      this.destinationAirport = flight.arrivalAirport;
    }

    public Decimal getTotalCompensation() {
      return Decimal.valueOf(EU261Compensation) + careCompensation;
    }

    public void rejectClaim() {
      if (this.status != 'Pending') {
        throw new AutomationException('Incorrect status change.');
      } else {
        this.status = 'Rejected';
      }
    }

    // Todo: Implement
    public void payOutClaim() {
      if (this.status != 'Pending') {
        throw new AutomationException('Incorrect status change.');
      } else {
        this.status = 'PaidOut';
      }
    }

    public void handleClaim() {
      if (this.status != 'Unhandled') {
        throw new AutomationException('Incorrect status change.');
      } else {
        this.status = 'Pending';
      }
    }

    public String getStatus() {
      return status;
    }
  }

  /**
   * @param claimIds a Set of Ids of the claims to be automated
   *
   * Todo: Rethink, make batchable, make testable (guard for callouts)
   * Todo: If rejected, add a information to the case/claim.
   *
   * @return A map from claim id to whether or not that claim has been automated.
   */
  public static Map<Id, Boolean> automateEU261(Set<Id> claimIds) {
    Map<Id, Boolean> claimToWasAutomated = new Map<Id, Boolean>{};

    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectByIdWithCustomers(claimIds);

    for (LIA_Claim__c c : claims) {
      claimToWasAutomated.put(c.Id, false);
    }

    List<AutomationContainer> claimsToAutomate = gatherInfoAboutClaimsToAutomate(
      claims
    );
    List<AutomationContainer> handledClaims = new List<AutomationContainer>{};
    for (AutomationContainer ac : claimsToAutomate) {
      // Was the flight from/to the right place + insanely complex edge case
      if (!isCoveredByEU261(ac)) {
        System.debug('This claim is not covered by EU261');
        continue;
      }

      // TEST: Determine if the claim is filed on time
      if (!isFiledOnTime(ac)) {
        System.debug('This claim was not filed on time');
        ac.handleClaim();
        ac.rejectClaim();
        handledClaims.add(ac);
        continue;
      }

      // TODO: Determine if a claim is a duplicate
      if (isDuplicate(ac)) {
        System.debug('This claim is a duplicate');
        handledClaims.add(ac);
        continue;
      }
      // TODO: ~Check proactivities

      // TODO: Determine if it is a delay or a cancellation and handle differently
      if (true) {
        ac.handleClaim();
        handledClaims.add(automateEU261Delay(ac));
      } else {
        //claimToWasAutomated.put(ac.claim.Id, automateEU261Cancellation(ac));
      }
    }

    for (AutomationContainer ac : handledClaims) {
      switch on ac.getStatus() {
        when 'PaidOut', 'Rejected' {
          claimToWasAutomated.put(ac.claim.Id, true);
        }
        when 'Unhandled' {
          // Fill the case/claim with all information gathered.
          claimToWasAutomated.put(ac.claim.Id, false);
        }
        when else {
          // If an AutomationContainer has status Pending (or and invalid status) it should not be in "handledClaims"
          throw new AutomationException('Invalid status.');
        }
      }
    }

    return claimToWasAutomated;
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * If there has been more than 3 years since the flight flew the customer is no longer eligable to apply for compensation.
   * Source: TODO, does this vary depending on country? (e.g 1 year Belgium, 5 years France?) There was a reason I coded 3 years (?)
   *
   * @return a boolean which asserts whether the claim was filed on time.
   */
  public static Boolean isFiledOnTime(AutomationContainer ac) {
    BookingJSON.Flight flight = getRelevantFlight(ac);
    Datetime claimCreation = ac.claim.CreatedDate; // TODO: Should this be the case creation date?
    Datetime flightDate = flight.scheduledArrivalTime;
    return DateUtils.isEligableForCompensation(claimCreation, flightDate);
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Calculates how much compensation the customer(s) is/are entitled to as per EU261:
   * "In determining the distance, the basis shall be the last destination at which
   * the denial of boarding or cancellation will delay the passenger's arrival
   * after the scheduled time." - EU261
   *
   * @return the amount of compensation in EUR
   */
  public static Integer calculateEU261Compensation(AutomationContainer ac) {
    Integer flightDistance = getFlightDistanceKm(ac); // Todo: Handle multi flight
    Integer delayedMinutes = getMinutesDelayed(ac);

    // TODO: ~Calculate revenue
    Integer noEligablePax = getNoPaxEligableForCompensation(ac); // Todo: Make much more complicated
    if (delayedMinutes < 180) {
      // Double check
      return 0;
    }
    if (flightDistance <= 1500) {
      return noEligablePax * 250;
    } else if (
      flightDistance > 1500 &&
      (flightDistance <= 3500 ||
      CountryUtils.isIntraCommunity(ac.originAirport, ac.destinationAirport))
    ) {
      return noEligablePax * 400;
    } else {
      if (delayedMinutes >= 240) {
        return noEligablePax * 600;
      } else {
        return noEligablePax * 300;
      }
    }
  }

  public class NoMatchingFlightException extends Exception {
  }

  public class NoDelayException extends Exception {
  }

  public class InvalidPNRTypeException extends Exception {
  }

  public class AutomationException extends Exception {
  }

  // DELAY
  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Automatically handles the compensation process for a claim with a delayed flight.
   *
   * @return the same AutomationUtils.AutomationContainer with updated information
   */
  private static AutomationContainer automateEU261Delay(
    AutomationContainer ac
  ) {
    Integer minutesDelayed = getMinutesDelayed(ac);

    if (minutesDelayed < 120) {
      // Double check
      // Reject
      ac.rejectClaim();
    } else {
      // TODO: ~Check if SAS is responsible
      // TODO: ~Check if within SAS control
      // TODO: ~Check if case is handled on behalf of another

      ac.careCompensation = calculateCareCompensation(ac); // Currently not supported

      if (minutesDelayed >= 180) {
        ac.EU261Compensation = calculateEU261Compensation(ac); // Semi-supported
      }

      // TODO: (c)Check reason and main rule

      // TODO: (c)Send compensation
      ac.payOutClaim();
    }
    return ac;
  }

  // CANCELLATION
  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Automatically handles the compensation process for a claim with a cancelled flight.
   *
   * @return the same AutomationUtils.AutomationContainer with updated information
   */
  private static Boolean automateEU261Cancellation(AutomationContainer ac) {
    // TODO: Understand
    return null;
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Calculates whether the claim is covered by EU261
   * EU261 is only applicable for flights leaving and/or arriving to an airport in the European Union, Iceland, Norway or Switzerland.
   * Also, if the customer has already received benefits related to a law of a non-EU country they are not eligable for compensation.
   * Source: https://europa.eu/youreurope/citizens/travel/passenger-rights/air/index_en.htm
   *
   * TODO:
   * The "already received benefits"-part, might be impossible to automate.
   * Is there any data which is shared between carriers? Can we add a checkmark "I have not received compensation under non-EU law"?
   *
   * @return a boolean which asserts if the claim is covered by EU261
   */
  private static Boolean isCoveredByEU261(AutomationContainer ac) {
    // ~TODO(c): Determine if the customer has already received benefits related to a law of a non-EU country
    return CountryUtils.oneIsInEU261Territory(
      ac.originAirport,
      ac.destinationAirport
    );
  }

  private static BookingJSON.Flight getRelevantFlight(AutomationContainer ac) {
    BookingJSON.Flight flight;
    for (BookingJSON.Flight f : ac.booking.flights) {
      // TODO: Make this more robust.
      if (f.flightNumber == ac.claim.Flight_Number__c.substringBefore('-')) {
        flight = f;
      }
    }
    if (flight == null) {
      throw new NoMatchingFlightException(
        'The flight number in the claim does not match any flight in the booking.'
      );
    }
    return flight;
  }

  private static Integer getMinutesDelayed(AutomationContainer ac) {
    BookingJSON.Flight flight = getRelevantFlight(ac);
    if (
      flight.arrivalDelayedMinutes == null ||
      flight.arrivalDelayedMinutes <= 0
    ) {
      throw new NoDelayException(
        'The delay is null or less than or equal to 0 minutes'
      );
    }
    return flight.arrivalDelayedMinutes.intValue();
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Calculates the total flight distance for the booking.
   * Thoughts: This is a bit wierd, does this concern individual flights or the whole booking?
   * And if the whole booking, how is a "leg" determined? This currently has to be handled individually.
   *
   * @return the distance in km, rounded normally.
   */
  private static Integer getFlightDistanceKm(AutomationContainer ac) {
    BookingJSON.Flight flight = getRelevantFlight(ac);

    switch on ac.booking.type {
      when 'DayReturn' {
        return null;
      }
      when 'MultiCity' {
        return null;
      }
      when 'OneWay' {
        if (ac.booking.flights.size() == 1) {
          return Integer.valueOf(
            CountryUtils.distanceBetweenAirportsInKilometers(
              flight.departureAirport,
              flight.arrivalAirport
            )
          ); // Supported
        } else {
          return null;
        }
      }
      when 'RoundTrip' {
        return null;
      }
      when 'Unknown' {
        return null;
      }
      when else {
        // Erronous data from TEDS
        throw new InvalidPNRTypeException('The booking has an invalid type.');
      }
    }

    // Get locations

    // Get haversine distance

    // Sum
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Checks whether there is another claim which is associated with the same booking pnr, PIR and/or the same flight number + passenger.
   * Beyond the PNR check, this also catches passengers which have made two bookings for the same flight.
   * These passengers should not be entitled to double compensation.
   * TODO: Are there any other cases we should check?
   */
  public static Boolean isDuplicate(AutomationContainer ac) {
    List<LIA_Claim__c> duplicateClaims = ClaimsSelector.newInstance()
      .selectDuplicatesById(ac.claim.Id);

    switch on duplicateClaims.size() {
      when 1 {
        return false; // Matched only itself
      }
      when 0 {
        throw new AutomationException('The claim is not in the database.');
      }
    }

    return true;
  }

  /**
   * @param claim
   * @param booking
   *
   * Asserts whether automation has been implemented for different types of bookings.
   */
  private static Boolean isSupportedForAutomation(
    LIA_Claim__c claim,
    BookingJSON booking
  ) {
    // Todo: Check if the customer has claimed Care expenses
    if (!hasClaimedCareExpenses()) {
      switch on booking.type {
        when 'DayReturn' {
          notSupported(booking.type);
        }
        when 'MultiCity' {
          notSupported(booking.type);
        }
        when 'OneWay' {
          if (booking.flights.size() == 1) {
            return true; // Supported
          } else {
            notSupported(booking.type + ' (multiple flights) ');
          }
        }
        when 'RoundTrip' {
          notSupported(booking.type);
        }
        when 'Unknown' {
          notSupported(booking.type);
        }
        when else {
          // Erronous data from TEDS
          throw new InvalidPNRTypeException('The booking has an invalid type.');
        }
      }
    }
    return false;
  }

  private static Boolean hasClaimedCareExpenses() {
    return false;
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * TODO: Make much more complicated, this data is not available in TEDS.
   * Investigate: Can people in the same booking have different number of flights?
   *
   * @return The amount of passengers which are entitled to compensation.
   */
  private static Integer getNoPaxEligableForCompensation(
    AutomationContainer ac
  ) {
    // TODO: Check: Is it an ID ticket? -> Not eligable (?)
    // TODO: Check: Is fare = 0?
    // TODO: Check: Is it an award ticket? (? ask someone)
    // TODO: Check: Is it an infant domestic?
    // TODO: Check: Is it DK domestic?

    return ac.booking.passengers.size();
  }

  /**
   * @param ac an AutomationUtils.AutomationContainer containing information about the booking and the claim.
   *
   * Todo: Implement.
   * This can likely not be automated :(
   * Thoughts: Can we make a custom type of case where agents only check and approve claim expenses?
   *
   * @return a Decimal with the care compensation in EUR, rounded to two decimals
   */
  private static Decimal calculateCareCompensation(AutomationContainer ac) {
    return 0.0;
  }

  /**
   * @param claims a list of claims for which to find information.
   *
   * Todo: Refactor, make batchable. Implement fetching of more data (purchase data etc.)
   *
   * @return a list of AutomationContainers containing all information necessary to automate the claim.
   */
  private static List<AutomationContainer> gatherInfoAboutClaimsToAutomate(
    List<LIA_Claim__c> claims
  ) {
    List<AutomationContainer> claimsToAutomate = new List<AutomationContainer>{};
    // Get information, TODO: Make batchable, use Set<Id>, don't overfetch, handle duplication
    for (LIA_Claim__c c : claims) {
      List<BookingJSON> bookings = CustomerCardController.getBookingsForCase(
        String.valueOf(c.Case__c)
      );
      for (BookingJSON b : bookings) {
        // TODO: Can there be multiple bookings per claim? No?
        if (b.bookingReference == c.Liability_PNR__c) {
          AutomationContainer claimToAutomate = new AutomationContainer(c, b);
          if (claimToAutomate.isAutomatable) {
            claimsToAutomate.add(claimToAutomate);
          }
          break;
        }
      }
    }
    return claimsToAutomate;
  }

  private static void notSupported(String type) {
    System.debug(
      'Claims with: ' +
      type +
      ' bookings are not currently supported for EU261 automation.'
    );
  }
}
