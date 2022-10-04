/**
 * @param claim a LIA_Claim__c to be automated
 * @param booking a BookingJSON associated with the claim
 *
 * Service class which handles case/claim automation
 * Contains all information needed (not currently) to automate a claim.
 * Investigate: Can people in the same booking have different amount of flights?
 *
 * WARNING: The automation is currently built with the assumption that there is exactly one flight per claim.
 * This can relatively easily be changed, but keep it in mind before allowing more than one flight in a claim.
 */
public without sharing class EU261Service {
  public static EU261Service newInstance() {
    return (EU261Service) SAS_Service_Application.Service.newInstance(
      EU261Service.class
    );
  }

  private static Set<String> invalidFareBases = new Set<String>{};

  @TestVisible
  private class ClaimWithCompensationDetails {
    public Bookings.Type bookingType;
    public Claims claim; // must be a single claim
    public Bookings booking;
    public Integer EU261Compensation;
    public Decimal careReimbursement;
    private Map<Id, List<Trip>> trips;
    private Map<Id, List<FlightIrregularities__c>> flightToIrregularities;
    private Trip tripWithClaimFlight;
    public String unhandledReason;
    public Boolean canBeEvaluated;
    public String rejectionReason;
    public String outsideSASControlExplanation;
    public Boolean customerEntitledToCompensation = false;
    public Decimal maximumTimeToClaimCompensation;
    public Boolean hasPotentiallyDuplicateClaims = false;
    public Boolean hasRelatedFiles = false;
    public Flight__c claimFlight;

    public ClaimWithCompensationDetails(Claim c) {
      this.claim = Claims.newInstance(
        (new List<LIA_Claim__c>{ c.underlyingSObject })
      );
    }

    public Boolean hasTripWithClaimFlight() {
      if (tripWithClaimFlight != null) {
        return true;
      }
      return false;
    }

    public Boolean hasDelay() {
      if (claimFlight == null) {
        throw new AutomationException('tripWithClaimFlight not set');
      }
      return this.tripWithClaimFlight.isDelayedToDestination();
    }

    public Boolean hasCancellation() {
      if (claimFlight == null) {
        throw new AutomationException('claimFlight not set');
      }

      FlightIrregularities claimIrregularities = new FlightIrregularities(
        flightToIrregularities.get(claimFlight.Id)
      );
      claimIrregularities.removeNA0Delay();

      return claimIrregularities.containsCancellation();
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
  public List<EU261Service.ClaimWithCompensationDetails> automateEU261Claims(
    Set<Id> claimIds,
    fflib_ISObjectUnitOfWork uow
  ) {
    /**
     * Let's add a picklist field to the case to capture what the automation thought about the case.
     * I.e. was it unsolvable, missing info or what.
     */

    // 1. get all information necessary for evaluating the right to and the amount of compensation
    List<ClaimWithCompensationDetails> claimsToAutomate = gatherAllNecessaryInformation(
      claimIds
    );

    // 2. figure out whether we can evaluate this claim
    claimsToAutomate = canWeEvaluate(claimsToAutomate);

    List<ClaimWithCompensationDetails> canBeEvaluated = new List<ClaimWithCompensationDetails>();
    for (ClaimWithCompensationDetails c : claimsToAutomate) {
      if (c.canBeEvaluated) {
        canBeEvaluated.add(c);
      }
    }

    // 3. Determinte eligibility for compensation and calculate amount if relevant
    determineEligibilityAndCalculateCompensation(canBeEvaluated);
    calculateReimbursement(canBeEvaluated); // Todo, implement

    // 4. Settle or reject all claims.
    List<ClaimWithCompensationDetails> claimsToPayOut = new List<ClaimWithCompensationDetails>();
    List<ClaimWithCompensationDetails> claimsToReject = new List<ClaimWithCompensationDetails>();
    List<ClaimWithCompensationDetails> claimsWhichCannotBeEvaluated = new List<ClaimWithCompensationDetails>();

    for (ClaimWithCompensationDetails c : claimsToAutomate) {
      if (!c.canBeEvaluated) {
        claimsWhichCannotBeEvaluated.add(c);
      } else if (c.customerEntitledToCompensation) {
        claimsToPayOut.add(c);
        // TODO: Add reimbursement ones here.
      } else {
        claimsToReject.add(c);
      }
    }

    storeClaimResolution(
      claimsWhichCannotBeEvaluated,
      claimsToReject,
      claimsToPayOut,
      uow
    );

    // settleClaims(claimsToPayOut, uow);

    debugResult(claimsToAutomate);

    return claimsToAutomate;

    // TODO: Log out some details about how many were handled.
  }

  public void processEU261Claims(Set<Id> claimIds) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    this.automateEU261Claims(claimIds, uow);
    uow.commitWork();
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
  private static List<ClaimWithCompensationDetails> canWeEvaluate(
    List<ClaimWithCompensationDetails> claimsToAutomate
  ) {
    for (ClaimWithCompensationDetails ac : claimsToAutomate) {
      Claim c = ac.claim.objects[0];
      if (c.category != Claim.Category.FlightDisruptions) {
        ac.unhandledReason = 'can handle only claims in category "Flight disruptions"';
        ac.canBeEvaluated = false;
      } else if (c.type != Claim.Type.FlightDelay) {
        ac.unhandledReason = 'can handle only claims in type "Flight delay"';
        ac.canBeEvaluated = false;
      } else if (c.recordType != Claim.RecordType.CustomerClaim) {
        ac.unhandledReason = 'can handle only claims with record type CustomerClaim';
        ac.canBeEvaluated = false;
      } else if (
        false // TODO: Fix this //ac.claim.instanceRecords[0].Case__r.Status != Cases.STATUS_NEW && String.valueOf(c.OwnerId).substring(0, 3) == '00G'
      ) {
        ac.unhandledReason = 'can handle only claims with case in status "New"';
        ac.canBeEvaluated = false;
      } else if (ac.booking.instanceRecords.size() == 0) {
        ac.unhandledReason = 'the claim is not associated with a booking';
        ac.canBeEvaluated = false;
      } else if (ac.booking.instanceRecords.size() > 1) {
        // TODO: Think about how to handle repeat PNRs.
        // TODO: Think about the potential fraud cases.
        ac.unhandledReason = 'can handle only one booking per claim';
        ac.canBeEvaluated = false;
        // TODO: Ensure that we have only a specific number of trips.
      } else if (ac.hasPotentiallyDuplicateClaims) {
        ac.unhandledReason = 'cannot handle potential duplicates';
        ac.canBeEvaluated = false;
      } else if (ac.bookingType != Bookings.Type.OneWay) {
        ac.unhandledReason = 'can handle only one one way trips';
        ac.canBeEvaluated = false;
      } else if (ac.booking.instanceRecords[0].Segments__r.size() == 0) {
        ac.unhandledReason = 'no flight associated with the claim';
        ac.canBeEvaluated = false;
      } else if (c.customers == null || c.customers.isEmpty()) {
        ac.unhandledReason = 'cannot handle claims without any travellers';
        ac.canBeEvaluated = false;
      } else if (
        ac.booking.instanceRecords[0].Segments__r.size() >
        2 * ac.booking.instanceRecords[0].Passengers__r.size()
      ) {
        ac.unhandledReason = 'can handle only one or two flights per claim'; // Each passenger should have a single segment per flight
        ac.canBeEvaluated = false;
      } else if (
        invalidFareBases.contains(
          ac.booking.instanceRecords[0].Segments__r[0].Fare_Basis__c
        )
      ) {
        // TODO: Move this to be evaluation instead.
        ac.unhandledReason = 'cannot handle claims with a restricted fare basis.';
        ac.canBeEvaluated = false;
      } else if (ac.hasRelatedFiles) {
        ac.unhandledReason = 'cannot handle claims with attachments (might have POA)';
        ac.canBeEvaluated = false;
      } else if (!ac.hasTripWithClaimFlight()) {
        ac.unhandledReason = 'cannot find claimed flight from booking';
        ac.canBeEvaluated = false;
      } else if (
        !ac.tripWithClaimFlight.originAirport.Is_EU261_Applicable__c ||
        !ac.tripWithClaimFlight.destinationAirport.Is_EU261_Applicable__c
      ) {
        ac.unhandledReason = 'can only handle claims with origin and destination airports in EU';
        ac.canBeEvaluated = false;
      } else if (c.submittedClaimExpenses > 0) {
        ac.unhandledReason = 'cannot handle claim expenses';
        ac.canBeEvaluated = false;
      } else if (hasRotationIrregularities(ac)) {
        ac.unhandledReason = 'cannot handle flights with irregularities caused by rotations';
        ac.canBeEvaluated = false;
      } else if (!ac.tripWithClaimFlight.SASIsOnlyOperatingCarrier) {
        ac.unhandledReason = 'cannot handle claims where SAS is not the only operating carrier';
        ac.canBeEvaluated = false;
      } else if (requiresPowerOfAttorney(ac)) {
        ac.unhandledReason = 'can handle only claims which do not require power of attorney';
        ac.canBeEvaluated = false;
      } else if (
        ac.hasCancellation() &&
        !canDetermineIfSASIsResponsibleForCancellation(ac)
      ) {
        ac.unhandledReason = 'cannot determine wether SAS is responsible or not.';
        ac.canBeEvaluated = false;
      } else if (
        ac.hasCancellation() &&
        (!ac.tripWithClaimFlight.canGetOriginalTrip() ||
        !ac.tripWithClaimFlight.canGetSuggestedRebookingTrip())
      ) {
        ac.unhandledReason = 'this trip type is not yet supported.';
        ac.canBeEvaluated = false;
      } else if (!ac.hasCancellation() && !canCalculateDelay(ac)) {
        ac.unhandledReason = 'there were issues calculating the delay'; // Can we code better logging?
        ac.canBeEvaluated = false;
      } else if (
        (!ac.hasCancellation() &&
        (getMinutesDelayedWithinSASControl(ac) <= (2 * 60) ||
        getMinutesDelayedWithinSASControl(ac) >= (5 * 60)))
      ) {
        ac.unhandledReason = 'can handle only delays between 2 and 5 hours';
        ac.canBeEvaluated = false;
      } else {
        ac.canBeEvaluated = true;
      }
      // TODO: ~Check proactivities Maybe something like if there's any proactivity for this claim, dont do anything. We could also move this to be later.
    }

    return claimsToAutomate;
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
  private static Boolean requiresPowerOfAttorney(
    ClaimWithCompensationDetails ac
  ) {
    Claim c = ac.claim.objects[0];

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
      for (Passenger__c p : ac.booking.instanceRecords[0].Passengers__r) {
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

  private static boolean canCalculateDelay(ClaimWithCompensationDetails ac) {
    try {
      getMinutesDelayedWithinSASControl(ac);
    } catch (Exception e) {
      return false;
    }
    return true;
  }

  private static void calculateReimbursement(
    List<ClaimWithCompensationDetails> handledClaims
  ) {
    for (ClaimWithCompensationDetails ac : handledClaims) {
      ac.careReimbursement = 0;
    }
  }

  private static Boolean isStaffBooking(ClaimWithCompensationDetails ac) {
    // TODO: Implement this. We are not currently storing the data but when we
    // are, this is just something like return ac.booking.IsIdTicket__c;
    return false;
  }

  private static void determineEligibilityAndCalculateCompensation(
    List<ClaimWithCompensationDetails> claimsWhichCanBeEvaluated
  ) {
    for (ClaimWithCompensationDetails ac : claimsWhichCanBeEvaluated) {
      if (isStaffBooking(ac)) {
        ac.rejectionReason = 'id and staff tickets are not eligible';
        ac.customerEntitledToCompensation = false;
      } else if (!isCoveredByEU261(ac)) {
        // Was the flight from/to the right place + insanely complex edge case
        ac.rejectionReason = 'not covered by EU261';
        ac.customerEntitledToCompensation = false;
      } else if (!isFiledOnTime(ac)) {
        ac.rejectionReason = 'not filed on time';
        ac.customerEntitledToCompensation = false;
      } else if (ac.hasCancellation()) {
        // If the claim flight was cancelled the customer should receive compensation according to the cancellation logic
        if (!cancellationCodeIsWithinSASControl(ac)) {
          ac.rejectionReason = 'cancellation code not within SAS control';
          ac.customerEntitledToCompensation = false;
        } else {
          ac = setEU261CompensationCancellation(ac);
        }
      } else if (!ac.hasDelay()) {
        ac.rejectionReason = 'flight not cancelled and not delayed';
        ac.customerEntitledToCompensation = false;
      } else {
        Boolean canBeCompensated = true; // Nathan: What is this for? Seems like something canWeEvaluate() handles?
        if (canBeCompensated) {
          ac = setEU261CompensationDelay(ac); // Also sets wether they are entitled
        } else {
          ac.rejectionReason = 'unknown';
          ac.customerEntitledToCompensation = false;
        }
      }
    }
  }

  /**
   * Settle the claims which can be. For the time being just adds description of
   * what was processed.
   */
  private static void settleClaims(
    List<ClaimWithCompensationDetails> claimsToPayout,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (ClaimWithCompensationDetails claim : claimsToPayout) {
      // claim.claim.instanceRecords[0].
      Settlements s = Settlements.createFromClaim(
        claim.claim.instanceRecords,
        null,
        uow
      );

      List<Settlement_Item__c> itemsToUpsert = new List<Settlement_Item__c>{
        new Settlement_Item__c(
          Amount__c = claim.EU261Compensation, // TODO: Calculate conversation rates correctly.
          Comments__c = 'Automatically created item for EU261 compensation.', // TODO: comments here properly.
          Cost_Account__c = '6727', // TODO: Is this the correct one?
          Currency__c = claim.claim.instanceRecords[0].Currency__c
        )
      };

      //s.updateSettlementItems(itemsToUpsert, uow); //TODO: This doesn't work if the settlement doesn't exist yet.
      // claim.claim.settle(uow);
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
  private static Boolean isFiledOnTime(ClaimWithCompensationDetails ac) {
    Claim c = ac.claim.objects[0];
    Datetime tripDate = ac.tripWithClaimFlight.getFinalDestinationArrivalTime();

    Integer limitInDepartureCountry = countryToClaimTimeLimitInMonths.get(
      ac.tripWithClaimFlight.originAirport.Country_Code__c
    );
    Integer limitInArrivalCountry = countryToClaimTimeLimitInMonths.get(
      ac.tripWithClaimFlight.destinationAirport.Country_Code__c
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

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261 regarding cancellations.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   * @return the ClaimWithCompensationDetails object with the correct compensation in EUR and/or rejection reason.
   *
   * TODO: Construct explanation for logging
   * TODO: Double check logic
   */
  private static ClaimWithCompensationDetails setEU261CompensationCancellation(
    ClaimWithCompensationDetails ac
  ) {
    // Get the original flight plan
    Trip originalTrip = ac.tripWithClaimFlight.getOriginalTripWithFlight();
    Datetime originalDeparture = originalTrip.getFirstFlight()
      .Scheduled_Departure_Time__c;
    Datetime originalArrival = originalTrip.getFlightToFinalDestination()
      .Scheduled_Arrival_Time__c;

    Decimal flightDistanceInKm =
      Airports.distanceBetweenAirportsInMeters(
        ac.tripWithClaimFlight.originAirport,
        ac.tripWithClaimFlight.destinationAirport
      ) / 1000;
    Integer flightDistanceInKmRounded = flightDistanceInKm.intValue();
    Boolean isIntraCommunity = originalTrip.isIntraCommunity();
    List<FlightIrregularities__c> flightIrregularities = ac.flightToIrregularities.get(
      ac.claimFlight.Id
    );
    Integer daysUntilFlightWhenInformedOfCancellation = getDaysBetweenCancellationAndDeparture(
      ac
    );

    // Get the new (suggested) flight plan
    Trip newTrip = ac.tripWithClaimFlight.getSuggestedRebookingWithoutFlight();
    Integer arrivalDifference;
    Integer departureDifference;
    Integer compensation;
    if (newTrip == null) {
      // Current state of this automation as we cannot determine that we have not suggested a rebooking
      Boolean allDataIsAvailable = false; // Temp (dev), EDW
      if (!allDataIsAvailable) {
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

    Integer numberOfEligiblePassengers = getNumberOfPassengersEligibleForCompensation(
      ac
    );

    Integer totalCompensation = compensation * numberOfEligiblePassengers;

    if (totalCompensation > 0) {
      ac.customerEntitledToCompensation = true;
      ac.EU261Compensation = totalCompensation;
    } else {
      ac.customerEntitledToCompensation = false;
    }

    return ac;
  }

  private static Integer calculateCompensationCancellation(
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

  public static Boolean isOutSideTimeFrame(
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

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261 regarding delays.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   * @return the ClaimWithCompensationDetails object with the correct compensation in EUR and/or rejection reason.
   */
  private static ClaimWithCompensationDetails setEU261CompensationDelay(
    ClaimWithCompensationDetails ac
  ) {
    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;
    final Integer MINIMUM_DELAY_FOR_INCREASED_COMPENSATION = 240;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Decimal flightDistanceInM =
      Airports.distanceBetweenAirportsInMeters(
        ac.tripWithClaimFlight.originAirport,
        ac.tripWithClaimFlight.destinationAirport
      ) / 1000;
    Integer flightDistanceInKm = flightDistanceInM.intValue();
    Integer numberOfEligiblePassengers = getNumberOfPassengersEligibleForCompensation(
      ac
    );
    Integer delayedMinutes = getMinutesDelayedWithinSASControl(ac);

    if (delayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
      ac.customerEntitledToCompensation = false;
      ac.rejectionReason = 'delayed less than 180 minutes';
    } else {
      if (flightDistanceInKm <= MEDIUM_DISTANCE) {
        ac.EU261Compensation = numberOfEligiblePassengers * 250;
      } else if (
        flightDistanceInKm > MEDIUM_DISTANCE &&
        (flightDistanceInKm <= LONG_DISTANCE ||
        ac.tripWithClaimFlight.isIntraCommunity())
      ) {
        ac.EU261Compensation = numberOfEligiblePassengers * 400;
      } else if (delayedMinutes < MINIMUM_DELAY_FOR_INCREASED_COMPENSATION) {
        ac.EU261Compensation = numberOfEligiblePassengers * 300;
      } else if (delayedMinutes >= MINIMUM_DELAY_FOR_INCREASED_COMPENSATION) {
        ac.EU261Compensation = numberOfEligiblePassengers * 600;
      } else {
        throw new AutomationException('Invalid compensation calculation.');
      }

      if (numberOfEligiblePassengers == 0) {
        ac.customerEntitledToCompensation = false;
        ac.rejectionReason = 'no passenger in this claim has a revenue ticket.';
      } else {
        ac.customerEntitledToCompensation = true;
      }
    }
    return ac;
  }

  public class AutomationException extends Exception {
  }

  /**
   * @param ac an AutomationUtils.ClaimWithCompensationDetails containing information about the booking and the claim.
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
  private static Boolean isCoveredByEU261(ClaimWithCompensationDetails ac) {
    // ~TODO(c): Determine if the customer has already received benefits related to a law of a non-EU country
    Boolean hasReceivedBenefitsWhichVoidEU261 = false;

    Airport__c originAirport = ac.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = ac.tripWithClaimFlight.destinationAirport;
    Boolean isToOrFromEU261Territory = (originAirport.Is_EU261_Applicable__c ||
    destinationAirport.Is_EU261_Applicable__c);

    return (isToOrFromEU261Territory && !hasReceivedBenefitsWhichVoidEU261);
  }

  private static Boolean hasRotationIrregularities(
    ClaimWithCompensationDetails ac
  ) {
    Flight__c flight = ac.tripWithClaimFlight.getFlightToFinalDestination();
    List<FlightIrregularities__c> flightIrregularities = ac.flightToIrregularities.get(
      flight.Id
    );
    FlightIrregularities irregularities = new FlightIrregularities(
      flightIrregularities
    );

    return irregularities.containsRotationIrregularities();
  }

  private static Integer getDaysBetweenCancellationAndDeparture(
    ClaimWithCompensationDetails ac
  ) {
    FlightIrregularities claimIrregularities = new FlightIrregularities(
      ac.flightToIrregularities.get(ac.claimFlight.Id)
    );
    claimIrregularities.removeNA0Delay();

    if (!claimIrregularities.containsCancellation()) {
      throw new AutomationException('Claim flight is not cancelled.');
    }

    if (claimIrregularities.instanceRecords.size() == 1) {
      FlightIrregularities__c cancellation = claimIrregularities.instanceRecords[0];
      Datetime departureTime = ac.claimFlight.Scheduled_Departure_Time__c;
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

  /**
   * TODO: Mover to gather all necessary information and batch
   * @return an Integer of the amount of minutes delayed for the ac.tripWithClaimFlight with the delay minutes outside SAS control deducted.
   */
  private static Integer getMinutesDelayedWithinSASControl(
    ClaimWithCompensationDetails ac
  ) {
    Flight__c flight = ac.tripWithClaimFlight.getFlightToFinalDestination();
    FlightIrregularities irregularities = new FlightIrregularities(
      ac.flightToIrregularities.get(flight.Id)
    );

    Integer delayCausedByIrregularitiesWithinSASControl = FlightService.newInstance()
      .getTotalDelayInMinutesWithinSASControl(
        new Flights(new List<Flight__c>{ flight }),
        ac.flightToIrregularities
      )
      .get(flight.Id);
    Integer netDelayedMinutes = Integer.valueOf(
      flight.Arrival_Delayed_Minutes__c
    );

    if (
      delaysOutsideSASControlReducesCompensation(
        ac,
        netDelayedMinutes,
        delayCausedByIrregularitiesWithinSASControl
      )
    ) {
      ac.outsideSASControlExplanation =
        'The flight was delayed ' +
        netDelayedMinutes +
        ' minutes on arrival of which ' +
        delayCausedByIrregularitiesWithinSASControl +
        ' minutes were within SAS control. ' +
        irregularities.getOutsideSASControlExplanation();
    }

    return delayCausedByIrregularitiesWithinSASControl;
  }

  private static Boolean canDetermineIfSASIsResponsibleForCancellation(
    ClaimWithCompensationDetails ac
  ) {
    try {
      cancellationCodeIsWithinSASControl(ac);
      return true;
    } catch (FlightIrregularities.IrregularityException e) {
      return false;
    }
  }

  private static Boolean cancellationCodeIsWithinSASControl(
    ClaimWithCompensationDetails ac
  ) {
    FlightIrregularities claimIrregularities = new FlightIrregularities(
      ac.flightToIrregularities.get(ac.claimFlight.Id)
    );
    claimIrregularities.removeNA0Delay();

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

  private static Integer getNumberOfPassengersEligibleForCompensation(
    ClaimWithCompensationDetails ac
  ) {
    // TODO: Check: Is fare = 0?

    List<Passenger__c> passengers = ac.booking.instanceRecords[0].Passengers__r; // FIXME: This should always be about travelers in claim, not passengers in booking

    List<ClaimCustomer> customers = ac.claim.objects[0].customers;

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
            ac.tripWithClaimFlight.destinationAirport.Country_Code__c == 'DK' &&
            ac.tripWithClaimFlight.originAirport.Country_Code__c == 'DK';
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

  /**
   * @param claims a list of claims for which to find information.
   *
   * @return a list of ClaimWithCompensationDetails containing all information necessary to automate the claim.
   */
  private static List<ClaimWithCompensationDetails> gatherAllNecessaryInformation(
    Set<Id> claimIds
  ) {
    // 1. Get claims
    ClaimsSelector claimsSel = ClaimsSelector.newInstance();
    List<Claim> claims = new List<Claim>();

    for (LIA_Claim__c c : claimsSel.selectByIdWithCustomers(claimIds)) {
      claims.add(new Claim(c));
    }

    // 2. Extract information needed for selection
    Set<String> allCountriesInClaims = new Set<String>{};
    Set<Id> allCaseIdsInClaims = new Set<Id>();
    Set<String> allPnrsInClaims = new Set<String>();
    for (Claim c : claims) {
      allCountriesInClaims.add(c.contactCountry);
      allCaseIdsInClaims.add(c.parentCaseId);
      allPnrsInClaims.add(c.bookingReference);
    }

    // 3. Get "duplicate" claims
    List<Claim> otherClaimsWithMatchingPnrs = new List<Claim>();
    for (LIA_Claim__c c : claimsSel.selectByBookingReference(allPnrsInClaims)) {
      otherClaimsWithMatchingPnrs.add(new Claim(c));
    }

    // 4. Get any files connected to the claims, TODO: use the contentversion selector Nathan: I can't get this to work, could you have a look? @Mikko
    List<ContentDocumentLink> filesForClaims = new List<ContentDocumentLink>{};

    // 6. Map cases to bookings and get bookings
    List<CaseToBooking__c> ctbs = CaseToBookingsSelector.newInstance()
      .selectByCaseId(allCaseIdsInClaims);
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings = new Map<Id, List<CaseToBooking__c>>();
    Set<Id> allBookingIds = new Set<Id>();
    for (CaseToBooking__c c : ctbs) {
      if (caseIdToCaseToBookings.get(c.Case__c) == null) {
        caseIdToCaseToBookings.put(c.Case__c, new List<CaseToBooking__c>{ c });
      } else {
        caseIdToCaseToBookings.get(c.Case__c).add(c);
      }

      allBookingIds.add(c.Booking__c);
    }

    List<Booking__c> allBookingsFoundInClaims = BookingsSelector.newInstance()
      .selectByIdFull(allBookingIds);

    Map<Id, Booking__c> bookingsById = new Map<Id, Booking__c>(
      allBookingsFoundInClaims
    );

    Set<String> allTEDSFlightIds = new Set<String>{};
    Set<String> allAirportCodes = new Set<String>{};
    for (Booking__c b : allBookingsFoundInClaims) {
      for (Segment__c s : b.Segments__r) {
        allTEDSFlightIds.add(s.Flight__r.TEDS_Identifier__c);
        allAirportCodes.add(s.Flight__r.Departure_Airport__c);
        allAirportCodes.add(s.Flight__r.Arrival_Airport__c);
      }
    }

    List<Airport__c> allAirports = AirportsSelector.newInstance()
      .selectByIATACode(allAirportCodes);
    Map<String, Airport__c> airportCodeToAirport = new Map<String, Airport__c>{};
    for (Airport__c a : allAirports) {
      airportCodeToAirport.put(a.TEDS_Identifier__c, a);
    }

    // 5. Get time limits for how long a pax can wait before filing a claim. Todo: Reimplement, do after airports are fetched in constructClaimWithCompensationDetails
    Map<String, Decimal> countryToClaimSubmissionTimeLimit = new Map<String, Decimal>{};
    // CountryUtils.getAmountOfYearsYouCanWaitToFileAClaim(
    //   allCountriesInClaims
    // );

    // 7. Get flight irregularities:
    List<FlightIrregularities__c> flightIrregularities = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(allTEDSFlightIds);

    // 8. Construct and return the ClaimWithCompensationDetails
    return constructClaimWithCompensationDetails(
      claims,
      countryToClaimSubmissionTimeLimit,
      otherClaimsWithMatchingPnrs,
      filesForClaims,
      caseIdToCaseToBookings,
      bookingsById,
      flightIrregularities,
      airportCodeToAirport
    );
  }

  private static List<ClaimWithCompensationDetails> constructClaimWithCompensationDetails(
    List<Claim> claims,
    Map<String, Decimal> countryToClaimSubmissionTimeLimit,
    List<Claim> otherClaimsWithMatchingPnrs,
    List<ContentDocumentLink> filesForClaims,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById,
    List<FlightIrregularities__c> flightIrregularities,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    List<ClaimWithCompensationDetails> claimsToAutomate = new List<ClaimWithCompensationDetails>{};
    for (Claim c : claims) {
      ClaimWithCompensationDetails cwcd = new ClaimWithCompensationDetails(c);

      // TODO: refactor handle with airportCodeToAirport
      cwcd.maximumTimeToClaimCompensation = 3;
      // countryToClaimSubmissionTimeLimit.get(
      //   c.Country__c
      // );

      // check if the claim matches any other claim by PNR
      for (Claim otherClaim : otherClaimsWithMatchingPnrs) {
        if (
          c.bookingReference == otherClaim.bookingReference &&
          c.id != otherClaim.id
        ) {
          cwcd.hasPotentiallyDuplicateClaims = true;
        }
      }

      // check if there are any files linked to the parent case, problematic due to PoAs
      for (ContentDocumentLink cdl : filesForClaims) {
        if (cdl.LinkedEntityId == c.parentCaseId) {
          cwcd.hasRelatedFiles = true;
        }
      }

      setBookings(c, cwcd, caseIdToCaseToBookings, bookingsById);
      setTrips(c, cwcd, airportCodeToAirport);

      claimsToAutomate.add(cwcd);
    }

    setFlightIrregularities(flightIrregularities, claimsToAutomate);
    // setMaximumWaitTime(claimsToAutomate, airportCodeToAirport); // TODO: implement, do after cwcds have segments

    return claimsToAutomate;
  }

  private static void setBookings(
    Claim c,
    ClaimWithCompensationDetails cwcd,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById
  ) {
    // Get bookings for claim
    List<Booking__c> bookingsForClaim = new List<Booking__c>();
    for (CaseToBooking__c ctb : caseIdToCaseToBookings.get(c.parentCaseId)) {
      // TODO: Fix this can be null.
      Booking__c booking = bookingsById.get(ctb.Booking__c);
      if (booking != null) {
        bookingsForClaim.add(booking);
      }
    }

    cwcd.booking = Bookings.newInstance(bookingsForClaim);
    if (cwcd.booking.instanceRecords.size() > 0) {
      cwcd.bookingType = Bookings.nameToBookingType.get(
        cwcd.booking.instanceRecords[0].Type__c
      );
    }
  }

  // TODO: use airportCodeToAirport to eliminate db calls in for-loop
  private static void setTrips(
    Claim c,
    ClaimWithCompensationDetails cwcd,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    try {
      cwcd.trips = cwcd.booking.getTrips(airportCodeToAirport);
    } catch (Trip.BookingTypeNotSupportedException e) {
      return;
    }

    // Todo: use stringutils / the flight domain (implement)
    String flightNumberDate = Flights.constructTEDSFlightNumberDate(
      c.flightNumber,
      c.departureDate
    );

    if (cwcd.booking.instanceRecords.size() > 0) {
      for (Trip t : cwcd.trips.get(cwcd.booking.instanceRecords[0].Id)) {
        Flight__c claimFlight = t.getFlight(flightNumberDate);
        if (claimFlight != null) {
          cwcd.tripWithClaimFlight = t;
          cwcd.claimFlight = claimFlight;
          break;
        }
      }
    }
  }

  private static void setFlightIrregularities(
    List<FlightIrregularities__c> claimFlightIrregularities,
    List<ClaimWithCompensationDetails> claimsToAutomate
  ) {
    FlightIrregularities irregularities = new FlightIrregularities(
      claimFlightIrregularities
    );
    irregularities.removeNA0Delay(); // Remove irrelevant irregularities
    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities = irregularities.getFlightIdToIrregularities();

    for (ClaimWithCompensationDetails c : claimsToAutomate) {
      Map<Id, List<FlightIrregularities__c>> claimSpecificIrregularities = new Map<Id, List<FlightIrregularities__c>>{};
      if (c.booking.instanceRecords.size() > 0) {
        for (Segment__c s : c.booking.instanceRecords[0].Segments__r) {
          List<FlightIrregularities__c> flightIrreg = flightIdToIrregularities.get(
            s.Flight__c
          );
          if (flightIrreg == null) {
            flightIrreg = new List<FlightIrregularities__c>{};
          }
          claimSpecificIrregularities.put(s.Flight__c, flightIrreg);
        }
      }
      c.flightToIrregularities = claimSpecificIrregularities;
    }
  }

  private static Boolean delaysOutsideSASControlReducesCompensation(
    ClaimWithCompensationDetails ac,
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

  private static void storeClaimResolution(
    List<ClaimWithCompensationDetails> claimsWhichCannotBeEvaluated,
    List<ClaimWithCompensationDetails> claimsToReject,
    List<ClaimWithCompensationDetails> claimsToPayOut,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (ClaimWithCompensationDetails cc : claimsWhichCannotBeEvaluated) {
      Claim c = cc.claim.objects[0];
      c.eu261HandlingNote = cc.unhandledReason;
      c.eu261HandlingStatus = Claim.EU261HandlingStatus.UnableToHandle;
      cc.claim.upsertToDB(uow);
    }

    for (ClaimWithCompensationDetails cc : claimsToReject) {
      Claim c = cc.claim.objects[0];
      c.eu261HandlingNote = cc.rejectionReason;
      c.eu261HandlingStatus = Claim.EU261HandlingStatus.IneligibleForCompensation;
      cc.claim.upsertToDB(uow);
    }

    for (ClaimWithCompensationDetails cc : claimsToPayOut) {
      Claim c = cc.claim.objects[0];
      c.eu261HandlingNote =
        'Compensation: ' +
        cc.EU261Compensation +
        ' | Reimbursement: ' +
        cc.careReimbursement;
      c.eu261HandlingStatus = Claim.EU261HandlingStatus.EligibleForCompensation;
      cc.claim.upsertToDB(uow);
    }
  }

  private static void debugResult(
    List<ClaimWithCompensationDetails> automatedClaims
  ) {
    Integer claimNo = 1;
    for (ClaimWithCompensationDetails c : automatedClaims) {
      System.debug(
        '----------------- Claim no.' +
        claimNo +
        ' START -----------------'
      );
      System.debug('Booking type: ' + c.bookingType);
      System.debug(
        'Status: ' + c.claim.instanceRecords[0].EU261_Handling_Status__c
      );
      System.debug(
        'Note: ' + c.claim.instanceRecords[0].EU261_Handling_Note__c
      );

      System.debug(
        'More: ' +
        'outsideSASControlExplanation: ' +
        c.outsideSASControlExplanation +
        '. maximumTimeToClaimCompensation: ' +
        c.maximumTimeToClaimCompensation +
        '. hasPotentiallyDuplicateClaims: ' +
        c.hasPotentiallyDuplicateClaims +
        '. hasRelatedFiles: ' +
        c.hasRelatedFiles +
        '. rejectionReason: ' +
        c.rejectionReason +
        '. canBeEvaluated: ' +
        c.canBeEvaluated +
        '. unhandledReason: ' +
        c.unhandledReason
      );
      System.debug(
        '----------------- Claim no.' +
        claimNo +
        ' END -------------------'
      );

      claimNo += 1;
    }
  }
}
