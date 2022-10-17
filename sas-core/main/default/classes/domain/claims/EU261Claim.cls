public class EU261Claim {
  private static Map<String, Integer> countryToClaimTimeLimitInMonths = new Map<String, Integer>{
    'BE' => 12,
    'DK' => 3 * 12,
    'FI' => 3 * 12,
    'FR' => 5 * 12,
    'DE' => 3 * 12,
    'IT' => 2 * 12,
    'NL' => 5 * 12,
    'NO' => 3 * 12,
    'PL' => 12,
    'ES' => 5 * 12,
    'SE' => 2,
    'UK' => 6 * 12,
    'IE' => 6 * 12,
    'LV' => 6,
    'default' => 0
  };

  // TODO: Make sure that this doesn't make any outside calls to anything.
  public Decision evaluate() {
    this.decision = this.canWeEvaluate();

    if (this.decision == null) {
      // If decision is null from above, we should be able to evaluate this claim.
      this.decision = this.determineEligibilityAndCalculateCompensation();
      // this.calculateReimbursement(); // Todo, implement
    }

    return this.decision;
  }

  private static Set<String> invalidFareBases = new Set<String>{};

  public class CreateException extends Exception {
  }

  public class Decision {
    public Integer compensationAmount { get; private set; } // Compensation is always per customer
    public Integer reimbursementAmount { get; private set; } // Reimbursement is one per claim because expenses are not tied to a customer

    public Map<ClaimCustomer, Integer> compensationPerCustomer; // TODO: We need something like this.

    public Claim.EU261HandlingStatus verdict { get; private set; }

    public String reasoning { get; private set; }

    Decision(Claim.EU261HandlingStatus verdict, String reasoning) {
      if (verdict == Claim.EU261HandlingStatus.EligibleForCompensation) {
        throw new CreateException(
          'Cannot create an eligible decision without compensation or reimbursement amount.'
        );
      }
      this.verdict = verdict;
      this.reasoning = reasoning;
      this.compensationAmount = 0;
      this.reimbursementAmount = 0;
    }

    Decision(
      String reasoning,
      Integer compensationAmount,
      Integer reimbursementAmount
    ) {
      if (compensationAmount == 0 && reimbursementAmount == 0) {
        throw new CreateException(
          'Cannot create an eligible decision with compensation and reimbursement amount both set to 0.'
        );
      }
      this.verdict = Claim.EU261HandlingStatus.EligibleForCompensation;
      this.reasoning = reasoning;
      this.compensationAmount = compensationAmount;
      this.reimbursementAmount = reimbursementAmount;
    }
  }

  @TestVisible
  private Bookings.Type bookingType;
  public Claims claimObj { public get; private set; } // must be a single claim
  @TestVisible
  private Bookings booking;
  private Map<Id, List<Trip>> trips;
  private Map<Id, List<FlightIrregularities__c>> flightToIrregularities;
  private Trip tripWithClaimFlight;
  private Boolean hasPotentiallyDuplicateClaims = false;
  private Flight__c claimFlight;

  public Decision decision { public get; private set; }

  public EU261Claim(
    Claim c,
    Bookings booking,
    Map<Id, List<FlightIrregularities__c>> flightToIrregularities,
    Boolean hasPotentiallyDuplicateClaims,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    this.claimObj = Claims.newInstance(
      (new List<LIA_Claim__c>{ c.underlyingSObject })
    );

    this.booking = booking;
    this.flightToIrregularities = flightToIrregularities;
    this.hasPotentiallyDuplicateClaims = hasPotentiallyDuplicateClaims;

    if (booking != null && booking.instanceRecords.size() > 0) {
      this.bookingType = Bookings.nameToBookingType.get(
        booking.instanceRecords[0].Type__c
      );

      try {
        this.trips = booking.getTrips(airportCodeToAirport);
      } catch (Trip.BookingTypeNotSupportedException e) {
        // If not supported, we'll leave trips empty. We'll ignore these when
        // processing cases later on.
        return;
      }

      String flightNumberDate = Flights.constructTEDSFlightNumberDate(
        c.flightNumber,
        c.departureDate
      );

      if (this.trips != null) {
        for (Trip t : this.trips.get(booking.instanceRecords[0].Id)) {
          Flight__c claimFlight = t.getFlight(flightNumberDate);
          if (claimFlight != null) {
            this.tripWithClaimFlight = t;
            this.claimFlight = claimFlight;
          }
        }
      }
    }
  }

  private Boolean hasTripWithClaimFlight() {
    if (tripWithClaimFlight != null) {
      return true;
    }
    return false;
  }

  private Boolean hasDelay() {
    if (claimFlight == null) {
      throw new AutomationException('tripWithClaimFlight not set');
    }
    return this.tripWithClaimFlight.isDelayedToDestination();
  }

  private Boolean hasCancellation() {
    if (claimFlight == null) {
      throw new AutomationException('claimFlight not set');
    }

    FlightIrregularities claimIrregularities = new FlightIrregularities(
      flightToIrregularities.get(claimFlight.Id)
    );
    claimIrregularities.removeNA0Delay();

    return claimIrregularities.containsCancellation();
  }

  private Boolean hasMoreThanOneCancellation() {
    List<FlightIrregularities__c> allIrregularities = new List<FlightIrregularities__c>();
    for (List<FlightIrregularities__c> fi : flightToIrregularities.values()) {
      allIrregularities.addAll(fi);
    }
    FlightIrregularities irr = new FlightIrregularities(allIrregularities);
    irr.removeAllButCancellations();
    irr.removeDuplicates();

    return irr.instanceRecords.size() > 1;
  }

  private Boolean hasOnlyOneFlightRoute() {
    String firstFlightRoute =
      booking.instanceRecords[0].Segments__r[0].Flight__r.Departure_Airport__c +
      booking.instanceRecords[0].Segments__r[0].Flight__r.Arrival_Airport__c;
    for (Segment__c s : booking.instanceRecords[0].Segments__r) {
      String segmentFlightRoute =
        s.Flight__r.Departure_Airport__c + s.Flight__r.Arrival_Airport__c;
      if (segmentFlightRoute != firstFlightRoute) {
        return false;
      }
    }
    return true;
  }

  /**
   * Verifies that we have necessessary information for this claim, and that the
   * type of the claim is such that we are able to evaluate it.
   *
   * Populates unhandledReason and canBeEvaluated.
   *
   * If canBeEvaluated for the given claim is true, we can try to evaluate the claim.
   *
   * Current limitations:
   *  [ ] flight disruption, correct record type etc.
   *      [x] must be flight disruption
   *      [x] must be CustomerClaim
   *      [x] must be New
   *      [ ] must have Queue as owner
   *  [x] one way ticket
   *  [x] only one person
   *  [x] only one flight
   *  [x] delay, not a cancellation
   *  [x] no claim expenses
   *  [x] no POA -> check that no attachments
   *  [ ] no proactivity on the claim  WE MIGHT NOT BE ABLE TO TAKE PROACTIVITIES INTO ACCOUNT
   *  [x] SAS is the only carrier
   *  [x] no claim related to this PNR
   *  [x] one delay reason
   *  [x] within EU
   *  [x] min 2h, max 5h delay
   *  [x] revenue ticket -> check for farebasis for SAS claims.
   *  [x] - not id ticket
   *  [x] - not infant // only one passenger
   *  [x] no duplicates
   */
  /**
   * Returns a decision if we cannot handle this claim. Returns null if we can evaluate it.
   */
  private Decision canWeEvaluate() {
    Claim c = this.claimObj.objects[0];
    if (c.category != Claim.Category.FlightDisruptions) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims in category "Flight disruptions"'
      );
    } else if (
      !(c.type == Claim.Type.FlightDelay ||
      c.type == Claim.Type.FlightCancellation)
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims in type "Flight delay" or "Flight cancellation"'
      );
    } else if (c.recordType != Claim.RecordType.CustomerClaim) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims with record type CustomerClaim'
      );
    } else if (
      false // TODO: Fix this //this.claim.instanceRecords[0].Case__r.Status != Cases.STATUS_NEW && String.valueOf(c.OwnerId).substring(0, 3) == '00G'
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims with case in status "New"'
      );
    } else if (
      this.booking == null ||
      this.booking.instanceRecords.size() == 0
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim is not associated with a booking'
      );
    } else if (this.booking.instanceRecords.size() > 1) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only one booking per claim'
      );
      // TODO: Think about how to handle repeat PNRs.
      // TODO: Think about the potential fraud cases.
      // TODO: Ensure that we have only a specific number of trips.
    } else if (this.hasPotentiallyDuplicateClaims) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle potential duplicates'
      );
    } else if (this.bookingType != Bookings.Type.OneWay) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only one way trips'
      );
    } else if (this.booking.instanceRecords[0].Segments__r.size() == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'no flight associated with the claim'
      );
    } else if (c.customers == null || c.customers.isEmpty()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims without any travellers'
      );
    } else if (
      invalidFareBases.contains(
        this.booking.instanceRecords[0].Segments__r[0].Fare_Basis__c
      )
    ) {
      // TODO: Move this to be evaluation instead.
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims with a restricted fare basis.'
      );
    } else if (!this.hasTripWithClaimFlight()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot find claimed flight from booking'
      );
    } else if (
      !this.tripWithClaimFlight.originAirport.Is_EU261_Applicable__c ||
      !this.tripWithClaimFlight.destinationAirport.Is_EU261_Applicable__c
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can only handle claims with origin and destination airports in EU'
      );
    } else if (c.submittedClaimExpenses > 0) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claim expenses'
      );
    } else if (this.hasRotationIrregularities()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle flights with irregularities caused by rotations'
      );
    } else if (!this.tripWithClaimFlight.SASIsOnlyOperatingCarrier) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims where SAS is not the only operating carrier'
      );
    } else if (this.requiresPowerOfAttorney()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims which do not require power of attorney'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation && !this.hasCancellation()
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight is not cancelled'
      );
    } else if (
      this.hasCancellation() != this.tripWithClaimFlight.hasCancelledSegments()
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight is cancelled but the booking has no cancelled segments'
      );
    } else if (hasMoreThanOneCancellation()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'there are more than one cancellation connected to this claim'
      );
    } else if (!hasOnlyOneFlightRoute()) {
      // Super-basic flight handling
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can only handle claims with a single flight route'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation &&
      !this.canDetermineIfSASIsResponsibleForCancellation()
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot determine wether SAS is responsible or not for the cancellation'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation &&
      (!this.tripWithClaimFlight.canGetOriginalTrip() ||
      !this.tripWithClaimFlight.canGetSuggestedRebookingTrip())
    ) {
      this.tripWithClaimFlight.logJSON(
        'Case: ' +
        String.valueOf(c.parentCaseId) +
        '. PNR: ' +
        c.bookingReference
      ); // If we get here, this should not happen
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'this trip type is not yet supported for automated cancellation handling'
      );
    } else if (c.type == Claim.Type.FlightDelay && !this.canCalculateDelay()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'there were issues calculating the delay'
      );
    } else if (
      (c.type == Claim.Type.FlightDelay &&
      (getMinutesDelayedWithinSASControl() <= (2 * 60) ||
      getMinutesDelayedWithinSASControl() >= (5 * 60)))
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only delays between 2 and 5 hours'
      ); // We should remove this early
    } else {
      return null;
    }
    // TODO: ~Check proactivities Maybe something like if there's any proactivity for this claim, dont do anything. We could also move this to be later.
  }

  /**
   * Returns false if the contact person is allowed to make the claim for all
   * customers claimed in the claim without a power of attorney.
   *
   * They are allowed to do this only if all of the following are true:
   * 1. Claimant is a private customer
   * 2. All claimed passengers can be found from the booking's passengers
   * 3. All claimed passengers have the same last name as the contaxt person
   * 4. There are less than four people overall in the booking
   * 5. TODO: Check if we can somehow identify children from the booking
   * 6. TODO: Consider infants
   */
  private Boolean requiresPowerOfAttorney() {
    Claim c = this.claimObj.objects[0];

    if (
      c.contactType != Claim.ContactType.PrivateCustomer ||
      c.customers.size() > 4
    ) {
      return true;
    }

    for (ClaimCustomer cust : c.customers) {
      if (cust.lastName.toLowerCase() != c.contactLastName.toLowerCase()) {
        return true;
      }

      Boolean claimedCustomerFoundInBooking = false;
      for (Passenger__c p : this.booking.instanceRecords[0].Passengers__r) {
        if (
          p.Last_Name__c.toLowerCase() == cust.lastName.toLowerCase() &&
          p.First_Name__c.toLowerCase() == cust.firstName.toLowerCase()
        ) {
          claimedCustomerFoundInBooking = true;
        }
      }

      if (!claimedCustomerFoundInBooking) {
        return true;
      }
    }

    return false;
  }

  private boolean canCalculateDelay() {
    try {
      getMinutesDelayedWithinSASControl();
    } catch (Exception e) {
      return false;
    }
    return true;
  }

  private Boolean isStaffBooking() {
    // TODO: Implement this. We are not currently storing the data but when we
    // are, this is just something like return ac.booking.IsIdTicket__c;
    return false;
  }

  /**
   * Returns true if the claim was filed on time and the customer is entitled
   * to compensation based on that.
   *
   * The time limit for filing a claim is different in different jurisdictions.
   * We pick the longest of arrival and departure countries' filing limit, so
   * to the benefit of the customer.
   */
  private Boolean isFiledOnTime() {
    Claim c = this.claimObj.objects[0];
    Datetime tripDate = this.tripWithClaimFlight.getFinalDestinationArrivalTime();

    Integer limitInDepartureCountry = countryToClaimTimeLimitInMonths.get(
      this.tripWithClaimFlight.originAirport.Country_Code__c
    );
    Integer limitInArrivalCountry = countryToClaimTimeLimitInMonths.get(
      this.tripWithClaimFlight.destinationAirport.Country_Code__c
    );

    Integer timeLimit;

    if (limitInDepartureCountry != null && limitInArrivalCountry != null) {
      timeLimit = Math.max(limitInDepartureCountry, limitInArrivalCountry);
    } else if (limitInDepartureCountry != null) {
      timeLimit = limitInDepartureCountry;
    } else if (limitInArrivalCountry != null) {
      timeLimit = limitInArrivalCountry;
    } else {
      timeLimit = countryToClaimTimeLimitInMonths.get('default');
    }

    // TODO: Determine if this is enough or we need closer to the exact date. This checks only on month level and ignores the days.
    Boolean filedWithinTimelimit =
      c.createdDate.date().monthsBetween(tripDate.date()) <= timeLimit;

    return filedWithinTimelimit;
  }

  private Decision determineEligibilityAndCalculateCompensation() {
    if (this.isStaffBooking()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'id and staff tickets are not eligible'
      );
    } else if (!this.isWithinEU261Jurisdiction()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'not covered by EU261'
      );
    } else if (!this.isFiledOnTime()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'not filed on time'
      );
    } else if (this.hasCancellation()) {
      // If the claim flight was cancelled the customer should receive compensation according to the cancellation logic
      if (!this.cancellationCodeIsWithinSASControl()) {
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'cancellation code not within SAS control'
        );
      } else {
        return this.calculateCompensationForCancellation();
      }
    } else if (!this.hasDelay()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'flight not cancelled and not delayed'
      );
    } else {
      return this.calculateCompensationForDelay();
    }
  }

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261 regarding cancellations.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   */
  private Decision calculateCompensationForCancellation() {
    // Get the original flight plan
    Trip originalTrip = this.tripWithClaimFlight.getOriginalTripWithFlight();
    Datetime originalDeparture = originalTrip.getFirstFlight()
      .Scheduled_Departure_Time__c;
    Datetime originalArrival = originalTrip.getFlightToFinalDestination()
      .Scheduled_Arrival_Time__c;

    Decimal flightDistanceInKm =
      Airports.distanceBetweenAirportsInMeters(
        this.tripWithClaimFlight.originAirport,
        this.tripWithClaimFlight.destinationAirport
      ) / 1000;
    Integer flightDistanceInKmRounded = flightDistanceInKm.intValue();
    Boolean isIntraCommunity = originalTrip.isIntraCommunity();
    List<FlightIrregularities__c> flightIrregularities = this.flightToIrregularities.get(
      this.claimFlight.Id
    );
    Integer daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture();

    // Get the new (suggested) flight plan
    Trip newTrip = this.tripWithClaimFlight.getSuggestedRebookingWithoutFlight();
    Integer arrivalDifference;
    Integer departureDifference;
    Integer compensation;
    if (newTrip == null) {
      // Current state of this automation as we cannot determine that we have not suggested a rebooking
      Boolean allDataIsAvailable = false; // Temp (dev), EDW
      if (!allDataIsAvailable) {
        // TODO: Can we move this check out of here?
        throw new AutomationException(
          'We do not have enough data to evaluate this claim (likely cancellation without rebooking).'
        );
      }
      // No suggested rebooking => full EU261 (10h outside timeframe => full compensation, except if you were informed on time)
      compensation = calculateCompensationCancellation(
        600,
        0,
        flightDistanceInKmRounded,
        daysUntilFlightWhenInformedOfCancellation,
        isIntraCommunity
      );
    } else {
      Datetime newDeparture = newTrip.getFirstFlight()
        .Scheduled_Departure_Time__c;
      Datetime newArrival = newTrip.getFlightToFinalDestination()
        .Scheduled_Arrival_Time__c;

      // Compare the original rebooking against the suggested rebooking and calculate compensation
      departureDifference = Integer.valueOf(
        DateUtils.getHoursBetween(newDeparture, originalDeparture) * 60
      );
      arrivalDifference = Integer.valueOf(
        DateUtils.getHoursBetween(newArrival, originalArrival) * 60
      ); // Do we need to round up?
      Integer minutesLateOnArrival = 0;
      Integer minutesEarlyOnDeparture = 0;
      if (newArrival > originalArrival) {
        minutesLateOnArrival = arrivalDifference;
      }
      if (newDeparture < originalDeparture) {
        minutesEarlyOnDeparture = departureDifference;
      }

      compensation = calculateCompensationCancellation(
        minutesLateOnArrival,
        minutesEarlyOnDeparture,
        flightDistanceInKmRounded,
        daysUntilFlightWhenInformedOfCancellation,
        isIntraCommunity
      );
    }

    Integer numberOfEligiblePassengers = this.getNumberOfPassengersEligibleForCompensation();

    Integer totalCompensation = compensation * numberOfEligiblePassengers;

    if (totalCompensation > 0) {
      // TODO: Will this ever happen?
      return new Decision('', totalCompensation, 0); // TODO: Reimbursement!
    } else {
      String reason = 'unknown';
      if (numberOfEligiblePassengers == 0) {
        reason = 'there are no passengers which are eligible for compensation';
      } else if (compensation == 0) {
        reason = 'the offered rebooking is not outside the timeframe allowed by EU261';
      }
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        reason
      );
    }
  }

  private Integer getNumberOfPassengersEligibleForCompensation() {
    // TODO: Check: Is fare = 0?

    List<Passenger__c> passengers = this.booking.instanceRecords[0]
      .Passengers__r; // FIXME: This should always be about travelers in claim, not passengers in booking

    List<ClaimCustomer> customers = this.claimObj.objects[0].customers;

    List<Passenger__c> eligiblePassengers = new List<Passenger__c>();

    for (Passenger__c passenger : passengers) {
      Boolean claimedPassenger = false;
      for (ClaimCustomer cc : customers) {
        if (
          cc.firstName.toLowerCase() == passenger.First_Name__c.toLowerCase() &&
          cc.lastName.toLowerCase() == passenger.Last_Name__c.toLowerCase()
        ) {
          claimedPassenger = true;
          break;
        }
      }

      if (claimedPassenger) {
        Boolean isInfant = passenger.Identifier__c.toLowerCase()
          .contains('inf');
        if (isInfant) {
          Boolean isDomesticTripInDenmark =
            this.tripWithClaimFlight.destinationAirport.Country_Code__c ==
            'DK' &&
            this.tripWithClaimFlight.originAirport.Country_Code__c == 'DK';
          if (isDomesticTripInDenmark) {
            eligiblePassengers.add(passenger);
          }
        } else {
          eligiblePassengers.add(passenger);
        }
      }
    }

    return eligiblePassengers.size();
  }

  private Boolean cancellationCodeIsWithinSASControl() {
    FlightIrregularities claimIrregularities = new FlightIrregularities(
      this.flightToIrregularities.get(this.claimFlight.Id)
    );
    claimIrregularities.removeAllButCancellations();
    claimIrregularities.removeDuplicates();

    if (!claimIrregularities.containsCancellation()) {
      throw new AutomationException('Claim flight is not cancelled.');
    }

    Integer noIrregularities = claimIrregularities.instanceRecords.size();
    if (noIrregularities == 1) {
      FlightIrregularities__c relevantIrregularity = claimIrregularities.instanceRecords[0];
      return claimIrregularities.isWithinSASControl()
        .get(relevantIrregularity.Id);
    } else if (noIrregularities == 0) {
      throw new AutomationException(
        'Claim flight has no valid irregularities.'
      );
    } else {
      throw new AutomationException(
        'Cancelled flight has more than one irregularity.'
      );
    }
  }

  private Boolean canDetermineIfSASIsResponsibleForCancellation() {
    try {
      this.cancellationCodeIsWithinSASControl();
      return true;
    } catch (FlightIrregularities.IrregularityException e) {
      return false;
    } catch (AutomationException e2) {
      return false;
    }
  }

  /**
   * TODO: Mover to gather all necessary information and batch
   * @return an Integer of the amount of minutes delayed for the ac.tripWithClaimFlight with the delay minutes outside SAS control deducted.
   */
  private Integer getMinutesDelayedWithinSASControl() {
    Flight__c flight = this.tripWithClaimFlight.getFlightToFinalDestination();
    FlightIrregularities irregularities = new FlightIrregularities(
      this.flightToIrregularities.get(flight.Id)
    );

    Integer delayCausedByIrregularitiesWithinSASControl = FlightService.newInstance()
      .getTotalDelayInMinutesWithinSASControl(
        new Flights(new List<Flight__c>{ flight }),
        this.flightToIrregularities
      )
      .get(flight.Id);
    Integer netDelayedMinutes = Integer.valueOf(
      flight.Arrival_Delayed_Minutes__c
    );

    if (
      delaysOutsideSASControlReducesCompensation(
        netDelayedMinutes,
        delayCausedByIrregularitiesWithinSASControl
      )
    ) {
      // TODO: Move this to a decision somehow?
      /*this.outsideSASControlExplanation =
        'The flight was delayed ' +
        netDelayedMinutes +
        ' minutes on arrival of which ' +
        delayCausedByIrregularitiesWithinSASControl +
        ' minutes were within SAS control. ' +
        irregularities.getOutsideSASControlExplanation();*/
    }

    return delayCausedByIrregularitiesWithinSASControl;
  }

  private Integer getDaysBetweenCancellationAndDeparture() {
    FlightIrregularities claimIrregularities = new FlightIrregularities(
      this.flightToIrregularities.get(this.claimFlight.Id)
    );
    claimIrregularities.removeAllButCancellations();
    claimIrregularities.removeDuplicates();

    if (!claimIrregularities.containsCancellation()) {
      throw new AutomationException('Claim flight is not cancelled.');
    }

    if (claimIrregularities.instanceRecords.size() == 1) {
      FlightIrregularities__c cancellation = claimIrregularities.instanceRecords[0];
      Datetime departureTime = this.claimFlight.Scheduled_Departure_Time__c;
      Datetime cancellationTime = cancellation.Cancellation_Time__c;
      if (cancellationTime == null) {
        throw new AutomationException(
          'Cancellation does not have a cancellation time.'
        );
      }
      Decimal hoursBetween = DateUtils.getHoursBetween(
        departureTime,
        cancellationTime
      );
      Integer daysBetween = (hoursBetween / 24).intValue();
      return daysBetween;
    } else {
      throw new AutomationException(
        'Cancelled flight does not have exactly one irregularity.'
      );
    }
  }

  private Boolean hasRotationIrregularities() {
    Flight__c flight = this.tripWithClaimFlight.getFlightToFinalDestination();
    List<FlightIrregularities__c> flightIrregularities = this.flightToIrregularities.get(
      flight.Id
    );
    FlightIrregularities irregularities = new FlightIrregularities(
      flightIrregularities
    );

    return irregularities.containsRotationIrregularities();
  }

  // TODO: Get rid of this.
  public class AutomationException extends Exception {
  }

  /**
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
  private Boolean isWithinEU261Jurisdiction() {
    // ~TODO(c): Determine if the customer has already received benefits related to a law of a non-EU country
    Boolean hasReceivedBenefitsWhichVoidEU261 = false;

    Airport__c originAirport = this.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = this.tripWithClaimFlight.destinationAirport;
    Boolean isToOrFromEU261Territory = (originAirport.Is_EU261_Applicable__c ||
    destinationAirport.Is_EU261_Applicable__c);

    return (isToOrFromEU261Territory && !hasReceivedBenefitsWhichVoidEU261);
  }

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261 regarding delays.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   */
  private Decision calculateCompensationForDelay() {
    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;
    final Integer MINIMUM_DELAY_FOR_INCREASED_COMPENSATION = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Decimal flightDistanceInM =
      Airports.distanceBetweenAirportsInMeters(
        this.tripWithClaimFlight.originAirport,
        this.tripWithClaimFlight.destinationAirport
      ) / 1000;
    Integer flightDistanceInKm = flightDistanceInM.intValue();
    Integer numberOfEligiblePassengers = this.getNumberOfPassengersEligibleForCompensation();
    Integer delayedMinutes = this.getMinutesDelayedWithinSASControl();

    Integer compensationAmount = 0;

    if (delayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'delayed less than 180 minutes.'
      );
    } else {
      if (flightDistanceInKm <= MEDIUM_DISTANCE) {
        compensationAmount = numberOfEligiblePassengers * 250;
      } else if (
        flightDistanceInKm > MEDIUM_DISTANCE &&
        (flightDistanceInKm <= LONG_DISTANCE ||
        this.tripWithClaimFlight.isIntraCommunity())
      ) {
        compensationAmount = numberOfEligiblePassengers * 400;
      } else if (delayedMinutes < MINIMUM_DELAY_FOR_INCREASED_COMPENSATION) {
        compensationAmount = numberOfEligiblePassengers * 300;
      } else if (delayedMinutes >= MINIMUM_DELAY_FOR_INCREASED_COMPENSATION) {
        compensationAmount = numberOfEligiblePassengers * 600;
      } else {
        // TODO: Can we get rid of this?
        throw new AutomationException('Invalid compensation calculation.');
      }

      if (numberOfEligiblePassengers == 0) {
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'no passenger in this claim has a revenue ticket.'
        );
      } else {
        return new Decision('', compensationAmount, 0); // TODO: Several customers, reimbursement!
      }
    }
  }

  private Integer calculateCompensationCancellation(
    Integer minutesLateOnArrival,
    Integer minutesEarlyOnDeparture,
    Integer flightDistanceInKm,
    Integer daysUntilFlightWhenInformedOfCancellation,
    Boolean isIntraCommunity
  ) {
    final Integer MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL = 240;
    final Integer MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE = 120;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE = 120;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE = 180;
    final Integer MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Boolean isEligableForCompensation =
      isOutSideTimeFrame(
        MAXIMUM_ACCEPTABLE_TIME_LATE_ARRIVAL,
        minutesLateOnArrival,
        daysUntilFlightWhenInformedOfCancellation
      ) ||
      isOutSideTimeFrame(
        MAXIMUM_ACCEPTABLE_TIME_EARLY_DEPARTURE,
        minutesEarlyOnDeparture,
        daysUntilFlightWhenInformedOfCancellation
      );

    if (!isEligableForCompensation) {
      return 0;
    }

    Integer compensation;
    if (flightDistanceInKm <= MEDIUM_DISTANCE) {
      compensation = 250;
      if (
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE
      ) {
        compensation /= 2;
      }
    } else if (
      flightDistanceInKm > MEDIUM_DISTANCE &&
      (flightDistanceInKm <= LONG_DISTANCE || isIntraCommunity)
    ) {
      compensation = 400;
      if (
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE
      ) {
        compensation /= 2;
      }
    } else {
      compensation = 600;
      if (
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE
      ) {
        compensation /= 2;
      }
    }

    return compensation;
  }

  private Boolean isOutSideTimeFrame(
    Integer timeFrame,
    Integer deviation,
    Integer daysUntilFlightWhenInformedOfCancellation
  ) {
    Integer minutesOutsideTimeFrame;
    if (daysUntilFlightWhenInformedOfCancellation > 14) {
      minutesOutsideTimeFrame = 0;
    } else if (
      daysUntilFlightWhenInformedOfCancellation <= 14 &&
      daysUntilFlightWhenInformedOfCancellation > 7
    ) {
      minutesOutsideTimeFrame = Math.max(0, deviation - timeFrame);
    } else {
      minutesOutsideTimeFrame = Math.max(0, deviation - timeFrame / 2);
    }

    return minutesOutsideTimeFrame > 0;
  }

  private Boolean delaysOutsideSASControlReducesCompensation(
    Decimal totalDelay,
    Decimal delayWithinSASControl
  ) {
    List<Decimal> delayThresholds = new List<Decimal>{
      120.0,
      180.0,
      240.0,
      300.0
    };
    for (Decimal threshold : delayThresholds) {
      Boolean totalDelayAbove = totalDelay > threshold;
      Boolean withinControlAbove = delayWithinSASControl > threshold;
      if (totalDelayAbove != withinControlAbove) {
        return true;
      }
    }
    return false;
  }
}
