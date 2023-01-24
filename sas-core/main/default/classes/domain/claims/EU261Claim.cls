/**
 * A class for evaluating claims against the EU261 regulation to determine
 * whether the claims should be compensated.
 *
 * Individuals instances of this class are individual claims from a customer.
 *
 * See EU261Service and Confluence for more details.
 */
public class EU261Claim {
  private static final Map<String, Integer> COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS = new Map<String, Integer>{
    'BE' => 12,
    'DK' => 3 * 12,
    'FI' => 3 * 12,
    'FR' => 5 * 12,
    'DE' => 3 * 12, // TODO: Change to 2 years + time until end of year 3 (e.g. 25 months 2022-12 -> 2024-12-31)
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
    try {
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
      } else if (
        this.decision.verdict ==
        Claim.EU261HandlingStatus.IneligibleForCompensation &&
        this.decision.reimbursementAmountInSEK.amount != 0
      ) {
        // Not eligible for compensation but eligible for reimbursement
        this.decision.verdict = Claim.EU261HandlingStatus.ReimbursementOnly;
        this.decision.caveats = this.getSemiAutomationReasons();
      }
    } catch (Exception e) {
      Decision errorDecision = new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'Uncaught exception: ' + e.getMessage()
      );
      this.decision = errorDecision;
    }

    writeProtocol();
    return this.decision;
  }

  private void writeProtocol() {
    protocol.decision = this.decision;
    protocol.claimFlight = this.claimFlight;
    protocol.initialTrip = this.tripWithClaimFlight;
    protocol.replacementTrip = this.tripWithClaimFlightReplacement;
    protocol.claimObj = this.claimObj;
    if (
      this.claimFlight != null &&
      this.claimFlight.irregularities.size() == 1
    ) {
      protocol.irregularity = claimFlight.irregularities[0];
    }
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
  public EU261Protocol protocol = new EU261Protocol();
  public Integer netDelayInMinutes;

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

  private Boolean claimFlightHasMoreThanOneCancellation() {
    Integer count = 0;
    for (FlightIrregularity fi : claimFlight.irregularities) {
      if (fi.isCancellation() && !fi.isArrivalCancellation()) {
        // We can ignore arrival cancellation in here because there's always
        // one if the departure is cancelled.
        count += 1;
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
    for (Segment s : this.claimedBooking.segments) {
      try {
        s.getStatus(Datetime.now());
      } catch (Segment.UnsupportedException e) {
        continue;
      } catch (U.InvalidArgumentException e) {
        return false;
      }
    }
    return true;
  }

  private Boolean bookingHasUnsupportedEvents() {
    for (Segment s : this.claimedBooking.segments) {
      try {
        s.getStatus(Datetime.now());
      } catch (Segment.UnsupportedException e) {
        return true;
      } catch (U.InvalidArgumentException e) {
        continue;
      }
    }
    return false;
  }

  /**
   * Checks whether we're able to evaluate this claim with the data we have on
   * it. Returns a decision with verdict of UnableToHandle if we cannot handle
   * this claim. Returns null if we _can_ evaluate it.
   */
  private Decision canWeEvaluate() {
    Claim c = this.claimObj;
    Boolean isCancellationClaim = c.type == Claim.Type.FlightCancellation;
    Boolean isDelayClaim = c.type == Claim.Type.FlightDelay;

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
    } else if (!(isCancellationClaim || isDelayClaim)) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims in type "Flight cancellation" or "Flight delay"'
      );
    } else if (c.recordType != Claim.RecordType.CustomerClaim) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'can handle only claims with record type CustomerClaim'
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
    } else if (this.claimFlight == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot find claimed flight from booking'
      );
    } else if (isCancellationClaim && !this.hasCancellation) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the claim flight is not cancelled'
      );
    } else if (isDelayClaim && this.hasCancellation) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the flight is cancelled but the customer has claimed for a delay'
      );
    } else if (isCancellationClaim && claimFlightHasMoreThanOneCancellation()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'there are more than one cancellation connected to the claim flight'
      );
    } else if (isCancellationClaim && flightCancelledWellInTime()) {
      return null; // If flight was cancelled 14 days, or more, in advance the customer is not eligible
    } else if (isDelayClaim && this.hasRotationIrregularities()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle flights with delays caused by rotations'
      );
    } else if (
      isCancellationClaim &&
      !this.canDetermineIfSASIsResponsibleForCancellation()
    ) {
      try {
        this.cancellationCodeIsWithinSASControl();
      } catch (Exception e) {
        return new Decision(
          Claim.EU261HandlingStatus.UnableToHandle,
          'cannot determine wether SAS is responsible or not for the cancellation | ' +
          e.getMessage()
        );
      }
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot determine wether SAS is responsible or not for the cancellation'
      );
    } else if (
      isCancellationClaim &&
      !this.cancellationCodeIsWithinSASControl() &&
      this.claimObj.submittedClaimExpenses.amount == 0
    ) {
      // This probably works, maybe tell customer that this was automated (a lot of process issues)
      return null; // If we are not responsible, and if the customer did not submit expenses, we don't need any more checks
    } else if (!canGetSegmentStatuses()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot get segment statuses'
      );
    } else if (bookingHasUnsupportedEvents()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'booking has unsupported event(s)'
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
    } else if (this.claimFlight.getOperator() == null) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot parse claim flight operator'
      );
    } else if (!this.claimFlight.isOperatedByStarAlliance()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'claim flight is not operated by Star Alliance'
      );
    } else if (!this.claimFlight.isOperatedBySAS()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'claim flight is not operated by SAS'
      );
    } else if (
      isCancellationClaim &&
      this.tripWithClaimFlight == this.tripWithClaimFlightReplacement
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the trip did not change before and after the cancellation (likely "cancellation <-> event" time mismatch)'
      );
    } else if (
      isCancellationClaim && this.tripWithClaimFlight.isUncertainWhoCancelled()
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'it is uncertain if SAS or the customer cancelled the flight'
      );
    } else if (
      isCancellationClaim && this.tripWithClaimFlight.customerCancelled()
    ) {
      return null; // Deny, customer cancelled the flight
    } else if (
      isCancellationClaim && this.claimedBooking.hasReinstated(this.claimFlight)
    ) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'claim flight was reinstated'
      );
    } else if (isDelayClaim && !this.canCalculateDelay()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'cannot handle tentative delays'
      );
    } else if (isDelayClaim && !this.isSimpleDelay()) {
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'the delay is too complicated'
      );
    } else {
      return null;
    }
  }

  private Boolean contactIsATraveler() {
    Claim c = this.claimObj;

    Boolean contactFoundInBooking = false;
    for (ClaimCustomer cust : c.customers) {
      if (cust.normalizedFullName == c.normalizedContactFullName) {
        contactFoundInBooking = true;
      }
    }

    return contactFoundInBooking;
  }

  /**
   * Asserts that all claimed travelers can be found from the booking's passengers
   */
  private Boolean allClaimedTravelersAreInBooking() {
    Claim c = this.claimObj;

    for (ClaimCustomer cust : c.customers) {
      Boolean claimedCustomerFoundInBooking = false;
      for (Passenger p : this.claimedBooking.passengers) {
        if (p.normalizedFullName == cust.normalizedFullName) {
          claimedCustomerFoundInBooking = true;
        }
      }

      if (!claimedCustomerFoundInBooking) {
        return false;
      }
    }

    return true;
  }

  /**
   * Returns false if the contact person is allowed to make the claim for all
   * customers claimed in the claim without a power of attorney.
   *
   * They are allowed to do this only if all of the following are true:
   * 1. Claimant is a private customer
   * 2. All claimed passengers have the same last name as the contact person
   * 3. There are five or fewer people overall in the claim
   */
  private Boolean requiresPowerOfAttorney() {
    Claim c = this.claimObj;
    if (
      c.contactType != Claim.ContactType.PrivateCustomer ||
      (c.customers.size() > 5)
    ) {
      // The larger than 5 customer is an arbitrary number to ensure that large
      // groups are always vetted by an agent for safety.
      return true;
    }

    if (!contactIsATraveler()) {
      return true;
    }

    if (!allClaimedTravelersAreInBooking()) {
      return true;
    }

    for (ClaimCustomer cust : c.customers) {
      if (cust.normalizedLastName != c.normalizedContactLastName && false) {
        return true; // Temporarily deactivated for backlog
      }
    }

    return false;
  }

  private Boolean canCalculateDelay() {
    // TODO: improve
    try {
      getMinutesDelayedWithinSASControl();
    } catch (FlightIrregularity.IrregularityException e) {
      return false;
    }
    return true;
  }

  private Boolean flightCancelledWellInTime() {
    try {
      Integer daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture();
      return daysUntilFlightWhenInformedOfCancellation >= 14;
    } catch (AutomationException e) {
      return false; // Not perfect, wanted to avoid another canDetermineIfSASIsResponsibleForCancellation
    }
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

    Integer limitInDepartureCountry = COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS.get(
      this.tripWithClaimFlight.originAirport.countryCode
    );
    Integer limitInArrivalCountry = COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS.get(
      this.tripWithClaimFlight.destinationAirport.countryCode
    );

    Integer timeLimit;
    Integer defaultTimeLimit = COUNTRY_TO_CLAIM_TIME_LIMIT_IN_MONTHS.get(
      'default'
    );

    if (limitInDepartureCountry != null && limitInArrivalCountry != null) {
      timeLimit = Math.max(limitInDepartureCountry, limitInArrivalCountry);
    } else if (limitInDepartureCountry != null) {
      timeLimit = Math.max(limitInDepartureCountry, defaultTimeLimit);
    } else if (limitInArrivalCountry != null) {
      timeLimit = Math.max(limitInArrivalCountry, defaultTimeLimit);
    } else {
      timeLimit = defaultTimeLimit;
    }

    protocol.claimFilingTimeLimit = timeLimit;

    // TODO: Determine if this is enough or we need closer to the exact date. This checks only on month level and ignores the days.
    Boolean filedWithinTimelimit =
      Math.abs(c.createdDate.date().monthsBetween(tripDate.date())) <=
      timeLimit;

    return filedWithinTimelimit;
  }

  private Decision determineEligibilityAndCalculateCompensation() {
    if (this.isStaffBooking()) {
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'id and staff tickets are not eligible'
      );
    } else if (this.hasCancellation && flightCancelledWellInTime()) {
      protocol.denialReason = EU261Protocol.DenialReason.CANCELLEDWELLINTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'flight was cancelled 14 or more days in advance'
      );
    } else if (
      this.hasCancellation && !this.cancellationCodeIsWithinSASControl()
    ) {
      if (this.claimObj.submittedClaimExpenses.amount != 0) {
        this.calculateCompensationForCancellation();
      }
      protocol.denialReason = EU261Protocol.DenialReason.NOTWITHINSASCONTROL;
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
      protocol.denialReason = EU261Protocol.DenialReason.NOTFILEDONTIME;
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'not filed on time'
      );
    } else if (
      this.hasCancellation && this.tripWithClaimFlight.customerCancelled()
    ) {
      protocol.denialReason = EU261Protocol.DenialReason.CUSTOMERCANCELLED;
      this.calculateCompensationForCancellation(); // For protocol reasons
      return new Decision(
        Claim.EU261HandlingStatus.IneligibleForCompensation,
        'customer cancelled the flight'
      );
    } else if (this.hasCancellation) {
      // If the claim flight was cancelled the customer should receive compensation according to the cancellation logic
      Decision compensationDecision = this.calculateCompensationForCancellation(); // For protocol reasons
      if (
        compensationDecision.verdict ==
        Claim.EU261HandlingStatus.IneligibleForCompensation
      ) {
        protocol.denialReason = EU261Protocol.DenialReason.NOTOUTSIDETIMEFRAME;
      }
      return compensationDecision;
    } else if (!this.hasDelay()) {
      protocol.denialReason = EU261Protocol.DenialReason.NODELAYORCANCELLATION;
      return new Decision(
        Claim.EU261HandlingStatus.UnableToHandle,
        'flight not cancelled and not delayed'
      ); // TODO: change to deny
    } else {
      Decision compensationDecision = this.calculateCompensationForDelay();
      if (
        compensationDecision.verdict ==
        Claim.EU261HandlingStatus.IneligibleForCompensation
      ) {
        protocol.denialReason = EU261Protocol.DenialReason.DELAYTOOSMALL;
      }
      return compensationDecision;
    }
  }

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261 regarding cancellations.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   * Returns the result as either a decision of Ineligible with explanations,
   * or Eligible with compensation amounts set.
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
    Boolean isIntraCommunity = originalTrip.isIntraCommunity(); // TODO: GB -> CH can be handled as EU
    Integer daysUntilFlightWhenInformedOfCancellation = this.getDaysBetweenCancellationAndDeparture();

    Trip newTrip = this.tripWithClaimFlightReplacement;
    Integer arrivalDifference;
    Integer departureDifference;
    Money compensation;
    Integer minutesLateOnArrival;
    Integer minutesEarlyOnDeparture;
    if (newTrip == null) {
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
      Flight finalFlight = newTrip.getFlightToFinalDestination();
      Datetime newArrival = finalFlight.actualArrivalTime;
      if (newArrival == null) {
        newArrival = finalFlight.scheduledArrivalTime;
      }

      // Compare the original rebooking against the suggested rebooking and calculate compensation
      departureDifference = Integer.valueOf(
        DateUtils.getHoursBetween(newDeparture, originalDeparture) * 60
      );
      arrivalDifference = Integer.valueOf(
        DateUtils.getHoursBetween(newArrival, originalArrival) * 60
      );

      if (newArrival > originalArrival) {
        minutesLateOnArrival = arrivalDifference;
      } else {
        minutesLateOnArrival = 0;
      }
      if (newDeparture < originalDeparture) {
        minutesEarlyOnDeparture = departureDifference;
      } else {
        minutesEarlyOnDeparture = 0;
      }

      compensation = calculateCompensationCancellation(
        minutesLateOnArrival,
        minutesEarlyOnDeparture,
        flightDistanceInKmRounded,
        daysUntilFlightWhenInformedOfCancellation,
        isIntraCommunity
      );
    }

    this.netDelayInMinutes = minutesLateOnArrival;

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
      new Money(0, Money.CurrencyCode.SEK)
    );
  }

  /**
   * Checks if the delay caused the trip to be altered in any major way.
   * E.g. if the customer had to catch another plane.
   * If not, the delay is simple.
   * @throws InsufficientDataException If there is no info about the boarding status
   * @return If we currently consider the delay automatically handleable.
   */
  private Boolean isSimpleDelay() {
    Datetime beforeTime = tripWithClaimFlight.getScheduledDeparture();
    Datetime afterTime = tripWithClaimFlight.getFinalDestinationArrivalTime();
    List<Trip> tripsBeforeDelay = claimedBooking.getTripsAtTime(beforeTime); // Trips at time of scheduled departure
    List<Trip> tripsAfterDelay = claimedBooking.getTripsAtTime(afterTime); // Trips at time of actual arrival

    if (tripsAfterDelay == null || tripsBeforeDelay == null) {
      return false;
    } else if (tripsBeforeDelay.size() != tripsAfterDelay.size()) {
      return false;
    }

    for (Integer i = 0; i < tripsBeforeDelay.size(); i++) {
      Trip tripBefore = tripsBeforeDelay[i];
      Trip tripAfter = tripsAfterDelay[i];

      if (tripBefore != tripAfter) {
        return false;
      }

      if (!tripAfter.allFlightsAreBoarded()) {
        return false; // If the customers did not board all flights something is going on
      }
    }

    return true;
  }

  private List<ClaimCustomer> getPassengersEligibleForCompensation() {
    List<Passenger> passengers = this.claimedBooking.passengers;

    List<ClaimCustomer> customers = this.claimObj.customers;

    List<ClaimCustomer> eligibleCustomers = new List<ClaimCustomer>();

    // If an infant has a paid ticket they should receive compensation, otherwise not.
    // We currently do not have payment data. But we know domestic flights in Sweden and Norway
    // are free for infants, therefore we can deny these passengers.
    for (Passenger passenger : passengers) {
      for (ClaimCustomer cc : customers) {
        Boolean isInfant = passenger.identifier.toLowerCase().contains('inf');

        if (!isInfant || !tripWithClaimFlight.isIntraSEorIntraNO()) {
          eligibleCustomers.add(cc);
        }
      }
    }

    return eligibleCustomers;
  }

  private Money calculateReimbursement() {
    // Check if arrived 2h late or not
    if (this.claimObj.submittedClaimExpenses.amount == 0) {
      return new Money(0, Money.currencyCode.SEK);
    }
    Boolean flightCancelledWellInTime =
      this.claimObj.type == Claim.Type.FlightCancellation &&
      flightCancelledWellInTime();
    if (flightCancelledWellInTime) {
      return new Money(0, Money.currencyCode.SEK);
    }

    Boolean customerCancelled =
      this.claimObj.type == Claim.Type.FlightCancellation &&
      this.tripWithClaimFlight.customerCancelled();
    if (customerCancelled) {
      return new Money(0, Money.currencyCode.SEK);
    }

    Integer netDelay;
    if (this.claimObj.type == Claim.Type.FlightCancellation) {
      netDelay = this.netDelayInMinutes;
    } else {
      netDelay = this.tripWithClaimFlight.getFlightToFinalDestination()
        .arrivalDelayedMinutes.intValue();
    }
    Money reimbursement;
    if (netDelay > 120) {
      reimbursement = this.claimObj.submittedClaimExpenses.setScale(0);
    } else {
      reimbursement = new Money(0, Money.currencyCode.SEK);
    }
    return reimbursement;
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
   * @return an Integer of the amount of minutes delayed for the ac.tripWithClaimFlight with the delay minutes outside SAS control deducted.
   * TODO: improve
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
      this.protocol.delayExplanation =
        'The flight was delayed ' +
        netDelayedMinutes +
        ' minutes on arrival of which ' +
        delayCausedByIrregularitiesWithinSASControl +
        ' minutes were within SAS control. ' +
        FlightIrregularity.getOutsideSASControlExplanationDelay(
          f.irregularities
        );
    } else {
      this.protocol.delayExplanation =
        'The flight was delayed ' +
        netDelayedMinutes +
        ' minutes on arrival.';
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
   * Checks whether the claim is covered by EU261 jurisdiction.
   * EU261 is only applicable for flights leaving and/or arriving to an airport in the European Union, Iceland, Norway or Switzerland.
   * Also, if the customer has already received benefits related to a law of a non-EU country they are not eligable for compensation.
   * Source: https://europa.eu/youreurope/citizens/travel/passenger-rights/air/index_en.htm
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
   * Calculates the actual amount of compensation in EUR the customer(s) is/are
   * entitled according to EU261 for _delays_.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   * TODO: go through this, something is off. Article 6 never refers to article 7, however, it details this in: https://europa.eu/youreurope/citizens/travel/passenger-rights/air/index_en.htm#compensation-delay-1
   * TODO: Check "Present themselves for check-in 45 minutes before the published departure time"
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

    protocol.delayWithinSASControl = delayedMinutes;
    if (delayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
      if (
        delayedMinutes <
        Integer.valueOf(
          this.tripWithClaimFlight.getFlightToFinalDestination()
            .arrivalDelayedMinutes
        )
      ) {
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'SAS is not responsible for 3 hours or more of the delay'
        );
      } else {
        return new Decision(
          Claim.EU261HandlingStatus.IneligibleForCompensation,
          'delayed less than 180 minutes'
        );
      }
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
    } else {
      compensationAmount = new Money(600, Money.CurrencyCode.EUR);
    }
    Map<ClaimCustomer, Money> compensationByCustomer = new Map<ClaimCustomer, Money>();

    for (ClaimCustomer p : passengersEligibleForCompensation) {
      compensationByCustomer.put(p, compensationAmount);
    }

    return new Decision(
      '',
      compensationByCustomer,
      new Money(0, Money.CurrencyCode.SEK)
    );
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

    protocol.minutesEarlyOnDeparture = minutesEarlyOnDeparture;
    protocol.minutesLateOnArrival = minutesLateOnArrival;
    protocol.flightDistanceInKm = flightDistanceInKm;
    protocol.isOutsideTimeFrame = isEligableForCompensation;
    protocol.daysUntilFlightWhenInformedOfCancellation = daysUntilFlightWhenInformedOfCancellation;

    if (!isEligableForCompensation) {
      return new Money(0, Money.CurrencyCode.EUR);
    }

    Money compensation;
    Boolean halveCompensation;
    Boolean isShortDistance = flightDistanceInKm <= MEDIUM_DISTANCE;
    Boolean isMediumDistanceOrIntraCommunity =
      flightDistanceInKm > MEDIUM_DISTANCE &&
      (flightDistanceInKm <= LONG_DISTANCE || isIntraCommunity);
    if (isShortDistance) {
      compensation = new Money(250, Money.CurrencyCode.EUR);
      halveCompensation =
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
        protocol.maxDelayForHalved = MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_SHORT_DISTANCE;
      }
    } else if (isMediumDistanceOrIntraCommunity) {
      compensation = new Money(400, Money.CurrencyCode.EUR);
      halveCompensation =
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
        protocol.maxDelayForHalved = MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_MEDIUM_DISTANCE;
      }
    } else {
      compensation = new Money(600, Money.CurrencyCode.EUR);
      halveCompensation =
        minutesLateOnArrival <=
        MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE;

      if (halveCompensation) {
        compensation = compensation.divideBy(2);
        protocol.maxDelayForHalved = MAXIMUM_DELAY_FOR_HALVED_COMPENSATION_LONG_DISTANCE;
      }
    }

    protocol.compensationIsHalved = halveCompensation;

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
    final List<Decimal> DELAY_TRESHOLDS = new List<Decimal>{
      120.0,
      180.0,
      240.0,
      300.0
    };
    for (Decimal threshold : DELAY_TRESHOLDS) {
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
