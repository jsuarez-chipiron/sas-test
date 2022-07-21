/**
 * Utility class which handles case/claim automation
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
   * @param claims
   *
   * Todo: Rethink, make batchable, make testable (guard for callouts)
   * Todo: If rejected, add a information to the case/claim.
   * Thoughts: We need to widen the scope from claim to case as a claim only can have one flight.
   *
   * @return A map from claim id to whether that claim has been automated.
   */
  public static Map<Id, Boolean> automateEU261(Set<Id> claimIds) {
    Map<Id, Boolean> claimToWasAutomated = new Map<Id, Boolean>{};

    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectById(claimIds);
    List<AutomationContainer> claimsToAutomate = new List<AutomationContainer>{};

    // Get information, TODO: Make batchable, use Set<Id>, don't overfetch, handle duplication
    for (LIA_Claim__c c : claims) {
      claimToWasAutomated.put(c.Id, false);
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

    List<AutomationContainer> handledClaims = new List<AutomationContainer>{};

    for (AutomationContainer ac : claimsToAutomate) {
      // TODO: Determine if EU261 is applicable
      // Was the flight from/to the right place
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
        ac.handleClaim();
        ac.rejectClaim();
        handledClaims.add(ac);
        continue;
      }
      // TODO: ~Check proactivities and similar cases

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
   * Calculates the haversine distance in meters between two airports.
   *
   * @param airport1 String of the IATA airport code.
   * @param airport2 String of the IATA airport code.
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    String airport1Id,
    String airport2Id
  ) {
    Double dist = distanceBetweenAirportsInKilometers(airport1Id, airport2Id);
    return Integer.valueOf(
      Decimal.valueOf(dist * 1000).round(System.RoundingMode.HALF_UP)
    );
  }

  /**
   * Calculates the haversine distance in kilometers between two airports (rounded normally).
   *
   * @param airport1
   * @param airport2
   *
   * @return An Double value of the distance in kilometers between the two airports.
   */
  public static Double distanceBetweenAirportsInKilometers(
    String airport1Id,
    String airport2Id
  ) {
    List<Airport__c> airportsFound = AirportsSelector.newInstance()
      .selectAndOrFetchByTEDSId(new Set<String>{ airport1Id, airport2Id });
    Airport__c airport1;
    Airport__c airport2;

    for (Airport__c a : airportsFound) {
      if (a.TEDS_Identifier__c == airport1Id) {
        airport1 = a;
      }
      if (a.TEDS_Identifier__c == airport2Id) {
        airport2 = a;
      }
    }
    if (airport1 == null || airport2 == null) {
      throw new AirportNotFoundException('Could not find both airports.');
    }

    Double long1 = Double.valueOf(airport1.Longitude__c);
    Double lat1 = Double.valueOf(airport1.Latitude__c);
    Double long2 = Double.valueOf(airport2.Longitude__c);
    Double lat2 = Double.valueOf(airport2.Latitude__c);

    Location loc1 = Location.newInstance(
      airport1.Latitude__c,
      airport1.Longitude__c
    );
    Location loc2 = Location.newInstance(
      airport2.Latitude__c,
      airport2.Longitude__c
    );
    return Location.getDistance(loc1, loc2, 'km');
  }

  /**
   * @param TODO
   * TODO
   * @return TODO
   */
  public static Boolean isFiledOnTime(AutomationContainer ac) {
    BookingJSON.Flight flight = getRelevantFlight(ac);
    Datetime claimCreation = ac.claim.CreatedDate; // TODO: Should this be the case creation date?
    Datetime flightDate = flight.scheduledArrivalTime;
    return DateUtils.isEligableForCompensation(claimCreation, flightDate);
  }

  /**
   * Todo: Implement.
   * "In determining the distance, the basis shall be the last destination at which
   * the denial of boarding or cancellation will delay the passenger's arrival
   * after the scheduled time." - EU261
   *
   * @param TODO
   * @return TODO
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
      flightDistance > 1500 && (flightDistance <= 3500 || isIntraCommunity(ac))
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

  public class AirportNotFoundException extends Exception {
  }

  public class NoDelayException extends Exception {
  }

  public class InvalidPNRTypeException extends Exception {
  }

  public class AutomationException extends Exception {
  }

  // DELAY
  private static AutomationContainer automateEU261Delay(
    AutomationContainer ac
  ) {
    Integer minutesDelayed = getMinutesDelayed(ac);

    if (minutesDelayed < 120) {
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
  private static Boolean automateEU261Cancellation(AutomationContainer ac) {
    // TODO: Understand
    return null;
  }

  /**
   * @param TODO
   * TODO
   * @return TODO
   */
  private static Boolean isCoveredByEU261(AutomationContainer ac) {
    return true;
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
   * Calculates the total flight distance for the booking.
   * Thoughts: This is a bit wierd, does this concern individual flights or the whole booking?
   * And if the whole booking, how is a "leg" determined? This currently has to be handled individually
   * @param TODO
   * TODO
   * @return TODO
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
            distanceBetweenAirportsInKilometers(
              flight.departureAirport,
              flight.arrivalAirport
            )
          ); // Supported
        } else {
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

    return 1;
  }

  /**
   * @param TODO
   * TODO
   * @return TODO
   */
  private static Boolean isDuplicate(AutomationContainer ac) {
    return false;
  }

  /**
   * @param TODO
   * TODO
   * @return TODO
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
   * TODO: Make much more complicated
   * Investigate: Can people in the same booking have different number of flights?
   * @param AutomationUtils.AutomationContainer ac
   * @return The amount of passengers which should have compensation
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
   * TODO: Reimplement, multi flights
   * Investigate: Can people in the same booking have different number of flights?
   * @param AutomationUtils.AutomationContainer ac
   * @return The amount of passengers which should have compensation
   */
  private static Boolean isIntraCommunity(AutomationContainer ac) {
    // TODO: think about how to handle airport data
    List<Airport__c> airportsFound = AirportsSelector.newInstance()
      .selectAndOrFetchByTEDSId(
        new Set<String>{ ac.originAirport, ac.destinationAirport }
      );
    Airport__c originAirport;
    Airport__c destinationAirport;

    for (Airport__c a : airportsFound) {
      if (a.TEDS_Identifier__c == ac.originAirport) {
        originAirport = a;
      }
      if (a.TEDS_Identifier__c == ac.destinationAirport) {
        destinationAirport = a;
      }
    }
    if (originAirport == null || destinationAirport == null) {
      throw new AirportNotFoundException('Could not find both airports.');
    }

    if (
      originAirport.Is_EU261_Applicable__c &&
      destinationAirport.Is_EU261_Applicable__c
    ) {
      return true;
    }

    return false;
  }

  /**
   * Todo: Implement.
   * This can likely not be automated :(
   *
   * @param TODO
   * @return TODO
   */
  private static Decimal calculateCareCompensation(AutomationContainer ac) {
    return 0;
  }

  private static void notSupported(String type) {
    System.debug(
      'Claims with: ' +
      type +
      ' bookings are not currently supported for EU261 automation.'
    );
  }
}
