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
    'default' => 6 * 12
  };

  public enum SemiAutomationReason {
    RequiresPowerOfAttorney,
    HasPotentialDuplicates,
    HasHighClaimExpenses,
    InvalidSettlementDetails
  }

  /**
   * Evaluates the claim according to the EU261 rules and returns the decision
   * made on whether the claim should be paid out.
   *
   * The result is also stored in this.decision.
   */
  public Decision evaluate() {
    this.decision = this.canWeEvaluate();

    if (this.decision == null) {
      // If decision is null from above, we should be able to evaluate this claim.
      this.decision = this.determineEligibilityAndCalculateCompensation();
      this.decision.reimbursementAmountInSEK = calculateReimbursement();
    }

    if (
      this.decision.verdict ==
      Claim.EU261HandlingStatus.EligibleForCompensation &&
      this.getSemiAutomationReasons().size() != 0
    ) {
      this.decision.verdict = Claim.EU261HandlingStatus.PossiblyEligibleForCompensation;
      this.decision.caveats = this.getSemiAutomationReasons();
    }

    return this.decision;
  }

  private static Set<String> invalidFareBases = new Set<String>{};

  public class CreateException extends Exception {
  }

  /**
   * Represents the outcome of evaluating a customer claim according to EU261
   * rules.
   *
   * Consists of the overall verdict of whether the customer is eligible for
   * compensation or not, or that we can't handle the claim.
   *
   * When the claim should be paid out, the decision also contains information
   * about the amounts of compensation and reimbursement that should be paid
   * out.
   */
  public class Decision {
    /**
     * The total reimbursement that can be paid out based on this decision in
     * SEK.
     *
     * There's only one total for reimbursement because the costs are not tied
     * to a specific customer like they are with compensation.
     */
    public Money reimbursementAmountInSEK { get; private set; }

    /**
     * The compensation which should be paid out based on this decision.
     * Keys are the claimed customers and values the amount to be paid out to
     * that customer in euros.
     */
    public Map<ClaimCustomer, Money> compensationPerCustomerInEUR {
      get;
      private set;
    }

    /**
     * The overall verdict of whether a customer is eligible for compensation.
     */
    public Claim.EU261HandlingStatus verdict { get; private set; }

    /**
     * Clarifications on how the decision was reached, if available.
     */
    public String reasoning { get; private set; }

    /**
     * Any caveats to the decision. Must be populated if verdict is PossiblyEligibleForCompensation.
     * Otherwise null.
     */
    public List<SemiAutomationReason> caveats { get; private set; }

    Decision(Claim.EU261HandlingStatus verdict, String reasoning) {
      if (verdict == Claim.EU261HandlingStatus.EligibleForCompensation) {
        throw new CreateException(
          'Cannot create an eligible decision without compensation or reimbursement amount.'
        );
      }
      this.verdict = verdict;
      this.reasoning = reasoning;
      this.reimbursementAmountInSEK = new Money(0, Money.CurrencyCode.SEK);
    }

    Decision(
      String reasoning,
      Map<ClaimCustomer, Money> compensationByCustomer,
      Money reimbursementAmountInSEK
    ) {
      if (
        reimbursementAmountInSEK.amount == 0 &&
        (compensationByCustomer == null || compensationByCustomer.isEmpty())
      ) {
        throw new CreateException(
          'Cannot create an eligible decision with compensation and reimbursement amount both set to 0.'
        );
      }
      this.verdict = Claim.EU261HandlingStatus.EligibleForCompensation;
      this.reasoning = reasoning;
      this.compensationPerCustomerInEUR = compensationByCustomer;
      this.reimbursementAmountInSEK = reimbursementAmountInSEK;
    }
  }

  public Claim claimObj { public get; private set; }
  @TestVisible
  private Booking claimedBooking;
  private Trip tripWithClaimFlight;
  private Trip tripWithClaimFlightReplacement;
  private Boolean hasPotentiallyDuplicateClaims = false;
  private Boolean foundMultipleMatchingBookings = false;
  private Boolean hasCancellation;
  private Boolean couldInitializeTrips;
  private Flight claimFlight;

  private EU261Service.Config config;

  /**
   * The decision made on this claim. Populated by this.evaluate().
   */
  public Decision decision { public get; private set; }

  public EU261Claim(
    Claim c,
    List<Booking> b,
    Boolean hasPotentiallyDuplicateClaims,
    EU261Service.Config config
  ) {
    this.claimObj = c;
    this.config = config;

    this.hasPotentiallyDuplicateClaims = hasPotentiallyDuplicateClaims; // TODO: This should be moved out of here. Decision should be based only on this single claim, comparison to others can be done elsewhere.

    if (b != null && b.size() != 0) {
      this.claimedBooking = b[0];
      this.foundMultipleMatchingBookings = b.size() > 1;

      String flightNumberDate = Flight.constructTEDSFlightNumberDate(
        c.flightNumber,
        c.departureDate
      );

      for (Flight f : this.claimedBooking.flights) {
        String flightId = Flight.TEDSIdToSimpleFlightIds(f.tedsIdentifier)[0];
        if (flightId == flightNumberDate) {
          this.claimFlight = f;
          this.hasCancellation = f.getCancellations().size() > 0;
          break;
        }
      }
    }
  }

  public static List<LIA_Claim__c> getClaimSObjectsFor(
    List<EU261Claim> eu261Claims
  ) {
    List<LIA_Claim__c> toReturn = new List<LIA_Claim__c>();

    for (EU261Claim cl : eu261Claims) {
      toReturn.add(cl.claimObj.underlyingSObject);
    }

    return toReturn;
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

  private Boolean hasMoreThanOneCancellation() {
    Integer count = 0;
    for (Flight f : this.claimedBooking.flights) {
      for (FlightIrregularity fi : f.irregularities) {
        if (fi.isCancellation() && !fi.isArrivalCancellation()) {
          // We can ignore arrival cancellation in here because there's always
          // one if the departure is cancelled.
          count += 1;
        }
      }
    }
    return count > 1;
  }

  private Boolean hasOnlyOneFlightRoute() {
    String firstFlightRoute =
      this.claimedBooking.segments[0].flight.departureAirport +
      this.claimedBooking.segments[0].flight.arrivalAirport;
    for (Segment s : this.claimedBooking.segments) {
      String segmentFlightRoute =
        s.flight.departureAirport + s.flight.arrivalAirport;
      if (segmentFlightRoute != firstFlightRoute) {
        return false;
      }
    }
    return true;
  }

  private static Set<Type> tripSetExceptions = new Set<Type>{
    Trip.BookingTypeNotSupportedException.class,
    Segment.UnsupportedException.class,
    Trip.RouteException.class,
    Trip.InvalidException.class,
    AbstractSObjectWrapper.MissingDataException.class,
    Booking.UnsupportedException.class
  };

  /**
   * Calculates and sets the trip objects tripWithClaimFlight and tripWithClaimFlightReplacement
   *
   * @throws Trip.InvalidException if the trips calculated are invalid.
   * @throws Trip.BookingTypeNotSupportedException if the booking type is not yet supported.
   * @throws Segment.UnsupportedException if there are unsupported segment event statuses
   * @throws Trip.RouteException if there is an error when checking the trip validity (infinite loop)
   * @throws AbstractSObjectWrapper.MissingDataException if there is no cancellation time
   * @throws Booking.UnsupportedException if there is more than one cancellation
   */
  private void calculateAndSetTrips() {
    if (this.hasCancellation) {
      List<Trip> beforeAndAfterCancellation = claimedBooking.getTripsBeforeAndAfterCancellation(
        claimFlight
      );

      this.tripWithClaimFlight = beforeAndAfterCancellation[0];
      this.tripWithClaimFlightReplacement = beforeAndAfterCancellation[1];
    } else {
      this.tripWithClaimFlight = claimedBooking.getTripWithFlight(claimFlight);
    }
  }

  private Boolean canGetSegmentStatuses() {
    try {
      for (Segment s : this.claimedBooking.segments) {
        s.getStatus(Datetime.now());
      }
    } catch (Segment.UnsupportedException e) {
      return false;
    } catch (U.InvalidArgumentException e) {
      return false;
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
    Claim c = this.claimObj;
    if (c.personWithReducedMobility) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims with person with reduced mobility'
      );
    } else if (c.unaccompaniedMinor) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims with unaccompanied minors'
      );
    } else if (c.category != Claim.Category.FlightDisruptions) {
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
    } else if (this.claimedBooking == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim is not associated with a booking'
      );
    } else if (this.foundMultipleMatchingBookings) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only one booking per claim'
      );
      // TODO: Think about how to handle repeat PNRs.
      // TODO: Think about the potential fraud cases.
      // TODO: Ensure that we have only a specific number of trips.
    } else if (
      this.claimedBooking.type != Booking.Type.OneWay &&
      this.claimedBooking.type != Booking.Type.RoundTrip
    ) {
      // TODO: I guess we need to get rid of the booking variable?
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only one way or round trips'
      );
    } else if (this.claimedBooking.flights.size() == 0) {
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
      invalidFareBases.contains(this.claimedBooking.segments[0].fareBasis)
    ) {
      // TODO: Move this to be evaluation instead.
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims with a restricted fare basis.'
      );
    } else if (this.claimFlight == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot find claimed flight from booking'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation && !this.hasCancellation
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight is not cancelled'
      );
    } else if (hasMoreThanOneCancellation()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'there are more than one cancellation connected to this claim'
      );
    } else if (this.hasRotationIrregularities()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle flights with irregularities caused by rotations'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation &&
      !this.canDetermineIfSASIsResponsibleForCancellation()
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot determine wether SAS is responsible or not for the cancellation'
      );
    } else if (!this.cancellationCodeIsWithinSASControl()) {
      return null; // Maybe not fantastic, but if we are not responsible we don't need any more checks
    } else if (!canGetSegmentStatuses()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot get segment statuses'
      );
    }

    // To continue the evaluation we have to construct the trip(s)
    this.couldInitializeTrips = false;
    Exception tripCalculationError;
    try {
      this.calculateAndSetTrips();
      this.couldInitializeTrips = true;
    } catch (Exception e) {
      Type error = Type.forName(e.getTypeName());
      if (tripSetExceptions.contains(error)) {
        tripCalculationError = e;
      } else {
        throw e;
      }
    }

    if (!this.couldInitializeTrips) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'was not able to divide the booking into trips (' +
        tripCalculationError.getMessage() +
        ')'
      );
    } else if (this.tripWithClaimFlight == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'could not set trip with claim flight'
      );
    } else if (this.tripWithClaimFlightReplacement == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'rebooking was likely not offered'
      );
    } else if (
      !this.tripWithClaimFlight.originAirport.isEU261Applicable ||
      !this.tripWithClaimFlight.destinationAirport.isEU261Applicable
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can only handle claims with origin and destination airports in EU'
      );
    } else if (
      !this.tripWithClaimFlight.SASIsOnlyOperatingCarrier ||
      !this.tripWithClaimFlightReplacement.SASIsOnlyOperatingCarrier
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle claims where SAS is not the only operating carrier'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation &&
      this.tripWithClaimFlight == this.tripWithClaimFlightReplacement
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the trip did not change before and after the cancellation (likely "cancellation <-> event" time mismatch)'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation &&
      this.tripWithClaimFlight.cancelledSegmentRemovedBeforeCancellation
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'it is uncertain if SAS or the customer cancelled the flight'
      );
    } else if (
      c.type == Claim.Type.FlightCancellation &&
      this.claimedBooking.hasReinstated(this.claimFlight)
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'claim flight was reinstated'
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
    Claim c = this.claimObj;

    if (
      c.contactType != Claim.ContactType.PrivateCustomer ||
      c.customers.size() > 5
    ) {
      return true;
    }

    for (ClaimCustomer cust : c.customers) {
      if (cust.lastName.toLowerCase() != c.contactLastName.toLowerCase()) {
        return true;
      }

      Boolean claimedCustomerFoundInBooking = false;
      for (Passenger p : this.claimedBooking.passengers) {
        if (
          p.lastName.toLowerCase() == cust.lastName.toLowerCase() &&
          p.firstName.toLowerCase() == cust.firstName.toLowerCase()
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
      System.debug(e.getMessage());
      return false;
    }
    return true;
  }

  private Boolean isStaffBooking() {
    if (this.claimedBooking.isStaffBooking == null) {
      return false;
    } else {
      return this.claimedBooking.isStaffBooking;
    }
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
    Claim c = this.claimObj;
    Datetime tripDate = this.tripWithClaimFlight.getFinalDestinationArrivalTime();

    Integer limitInDepartureCountry = countryToClaimTimeLimitInMonths.get(
      this.tripWithClaimFlight.originAirport.countryCode
    );
    Integer limitInArrivalCountry = countryToClaimTimeLimitInMonths.get(
      this.tripWithClaimFlight.destinationAirport.countryCode
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
    } else if (
      this.hasCancellation && !this.cancellationCodeIsWithinSASControl()
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'cancellation code not within SAS control'
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
    } else if (this.hasCancellation) {
      // If the claim flight was cancelled the customer should receive compensation according to the cancellation logic
      return this.calculateCompensationForCancellation();
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
    // FLight plan before the cancellation
    Trip originalTrip = this.tripWithClaimFlight;
    Datetime originalDeparture = originalTrip.getFirstFlight()
      .scheduledDepartureTime;
    Datetime originalArrival = originalTrip.getFlightToFinalDestination()
      .scheduledArrivalTime;

    Decimal flightDistanceInKm =
      Airport.distanceBetweenAirportsInMeters(
        originalTrip.originAirport,
        originalTrip.destinationAirport
      ) / 1000;
    Integer flightDistanceInKmRounded = flightDistanceInKm.intValue();
    Boolean isIntraCommunity = originalTrip.isIntraCommunity();
    Integer daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture();

    // Get the new (suggested) flight plan, todo: check that this is correct
    Trip newTrip = this.tripWithClaimFlightReplacement;
    Integer arrivalDifference;
    Integer departureDifference;
    Money compensation;
    if (newTrip == null) {
      // This will currently never happen (see initialization of the EU261Claim)
      if (true) {
        // Temp, todo: handle these cases
        throw new AutomationException(
          'The replacement trip should never be null'
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
      Datetime newDeparture = newTrip.getFirstFlight().scheduledDepartureTime;
      Datetime newArrival = newTrip.getFlightToFinalDestination()
        .scheduledArrivalTime;

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

    List<ClaimCustomer> eligiblePassengers = this.getPassengersEligibleForCompensation();

    if (eligiblePassengers.size() == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'there are no passengers which are eligible for compensation'
      );
    }

    if (compensation == new Money(0, Money.CurrencyCode.EUR)) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'the offered rebooking is not outside the timeframe allowed by EU261'
      );
    }

    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();

    for (ClaimCustomer p : eligiblePassengers) {
      compensationByCustomer.put(p, compensation);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.EUR)
    ); // TODO: reimbursement
  }

  private List<ClaimCustomer> getPassengersEligibleForCompensation() {
    // TODO: Check: Is fare = 0?

    List<Passenger> passengers = this.claimedBooking.passengers;

    List<ClaimCustomer> customers = this.claimObj.customers;

    List<ClaimCustomer> eligibleCustomers = new List<ClaimCustomer>();

    for (Passenger passenger : passengers) {
      for (ClaimCustomer cc : customers) {
        if (
          cc.firstName.toLowerCase() == passenger.firstName.toLowerCase() &&
          cc.lastName.toLowerCase() == passenger.lastName.toLowerCase()
        ) {
          Boolean isInfant = passenger.identifier.toLowerCase().contains('inf');

          if (!isInfant) {
            eligibleCustomers.add(cc);
          } else {
            // Infants are usually not entitled to compensation
            Boolean isDomesticTripInDenmark =
              this.tripWithClaimFlight.destinationAirport.countryCode == 'DK' &&
              this.tripWithClaimFlight.originAirport.countryCode == 'DK';
            if (isDomesticTripInDenmark) {
              // Unless the trip is a domestic flight in denmark.
              eligibleCustomers.add(cc);
            }
          }

          break;
        }
      }
    }

    return eligibleCustomers;
  }

  private Money calculateReimbursement() {
    return this.claimObj.submittedClaimExpenses.setScale(0);
  }

  private Boolean cancellationCodeIsWithinSASControl() {
    if (
      claimFlight.irregularities == null ||
      claimFlight.irregularities.size() == 0
    ) {
      throw new AutomationException(
        'Claim flight has no valid irregularities.'
      );
    } else if (claimFlight.irregularities.size() > 1) {
      throw new AutomationException(
        'Cancelled flight has more than one irregularity.'
      );
    }

    return claimFlight.irregularities[0].isWithinSASControl();
  }

  private Boolean canDetermineIfSASIsResponsibleForCancellation() {
    try {
      this.cancellationCodeIsWithinSASControl();
      return true;
    } catch (FlightIrregularity.IrregularityException e) {
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
    Flight f = this.tripWithClaimFlight.getFlightToFinalDestination();

    Integer delayCausedByIrregularitiesWithinSASControl = FlightService.newInstance()
      .getTotalDelayInMinutesWithinSASControl(
        new List<Flight>{ f },
        new Map<Id, List<FlightIrregularity>>{ f.id => f.irregularities }
      )
      .get(f.id);
    Integer netDelayedMinutes = Integer.valueOf(f.arrivalDelayedMinutes);

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
    List<FlightIrregularity> claimIrregularities = new List<FlightIrregularity>();

    for (FlightIrregularity fi : this.claimFlight.irregularities) {
      if (fi.isCancellation() && !fi.isArrivalCancellation()) {
        claimIrregularities.add(fi);
      }
    }

    if (claimIrregularities.size() == 0) {
      throw new AutomationException('Claim flight is not cancelled.');
    }

    if (claimIrregularities.size() > 1) {
      throw new AutomationException(
        'Cancelled flight does not have exactly one irregularity.'
      );
    }
    FlightIrregularity cancellation = claimIrregularities[0];

    Datetime departureTime = this.claimFlight.scheduledDepartureTime;
    Datetime cancellationTime = cancellation.cancellationTime;
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
  }

  private Boolean hasRotationIrregularities() {
    for (FlightIrregularity fi : this.claimFlight.irregularities) {
      if (fi.isRotation()) {
        return true;
      }
    }
    return false;
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
    return true; // Until we have other operating carriers.
    // As SAS is EU carrier, we're always under EU jurisdiction as operating carrier.

    /* TODO: Add operating carrier check

    Airport__c originAirport = this.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = this.tripWithClaimFlight.destinationAirport;
    Boolean isToOrFromEU261Territory = (originAirport.Is_EU261_Applicable__c ||
    destinationAirport.Is_EU261_Applicable__c);

    return (isToOrFromEU261Territory && !hasReceivedBenefitsWhichVoidEU261);
    */
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
      Airport.distanceBetweenAirportsInMeters(
        this.tripWithClaimFlight.originAirport,
        this.tripWithClaimFlight.destinationAirport
      ) / 1000;
    Integer flightDistanceInKm = flightDistanceInM.intValue();
    List<ClaimCustomer> passengersEligibleForCompensation = this.getPassengersEligibleForCompensation();
    Integer delayedMinutes = this.getMinutesDelayedWithinSASControl();

    if (passengersEligibleForCompensation.size() == 0) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'no passenger in this claim has a revenue ticket.'
      );
    }

    if (delayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'delayed less than 180 minutes.'
      );
    }

    Money compensationAmount = new Money(0, Money.CurrencyCode.EUR);

    if (flightDistanceInKm <= MEDIUM_DISTANCE) {
      compensationAmount = new Money(250, Money.CurrencyCode.EUR);
    } else if (
      flightDistanceInKm > MEDIUM_DISTANCE &&
      (flightDistanceInKm <= LONG_DISTANCE ||
      this.tripWithClaimFlight.isIntraCommunity())
    ) {
      compensationAmount = new Money(400, Money.CurrencyCode.EUR);
    } else if (delayedMinutes < MINIMUM_DELAY_FOR_INCREASED_COMPENSATION) {
      compensationAmount = new Money(300, Money.CurrencyCode.EUR);
    } else if (delayedMinutes >= MINIMUM_DELAY_FOR_INCREASED_COMPENSATION) {
      compensationAmount = new Money(600, Money.CurrencyCode.EUR);
    } else {
      // TODO: Can we get rid of this?
      throw new AutomationException('Invalid compensation calculation.');
    }
    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();

    for (ClaimCustomer p : passengersEligibleForCompensation) {
      compensationByCustomer.put(p, compensationAmount);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.EUR)
    ); // TODO: reimbursement
  }

  private Money calculateCompensationCancellation(
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
      return new Money(0, Money.CurrencyCode.EUR);
    }

    Money compensation;
    if (flightDistanceInKm <= MEDIUM_DISTANCE) {
      compensation = new Money(250, Money.CurrencyCode.EUR);
      if (
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE
      ) {
        compensation = compensation.divideBy(2);
      }
    } else if (
      flightDistanceInKm > MEDIUM_DISTANCE &&
      (flightDistanceInKm <= LONG_DISTANCE || isIntraCommunity)
    ) {
      compensation = new Money(400, Money.CurrencyCode.EUR);
      if (
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE
      ) {
        compensation = compensation.divideBy(2);
      }
    } else {
      compensation = new Money(600, Money.CurrencyCode.EUR);
      if (
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE
      ) {
        compensation = compensation.divideBy(2);
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

  public Boolean hasHighClaimedExpenses() {
    if (
      this.claimObj.submittedClaimExpenses == null ||
      this.claimObj.submittedClaimExpenses.equals(
        new Money(0, Money.CurrencyCode.SEK)
      )
    ) {
      return false;
    }

    Boolean anySingleExpenseOverLimit = false;

    for (ClaimExpense ce : this.claimObj.expenses) {
      Money expenseLimit = new Money(0, Money.CurrencyCode.SEK);

      switch on ce.type {
        when Accommodation {
          expenseLimit = this.config.expenseLimitAccommodation;
        }
        when Food {
          expenseLimit = this.config.expenseLimitFood;
        }
        when PhoneCalls {
          expenseLimit = this.config.expenseLimitPhoneCalls;
        }
        when Transportation {
          expenseLimit = this.config.expenseLimitTransportation;
        }
      }

      if (
        (new Money(ce.amountInSEK, Money.CurrencyCode.SEK))
          .greaterThan(expenseLimit)
      ) {
        anySingleExpenseOverLimit = true;
        break;
      }
    }

    return anySingleExpenseOverLimit ||
      this.claimObj.submittedClaimExpenses.greaterThan(
        config.expenseLimitTotal
      );
  }

  private List<SemiAutomationReason> getSemiAutomationReasons() {
    List<SemiAutomationReason> toReturn = new List<SemiAutomationReason>();

    if (this.hasPotentiallyDuplicateClaims) {
      toReturn.add(SemiAutomationReason.HasPotentialDuplicates);
    }

    if (this.hasHighClaimedExpenses()) {
      toReturn.add(SemiAutomationReason.HasHighClaimExpenses);
    }

    if (this.requiresPowerOfAttorney()) {
      toReturn.add(SemiAutomationReason.RequiresPowerOfAttorney);
    }

    return toReturn;
  }

}
