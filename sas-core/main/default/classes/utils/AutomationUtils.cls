/**
 * @param claim a LIA_Claim__c to be automated
 * @param booking a BookingJSON associated with the claim
 *
 * Utility class which handles case/claim automation
 * Contains all information needed (not currently) to automate a claim.
 * Investigate: Can people in the same booking have different amount of flights?
 *
 * WARNING: The automation is currently built with the assumption that there is exactly one flight per claim.
 * This can relatively easily be changed, but keep it in mind before allowing more than one flight in a claim.
 */
public without sharing class AutomationUtils {
  public class TripsAirportFetchContainer {
    private List<Trip> instanceRecords;
    private Boolean hasAirports;

    public TripsAirportFetchContainer(List<Trip> trips) {
      this.instanceRecords = trips;
      hasAirports = false;
    }

    public List<Trip> getInstanceRecordsWithAirports() {
      if (!this.hasAirports) {
        this.getAirports();
      }
      return this.instanceRecords;
    }

    private void getAirports() {
      Set<String> airportIds = new Set<String>{};
      for (Trip t : this.instanceRecords) {
        airportIds.add(t.originAirportId);
        airportIds.add(t.destinationAirportId);
      }

      List<Airport__c> airports = AirportsSelector.newInstance()
        .selectAndOrFetchByTEDSId(airportIds);
      List<Trip> updatedTrips = new List<Trip>{};

      for (Trip t : this.instanceRecords) {
        for (Airport__c a : airports) {
          if (a.TEDS_Identifier__c == t.originAirportId) {
            t.originAirport = a;
          }
          if (a.TEDS_Identifier__c == t.destinationAirportId) {
            t.destinationAirport = a;
          }
        }
        if (t.originAirport == null || t.destinationAirport == null) {
          throw new AutomationException('Could not find airport.');
        }
        updatedTrips.add(t);
      }

      this.instanceRecords = updatedTrips;
      this.hasAirports = true;
    }
  }

  public class Trip {
    public String originAirportId; // If we begin storing airports as lookups these are unnecessary.
    public String destinationAirportId;
    public Airport__c originAirport;
    public Airport__c destinationAirport;
    private List<Segment__c> allSegmentsInOrder;
    public Boolean hasOnlySASFlights;
    public Id bookingId;

    public Trip(Id bookingId, List<Segment__c> segmentsInOrder) {
      this.bookingId = bookingId;
      this.allSegmentsInOrder = segmentsInOrder;
      this.originAirportId = segmentsInOrder[0].Flight__r.Departure_Airport__c;
      this.destinationAirportId = segmentsInOrder[segmentsInOrder.size() - 1]
        .Flight__r
        .Arrival_Airport__c;
      this.hasOnlySASFlights = true;

      for (Segment__c s : segmentsInOrder) {
        if (s.Flight__r == null) {
          throw new AutomationException(
            'Segment is not associated with a flight. Please fetch all necessary data.'
          );
        }
        if (s.Flight__r.TEDS_Identifier__c.substring(0, 2) != 'SK') {
          this.hasOnlySASFlights = false;
        }
      }
    }

    public Boolean containsFlight(String flightNumberDate) {
      for (Segment__c s : this.allSegmentsInOrder) {
        String segmentFlightId;
        try {
          segmentFlightId = s.Flight__r.TEDS_Identifier__c;
        } catch (Exception e) {
          throw new AutomationException(
            'Segment in trip does not contain all necessary information.'
          );
        }
        if (segmentFlightId.contains(flightNumberDate)) {
          return true;
        }
      }
      return false;
    }

    public Datetime getFinalDestinationArrivalTime() {
      Flight__c lastFlight = getFlightToFinalDestination();

      if (lastFlight.Actual_Arrival_Time__c != null) {
        return lastFlight.Actual_Arrival_Time__c;
      }
      return lastFlight.Scheduled_Arrival_Time__c;
    }

    public Flight__c getFlightToFinalDestination() {
      Flight__c lastFlight = allSegmentsInOrder[allSegmentsInOrder.size() - 1]
        .Flight__r;
      if (lastFlight == null) {
        throw new AutomationException(
          'Segment in trip does not contain all necessary information.'
        );
      }
      return lastFlight;
    }

    /**
     * Not to be used, use TripsAirportFetchContainer to fetch airports for trips in batch.
     */
    public void forceSetFlights() {
      List<Airport__c> airports = AirportsSelector.newInstance()
        .selectAndOrFetchByTEDSId(
          new Set<String>{ this.originAirportId, this.destinationAirportId }
        );
      for (Airport__c a : airports) {
        if (a.TEDS_Identifier__c == this.originAirportId) {
          this.originAirport = a;
        }
        if (a.TEDS_Identifier__c == this.destinationAirportId) {
          this.destinationAirport = a;
        }
      }
      if (this.originAirport == null || this.destinationAirport == null) {
        throw new AutomationException('Could not find airport.');
      }
    }
  }

  public class AutomationInfoContainer {
    public String type;
    public Boolean hasDelay;
    public Boolean hasCancellation;
    public LIA_Claim__c claim;
    public Booking__c booking;
    private String status; // Unhandled, Rejected, Pending, PaidOut
    private Integer EU261Compensation = 0;
    private Decimal careCompensation = 0.0; // Currently not supported
    private List<Trip> trips;
    private Trip tripWithClaimFlight;

    public AutomationInfoContainer(
      LIA_Claim__c claim,
      Booking__c booking,
      List<Trip> trips
    ) {
      // Check if the booking type is supported
      List<String> supportedTypes = new List<String>{ 'OneWay' };
      if (!supportedTypes.contains(booking.Type__c)) {
        throw new AutomationException(
          booking.Type__c + ' type bookings are not supported for automation.'
        );
      }

      // Currently only delays are supported
      this.hasDelay = true; // TODO: make this dynamic
      this.hasCancellation = false;
      this.claim = claim;
      this.trips = trips;
      this.booking = booking;
      this.type = booking.Type__c;
      this.status = 'Unhandled';
      this.setTripWithClaimFlight();
    }

    public Decimal getTotalCompensation() {
      return Decimal.valueOf(EU261Compensation) + careCompensation;
    }

    // Todo: Implement
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

    public void sendToManualHandling() {
      if (this.status != 'Pending') {
        throw new AutomationException('Incorrect status change.');
      } else {
        this.status = 'Unhandled';
      }
    }

    public String getStatus() {
      return status;
    }

    private void setTripWithClaimFlight() {
      String flightNumberDate =
        this.claim.Flight_Number__c +
        '-' +
        String.valueOf(this.claim.Flight_Date__c).remove('-');

      if (this.tripWithClaimFlight != null) {
        System.debug('Trip with claim flight has already been set');
      }
      for (Trip t : trips) {
        if (t.containsFlight(flightNumberDate)) {
          if (this.tripWithClaimFlight != null) {
            // This is actually quite likely to happen, especially for "DayReturn"-bookings. In the claim we do not specify the airports.
            // This means that there is ambiguity if the customer has a ticket with e.g. SK1234-20220101-ARN-UME and SK1234-20220101-UME-ARN
            throw new AutomationException(
              'There are multiple trips in this booking that contain the claim flight.'
            );
          }
          this.tripWithClaimFlight = t;
        }
      }
    }

    public Boolean hasTripWithClaimFlight() {
      if (tripWithClaimFlight != null) {
        return true;
      }
      return false;
    }
  }

  /**
   * @param claimIds a Set of Ids of the claims to be automated
   *
   * Todo: Rethink, make batchable, make testable (guard for callouts), Convert to using flight irregularities
   * Todo: If rejected, add a information to the case/claim.
   *
   * @return A map from claim id to whether or not that claim has been automated.
   */
  public static Map<Id, Boolean> automateEU261Claims(Set<Id> claimIds) {
    Map<Id, Boolean> claimIdToWasAutomated = new Map<Id, Boolean>{};

    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectByIdWithCustomers(claimIds);

    // TODO: think about cancellations
    List<AutomationInfoContainer> claimsToAutomate = selectAutomatableClaimsAndGatherInformation(
      claims
    );

    List<AutomationInfoContainer> handledClaims = new List<AutomationInfoContainer>{};
    for (AutomationInfoContainer ac : claimsToAutomate) {
      // The flight for which the customer has claimed compensation should be in a trip in the AutomationInfoContainer
      if (!ac.hasTripWithClaimFlight()) {
        throw new NoMatchingFlightException(
          'The flight number in the claim does not match any flight in the booking.'
        );
      }

      // Was the flight from/to the right place + insanely complex edge case
      if (!isCoveredByEU261(ac)) {
        System.debug('This claim is not covered by EU261');
        continue;
      }

      // Determine if the claim is filed on time
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
      // Currently no cancellations should end up here
      if (ac.hasDelay) {
        ac.handleClaim();
        handledClaims.add(automateEU261Delay(ac));
      } else if (ac.hasCancellation) {
        //claimIdToWasAutomated.put(ac.claim.Id, automateEU261Cancellation(ac));
        throw new AutomationException(
          'Cancellations are currently not supported.'
        );
      } else {
        throw new AutomationException(
          'This claim has not got a delay or a cancellation.'
        );
      }
    }

    for (AutomationInfoContainer ac : handledClaims) {
      switch on ac.getStatus() {
        when 'PaidOut', 'Rejected' {
          claimIdToWasAutomated.put(ac.claim.Id, true);
        }
        when 'Unhandled' {
          // Fill the case/claim with all information gathered.
          claimIdToWasAutomated.put(ac.claim.Id, false);
        }
        when else {
          // If an AutomationInfoContainer has status Pending (or and invalid status) it should not be in "handledClaims"
          throw new AutomationException('Invalid status.');
        }
      }
    }

    return claimIdToWasAutomated;
  }

  /**
   * If there has been more than 3 years since the flight flew the customer is no longer eligable to apply for compensation.
   * Source: TODO, does this vary depending on country? (e.g 1 year Belgium, 5 years France?) There was a reason I coded 3 years (?)
   *
   * @return a boolean which asserts whether the claim was filed on time.
   */
  public static Boolean isFiledOnTime(AutomationInfoContainer ac) {
    Datetime claimCreation = ac.claim.CreatedDate; // TODO: Should this be the case creation date?
    Datetime tripDate = ac.tripWithClaimFlight.getFinalDestinationArrivalTime();
    return DateUtils.isEligableForCompensation(claimCreation, tripDate);
  }

  /**
   * Calculates how much compensation the customer(s) is/are entitled to as per EU261.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   * @return the amount of compensation in EUR
   */
  public static Integer calculateEU261Compensation(AutomationInfoContainer ac) {
    Integer delayedMinutes = getMinutesDelayed(ac);

    if (delayedMinutes < 180) {
      // Double check
      return 0;
    }

    // Calculate revenue
    Integer noEligablePax = getNoPaxEligableForCompensation(ac); // Todo: Make much more complicated
    Integer flightDistance = getFlightDistanceKm(ac);
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

  public class NoDelayException extends Exception {
  }

  public class InvalidPNRTypeException extends Exception {
  }

  public class AutomationException extends Exception {
  }

  // DELAY
  /**
   * @param ac an AutomationUtils.AutomationInfoContainer containing information about the booking and the claim.
   *
   * Automatically handles the compensation process for a claim with a delayed flight.
   *
   * @return the same AutomationUtils.AutomationInfoContainer with updated information
   */
  private static AutomationInfoContainer automateEU261Delay(
    AutomationInfoContainer ac
  ) {
    Integer minutesDelayed = getMinutesDelayed(ac);

    if (minutesDelayed < 120) {
      // Double check
      // Reject
      ac.rejectClaim();
    } else {
      // Check if SAS is responsible, TODO: Make this more complicated, then we can reject claims
      if (!SASisResponsible(ac)) {
        ac.sendToManualHandling();
        return ac; // Can't be handled (when implemented: reject)
      }
      // TODO: ~Check if within SAS control
      if (!isWithinSASControl(ac)) {
        ac.sendToManualHandling();
        return ac; // Can't be handled (when implemented: reject)
      }
      // TODO: ~Check if case is handled on behalf of another
      if (isHandledOnBehalfOfAnother(ac)) {
        ac.sendToManualHandling();
        return ac; // Can't be handled (future feature: send to Liability who can manulally validate the POA)
      }

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
   * @param ac an AutomationUtils.AutomationInfoContainer containing information about the booking and the claim.
   *
   * Automatically handles the compensation process for a claim with a cancelled flight.
   *
   * @return the same AutomationUtils.AutomationInfoContainer with updated information
   */
  private static Boolean automateEU261Cancellation(AutomationInfoContainer ac) {
    // TODO: Understand
    return null;
  }

  /**
   * @param ac an AutomationUtils.AutomationInfoContainer containing information about the booking and the claim.
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
  private static Boolean isCoveredByEU261(AutomationInfoContainer ac) {
    // ~TODO(c): Determine if the customer has already received benefits related to a law of a non-EU country
    Boolean hasReceivedBenefitsWhichVoidEU261 = false;

    Airport__c originAirport = ac.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = ac.tripWithClaimFlight.destinationAirport;
    Boolean isToOrFromEU261Territory = (originAirport.Is_EU261_Applicable__c ||
    destinationAirport.Is_EU261_Applicable__c);

    return (isToOrFromEU261Territory && !hasReceivedBenefitsWhichVoidEU261);
  }

  private static Boolean isIntraCommunity(AutomationInfoContainer ac) {
    Airport__c originAirport = ac.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = ac.tripWithClaimFlight.destinationAirport;
    return originAirport.Is_EU261_Applicable__c &&
      destinationAirport.Is_EU261_Applicable__c;
  }

  // Todo: Update this to use Flight_Irregularities__c
  private static Integer getMinutesDelayed(AutomationInfoContainer ac) {
    Flight__c flight = ac.tripWithClaimFlight.getFlightToFinalDestination();

    // Can the flight be delayed even if there is no actual arrival time?
    Integer delayedMinutes = flight.Arrival_Delayed_Minutes__c.intValue() + 1; // +1 to be safe from rounding errors if Delayed_Minutes_c actually is a Decimal value
    if (delayedMinutes == null || delayedMinutes <= 0) {
      throw new NoDelayException(
        'The delay is null or less than or equal to 0 minutes'
      );
    }

    return delayedMinutes;
  }

  /**
   * Calculates the total flight distance for the relevant Trip.
   * This is valid for all booking types.
   * @return the distance in km, rounded normally.
   */
  private static Integer getFlightDistanceKm(AutomationInfoContainer ac) {
    return Integer.valueOf(
      CountryUtils.distanceBetweenAirportsInKilometers(
        ac.tripWithClaimFlight.originAirport,
        ac.tripWithClaimFlight.destinationAirport
      )
    );
  }

  /**
   * Checks whether there is another claim which is associated with the same booking pnr, PIR and/or the same flight number + passenger.
   * Beyond the PNR check, this also catches passengers which have made two bookings for the same flight.
   * These passengers should not be entitled to double compensation.
   * TODO: Are there any other cases we should check?
   */
  public static Boolean isDuplicate(AutomationInfoContainer ac) {
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

  // TODO: implement
  private static Boolean hasClaimedCareExpenses(LIA_Claim__c claim) {
    return false;
  }

  /**
   * TODO: Make this more complicated. Ask Liability for help.
   */
  private static Boolean SASisResponsible(AutomationInfoContainer ac) {
    return ac.tripWithClaimFlight.hasOnlySASFlights;
  }

  /**
   * TODO: Implement. Ask Liability for help.
   */
  private static Boolean isWithinSASControl(AutomationInfoContainer ac) {
    return true;
  }

  /**
   * TODO: Implement. Check if there is a POA or not.
   */
  private static Boolean isHandledOnBehalfOfAnother(
    AutomationInfoContainer ac
  ) {
    return false;
  }

  /**
   * TODO: Make much more complicated, this data is not available in TEDS (?ö).
   * Investigate: Can people in the same booking have different number of flights?
   * @param AutomationUtils.AutomationContainer ac
   * @return The amount of passengers which should have compensation
   */
  private static Integer getNoPaxEligableForCompensation(
    AutomationInfoContainer ac
  ) {
    // TODO: Check: Is it an ID ticket? -> Not eligable (?)
    // TODO: Check: Is fare = 0?
    // TODO: Check: Is it an award ticket? (? ask someone)
    // TODO: Check: Is it an infant domestic?
    // TODO: Check: Is it DK domestic?
    return ac.claim.Customers__r.size();
  }

  /**
   * Todo: Implement.
   * This can likely not be automated :(
   * Thoughts: Can we make a custom type of case where agents only check and approve claim expenses?
   *
   * @return a Decimal with the care compensation in EUR, rounded to two decimals
   */
  private static Decimal calculateCareCompensation(AutomationInfoContainer ac) {
    return 0.0;
  }

  /**
   * @param claims a list of claims for which to find information or sort out.
   *
   * This logic resembles the constructor logic for BookingJSON.
   * However, to efficiently handle different types of bookings we need a custom solution.
   *
   * Todo: Implement fetching of more data, e.g. Flight_irregularities (needed for cancellations)
   *
   * Sort out the claims which are not supported and gather information about those who are.
   *
   * @return a list of AutomationInfoContainers containing all information necessary to automate the claim.
   */
  private static List<AutomationInfoContainer> selectAutomatableClaimsAndGatherInformation(
    List<LIA_Claim__c> claims
  ) {
    Map<Id, LIA_Claim__c> caseIdToClaim = new Map<Id, LIA_Claim__c>{};
    Map<Id, LIA_Claim__c> bookingIdToClaim = new Map<Id, LIA_Claim__c>{};

    for (LIA_Claim__c c : claims) {
      caseIdToClaim.put(c.Case__c, c);
    }

    // TODO: break out
    List<Claim_Expense__c> expenses = [
      SELECT Claim__c
      FROM Claim_Expense__c
      WHERE Claim__c IN :caseIdToClaim.values()
    ];

    Set<Id> claimIdsWithCareExpeses = new Set<Id>{};
    for (Claim_Expense__c e : expenses) {
      claimIdsWithCareExpeses.add(e.Claim__c);
    }

    // Get all bookings connected to the claims, if the claim is not supported don't handle it.
    List<CaseToBooking__c> ctbs = CaseToBookingsSelector.newInstance()
      .selectByCaseId(caseIdToClaim.keySet());

    Set<Id> caseIdsWithABooking = new Set<Id>();
    for (CaseToBooking__c c : ctbs) {
      LIA_Claim__c claim = caseIdToClaim.get(c.Case__c);
      Boolean hasClaimedCareExpenses = claimIdsWithCareExpeses.contains(
        claim.Id
      );

      if (hasClaimedCareExpenses) {
        notSupported(claim, 'contains care expenses.');
        continue;
      }

      if (caseIdsWithABooking.contains(c.Case__c)) {
        notSupported(claim, 'is associated with more than one booking.');
        continue;
      }

      if (claim.Customer_Claim_Category__c != 'Flight disruptions') {
        notSupported(claim, 'is not a flight disruption claim.');
        continue;
      }

      caseIdsWithABooking.add(c.Case__c);
      bookingIdToClaim.put(c.Booking__c, claim);
    }

    // Contains Segment->Flight
    List<Booking__c> bookings = BookingsSelector.newInstance()
      .selectByIdFull(bookingIdToClaim.keySet());

    // Get all relevant booking data.
    List<Trip> allTrips = new List<Trip>{}; // These have to be fetched in a wierd way as airports do not have a lookup relationship
    Map<Id, Booking__c> idToBooking = new Map<Id, Booking__c>{};
    for (Booking__c booking : bookings) {
      idToBooking.put(booking.Id, booking);
      LIA_Claim__c claim = bookingIdToClaim.get(booking.Id);
      List<Segment__c> segments = new List<Segment__c>{};

      String reason =
        'has an unsupported booking type (' +
        booking.Type__c +
        ').';
      switch on booking.Type__c {
        when 'DayReturn' {
          notSupported(claim, reason);
        }
        when 'MultiCity' {
          notSupported(claim, reason);
        }
        when 'OneWay' {
          if (booking.Segments__r.size() == 1) {
            allTrips.addAll(divideIntoTrips(booking, booking.Segments__r));
          } else {
            notSupported(claim, reason + '(multiple flights)');
          }
        }
        when 'RoundTrip' {
          notSupported(claim, reason);
        }
        when 'Unknown' {
          notSupported(claim, reason);
        }
        when else {
          // Erronous data from TEDS
          throw new InvalidPNRTypeException('The booking has an invalid type.');
        }
      }
    }

    TripsAirportFetchContainer tripsForAllBookings = new TripsAirportFetchContainer(
      allTrips
    );
    List<Trip> allTripsWithAirports = tripsForAllBookings.getInstanceRecordsWithAirports();
    Map<Id, List<Trip>> bookingIdToTrips = new Map<Id, List<Trip>>{};
    for (Trip t : allTripsWithAirports) {
      List<Trip> tripsInBooking = bookingIdToTrips.get(t.bookingId);
      if (tripsInBooking == null) {
        bookingIdToTrips.put(t.bookingId, new List<Trip>{ t });
      } else {
        tripsInBooking.add(t);
        bookingIdToTrips.put(t.bookingId, tripsInBooking);
      }
    }

    // Gather all necessary data in a container
    List<AutomationInfoContainer> claimsToAutomate = new List<AutomationInfoContainer>{};
    for (Id bookingId : bookingIdToTrips.keySet()) {
      Booking__c booking = idToBooking.get(bookingId);
      LIA_Claim__c claim = bookingIdToClaim.get(booking.Id);
      List<Trip> trips = bookingIdToTrips.get(bookingId);
      claimsToAutomate.add(new AutomationInfoContainer(claim, booking, trips));
    }

    return claimsToAutomate;
  }

  /**
   * @param claim the claim that is not supported
   * @param reason a string with the reason why the claim is not supported. Format: verb ...
   * Helper function to log why a claim is not supported for automation
   *
   * @return The amount of passengers which are entitled to compensation.
   */
  private static void notSupported(LIA_Claim__c claim, String reason) {
    System.debug(
      'Claim no. ' +
      claim.Name +
      ' cannot be automated as it ' +
      reason
    );
  }

  /**
   * Divides the flights in the booking into different legs.
   * If the booking is a OneWay there should only be one leg.
   * If the booking is a Roundtrip or Dayreturn there should be two legs.
   * If the booking is a MultiCity there can be 1(?) or more legs.
   *
   * The compensation should, logically, be calculated with respect to each "final destination" in the booking (see EU261 Article 2 h: https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   * When a pax stays in a city for more than 24 hours it counts as a "final destination" according to internal SAS policy (TODO: find a good source).
   * After 24 hours the booking is considered a "package" under EU law (Council Directive 90/314/EEC Article 2 §1: https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=celex%3A31990L0314)
   *
   * TODO: Think about how we should handle the exception cases, find a solid source for the 24 hour policy
   */
  @TestVisible
  private static List<Trip> divideIntoTrips(
    Booking__c booking,
    List<Segment__c> segments
  ) {
    // Sort the Segments
    List<Segment__c> sortedSegments = new List<Segment__c>{};
    List<SegmentWrapper> segmentsToSort = new List<SegmentWrapper>{};
    for (Segment__c s : segments) {
      segmentsToSort.add(new SegmentWrapper(s));
    }

    segmentsToSort.sort();

    for (SegmentWrapper sw : segmentsToSort) {
      sortedSegments.add(sw.segment);
    }

    List<Trip> trips = new List<Trip>{};
    Segment__c latestSegment;
    List<Segment__c> segmentsInCurrentTrip = new List<Segment__c>{};

    Segment__c moreTest = sortedSegments[0];
    String moreTest2 = sortedSegments[0].Trip_Type__c;

    for (Segment__c s : sortedSegments) {
      if (s.Trip_Type__c == 'Cancelled') {
        throw new AutomationException(
          'Claims with cancelled flights are currently not supported'
        );
      }
      if (latestSegment == null) {
        latestSegment = s;
        segmentsInCurrentTrip.add(s);
        continue;
      }

      Boolean lessThan24HoursAtAirport = DateUtils.isLessThan24HoursBetween(
        latestSegment.flight__r.Scheduled_Arrival_Time__c,
        s.flight__r.Scheduled_Departure_Time__c
      );
      Boolean switchedToInbound = (s.Trip_Type__c !=
      latestSegment.Trip_Type__c &&
      booking.Type__c != 'MultiCity');

      if (lessThan24HoursAtAirport && !switchedToInbound) {
        latestSegment = s;
      } else {
        trips.add(new Trip(booking.Id, segmentsInCurrentTrip));
        segmentsInCurrentTrip = new List<Segment__c>{};
      }
      segmentsInCurrentTrip.add(s);
    }

    trips.add(new Trip(booking.id, segmentsInCurrentTrip));

    switch on booking.Type__c {
      when 'DayReturn', 'RoundTrip' {
        if (trips.size() != 2) {
          throw new AutomationException(
            'A ' +
            booking.Type__c +
            ' booking must have exactly two trips.'
          );
        }
        return trips;
      }
      when 'MultiCity' {
        if (trips.size() < 1) {
          throw new AutomationException(
            'A MultiCity booking must have at least on leg.'
          );
        }
        return trips;
      }
      when 'OneWay' {
        if (trips.size() != 1) {
          throw new AutomationException(
            'A OneWay booking must have exactly one leg.'
          );
        }
        return trips;
      }
      when 'Unknown' {
        throw new AutomationException(
          'Unknown type bookings are not supported.'
        );
      }
      when else {
        // Erronous data from TEDS
        throw new InvalidPNRTypeException('The booking has an invalid type.');
      }
    }
  }

  /**
   * Helper class to sort segments
   * TODO: Think about how to handle infants
   */
  private class SegmentWrapper implements Comparable {
    public Segment__c segment;

    public SegmentWrapper(Segment__c segment) {
      this.segment = segment;
    }

    public Integer compareTo(Object compareTo) {
      SegmentWrapper otherSegment = (SegmentWrapper) compareTo;
      if (segment.flight__r == null || segment.Seat__c == null) {
        throw new AutomationException(
          'The segment should contain a flight and a seat.'
        );
      }
      if (
        segment.flight__r.Scheduled_Departure_Time__c >
        otherSegment.segment.flight__r.Scheduled_Departure_Time__c
      ) {
        return 1;
      } else if (
        segment.flight__r.Scheduled_Departure_Time__c <
        otherSegment.segment.flight__r.Scheduled_Departure_Time__c
      ) {
        return -1;
      } else {
        // TODO: Think about infants
        if (segment.Seat__c != otherSegment.segment.Seat__c) {
          return 0;
        }
        throw new AutomationException(
          'The scheduled departure time for the segments and their seats are the same.'
        );
      }
    }
  }
}
