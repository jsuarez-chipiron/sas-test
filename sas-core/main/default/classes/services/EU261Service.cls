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
    public Boolean customerEntitledToRefund;
    public Decimal maximumTimeToClaimCompensation;
    public Boolean hasPotentiallyDuplicateClaims = false;
    public Boolean hasRelatedFiles = false;

    public ClaimWithCompensationDetails(LIA_Claim__c c) {
      this.claim = new Claims(new List<LIA_Claim__c>{ c });
    }

    public Boolean hasTripWithClaimFlight() {
      if (tripWithClaimFlight != null) {
        return true;
      }
      return false;
    }

    public Boolean hasDelay() {
      if (this.tripWithClaimFlight == null) {
        return null;
      }
      return this.tripWithClaimFlight.isDelayedToDestination();
    }

    public Boolean hasCancellation() {
      if (this.tripWithClaimFlight == null) {
        return null;
      }
      return this.tripWithClaimFlight.hasCancelledSegments();
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
      if (
        ac.claim.instanceRecords[0].Customer_Claim_Category__c !=
        'Flight disruptions'
      ) {
        ac.unhandledReason = 'can handle only claims in category "Flight disruptions"';
        ac.canBeEvaluated = false;
      } else if (
        ac.claim.instanceRecords[0].Customer_Claim_Type__c != 'Flight delay'
      ) {
        ac.unhandledReason = 'can handle only claims in type "Flight delay"';
        ac.canBeEvaluated = false;
      } else if (
        ac.claim.instanceRecords[0].RecordTypeId !=
        Claims.getRecordTypeId(Claims.RecordType.CustomerClaim)
      ) {
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
      } else if (ac.hasPotentiallyDuplicateClaims && false) {
        ac.unhandledReason = 'cannot handle potential duplicates';
        ac.canBeEvaluated = false;
      } else if (ac.booking.instanceRecords[0].Passengers__r.size() != 1) {
        ac.unhandledReason = 'can handle only one passenger per claim';
        ac.canBeEvaluated = false;
      } else if (ac.bookingType != Bookings.Type.OneWay) {
        ac.unhandledReason = 'can handle only one one way trips';
        ac.canBeEvaluated = false;
      } else if (ac.booking.instanceRecords[0].Segments__r.size() == 0) {
        ac.unhandledReason = 'no flight associated with the claim';
        ac.canBeEvaluated = false;
      } else if (ac.booking.instanceRecords[0].Segments__r.size() > 1) {
        ac.unhandledReason = 'can handle only one flight per claim';
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
      } else if (
        ac.claim.instanceRecords[0].Submitted_Claim_Expenses_in_SEK__c > 0
      ) {
        ac.unhandledReason = 'cannot handle claim expenses';
        ac.canBeEvaluated = false;
      } else if (
        ac.flightToIrregularities.get(
          ac.tripWithClaimFlight.sortedSegments[0].Flight__c
        ) == null ||
        ac.flightToIrregularities.get(
            ac.tripWithClaimFlight.sortedSegments[0].Flight__c
          )
          .size() != 1
      ) {
        ac.unhandledReason = 'cannot handle flights without exactly one irregularity';
        ac.canBeEvaluated = false;
      } else if (
        ac.flightToIrregularities.get(
            ac.tripWithClaimFlight.sortedSegments[0].Flight__c
          )[0]
          .Type__c.substringBefore(' ') != 'Delay'
      ) {
        ac.unhandledReason = 'cannot handle irregularities which are not type "Delay"';
        ac.canBeEvaluated = false;
      } else if (
        getMinutesDelayedWithinSASControl(ac) <= (2 * 60) ||
        getMinutesDelayedWithinSASControl(ac) >= (5 * 60)
      ) {
        ac.unhandledReason = 'can handle only delays between 2 and 5 hours';
        ac.canBeEvaluated = false;
      } else if (!SASIsOnlyOperatingCarrier(ac)) {
        ac.unhandledReason = 'cannot handle claims where SAS is not the only operating carrier';
        ac.canBeEvaluated = false;
      } else if (
        ac.claim.instanceRecords[0].Contact_Last_Name__c.toLowerCase() !=
        ac.booking.instanceRecords[0]
          .Passengers__r[0]
          .Last_Name__c.toLowerCase()
      ) {
        // TODO: This won't work for claims submitted by agencies because there is no last name. But those should always have files anyway.
        ac.unhandledReason = 'can handle only claims when contact name matches booking passenger';
        ac.canBeEvaluated = false;
      } else {
        ac.canBeEvaluated = true;
      }
      // TODO: ~Check proactivities Maybe something like if there's any proactivity for this claim, dont do anything. We could also move this to be later.
    }

    return claimsToAutomate;
  }

  private static void calculateReimbursement(
    List<ClaimWithCompensationDetails> handledClaims
  ) {
    for (ClaimWithCompensationDetails ac : handledClaims) {
      ac.careReimbursement = 0;
    }
  }

  private static void determineEligibilityAndCalculateCompensation(
    List<ClaimWithCompensationDetails> claimsWhichCanBeEvaluated
  ) {
    for (ClaimWithCompensationDetails ac : claimsWhichCanBeEvaluated) {
      if (!isCoveredByEU261(ac)) {
        // Was the flight from/to the right place + insanely complex edge case
        ac.rejectionReason = 'not covered by EU261';
        ac.customerEntitledToCompensation = false;
      } else if (!isFiledOnTime(ac)) {
        ac.rejectionReason = 'not filed on time';
        ac.customerEntitledToCompensation = false;
      } else if (!cancellationCodeIsWithinSASControl(ac) && false) {
        // TODO: Implement cancellation logic, should be sorted out by canWeEvaluate()
        ac.rejectionReason = 'cancellation code not within SAS control';
        ac.customerEntitledToCompensation = false;
      } else if (!ac.hasDelay()) {
        ac.rejectionReason = 'flight not delayed';
        ac.customerEntitledToCompensation = false;
      } else {
        Boolean canBeCompensated = true; // Nathan: What is this for? Seems like something canWeEvaluate() handles?
        if (canBeCompensated) {
          ac = setEU261Compensation(ac); // Also sets wether they are entitled
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
   * If there has been more than X years since the flight flew the customer is no longer eligable to apply for compensation.
   * If there is no information about the country limit in the database the limit is set to 3 years.
   * TODO: Find limits for different countries and talk to Liability if we can implement some general rule.
   *
   * @return a boolean which asserts whether the claim was filed on time.
   */
  private static Boolean isFiledOnTime(ClaimWithCompensationDetails ac) {
    Datetime claimCreation = ac.claim.instanceRecords[0].CreatedDate;
    Datetime tripDate = ac.tripWithClaimFlight.getFinalDestinationArrivalTime();

    return DateUtils.areWithinTimeLimit(
      claimCreation,
      tripDate,
      ac.maximumTimeToClaimCompensation
    );
  }

  /**
   * Calculates how much compensation in EUR the customer(s) is/are entitled to as per EU261.
   * Source: EU261 Article 6 and 7. (https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   *
   * @return the ClaimWithCompensationDetails object with the correct compensation in EUR and/or rejection reason.
   */
  private static ClaimWithCompensationDetails setEU261Compensation(
    ClaimWithCompensationDetails ac
  ) {
    final Integer MINIMUM_DELAY_FOR_COMPENSATION = 180;
    final Integer MINIMUM_DELAY_FOR_INCREASED_COMPENSATION = 240;
    final Integer MINIMUM_DELAY_FOR_REFUND = 300;
    final Integer MEDIUM_DISTANCE = 1500;
    final Integer LONG_DISTANCE = 3500;

    Integer delayedMinutes = getMinutesDelayedWithinSASControl(ac);
    Integer flightDistanceInKm = Airports.distanceBetweenAirportsInMeters(
      ac.tripWithClaimFlight.originAirport,
      ac.tripWithClaimFlight.destinationAirport
    );
    Integer numberOfEligiblePassengers = getNumberOfPassengersEligibleForCompensation(
      ac
    ); // Calculate revenue, todo: implement

    if (delayedMinutes < MINIMUM_DELAY_FOR_COMPENSATION) {
      ac.customerEntitledToCompensation = false;
      ac.rejectionReason = 'delayed less than 180 minutes';
    } else {
      if (flightDistanceInKm <= MEDIUM_DISTANCE) {
        ac.EU261Compensation = numberOfEligiblePassengers * 250;
      } else if (
        flightDistanceInKm > MEDIUM_DISTANCE &&
        (flightDistanceInKm <= LONG_DISTANCE || isIntraCommunity(ac))
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
        if (delayedMinutes >= MINIMUM_DELAY_FOR_REFUND) {
          ac.customerEntitledToRefund = true;
        }
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

  private static Boolean isIntraCommunity(ClaimWithCompensationDetails ac) {
    Airport__c originAirport = ac.tripWithClaimFlight.originAirport;
    Airport__c destinationAirport = ac.tripWithClaimFlight.destinationAirport;
    return originAirport.Is_EU261_Applicable__c &&
      destinationAirport.Is_EU261_Applicable__c;
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

  private static Boolean SASIsOnlyOperatingCarrier(
    ClaimWithCompensationDetails ac
  ) {
    return ac.tripWithClaimFlight.hasOnlySASFlights;
  }

  /**
   * TODO: Ask Liability for help. See FlightIrregularities.isWithinSASControl()
   */
  private static Boolean cancellationCodeIsWithinSASControl(
    ClaimWithCompensationDetails ac
  ) {
    if (!ac.tripWithClaimFlight.hasCancelledSegments()) {
      return false; // TODO: Implement, set return to null
    } else {
      List<FlightIrregularities__c> irregularitiesWithCancellationCodes = new List<FlightIrregularities__c>{};
      // Get all irregularities with cancellation codes
      for (Segment__c s : ac.tripWithClaimFlight.sortedSegments) {
        for (
          FlightIrregularities__c f : ac.flightToIrregularities.get(s.Flight__c)
        ) {
          if (f.Type__c.substringBefore(' ') == 'Cancellation') {
            irregularitiesWithCancellationCodes.add(f);
          }
        }
      }

      // Evaluate if it is within SAS control
      if (irregularitiesWithCancellationCodes.size() == 0) {
        // TODO: Define: What should we do here?
        throw new AutomationException('Cancellation has no cancellation code.');
      } else if (irregularitiesWithCancellationCodes.size() == 1) {
        Map<Id, Boolean> irregularityToIsWithinSASControl = FlightIrregularities.newInstance(
            irregularitiesWithCancellationCodes
          )
          .isWithinSASControl();

        Boolean isWithinSASControl = irregularityToIsWithinSASControl.get(
          irregularitiesWithCancellationCodes[0].Id
        );
        return isWithinSASControl;
      } else {
        throw new AutomationException(
          'Bookings with more than one cancellation code in a trip is currently not supported for automation.'
        );
      }
    }
  }

  /**
   * TODO: Make much more complicated, this data is not available in TEDS (?ö).
   * Investigate: Can people in the same booking have different number of flights?
   * @param AutomationUtils.AutomationContainer ac
   * @return The amount of passengers which should have compensation
   */
  private static Integer getNumberOfPassengersEligibleForCompensation(
    ClaimWithCompensationDetails ac
  ) {
    // TODO: Check: Is it an ID ticket? -> Not eligable (?)
    // TODO: Check: Is fare = 0?
    // TODO: Check: Is it an award ticket? (? ask someone)
    // TODO: Check: Is it an infant domestic?
    // TODO: Check: Is it DK domestic?

    Integer numberOfPassengers = ac.booking.instanceRecords[0]
      .Passengers__r.size();
    if (numberOfPassengers != 1) {
      throw new AutomationException(
        'Claims with more (or less) than one passenger is currently not supported.'
      );
    }
    return numberOfPassengers;
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
    List<LIA_Claim__c> claims = claimsSel.selectByIdWithCustomers(claimIds);

    // 2. Extract information needed for selection
    Set<String> allCountriesInClaims = new Set<String>{};
    Set<Id> allCaseIdsInClaims = new Set<Id>();
    Set<String> allPnrsInClaims = new Set<String>();
    for (LIA_Claim__c c : claims) {
      allCountriesInClaims.add(c.Country__c);
      allCaseIdsInClaims.add(c.Case__c);
      allPnrsInClaims.add(c.Liability_PNR__c);
    }

    // 3. Get "duplicate" claims
    List<LIA_Claim__c> otherClaimsWithMatchingPnrs = claimsSel.selectByBookingReference(
      allPnrsInClaims
    );

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
    List<LIA_Claim__c> claims,
    Map<String, Decimal> countryToClaimSubmissionTimeLimit,
    List<LIA_Claim__c> otherClaimsWithMatchingPnrs,
    List<ContentDocumentLink> filesForClaims,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById,
    List<FlightIrregularities__c> flightIrregularities,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    List<ClaimWithCompensationDetails> claimsToAutomate = new List<ClaimWithCompensationDetails>{};
    for (LIA_Claim__c c : claims) {
      ClaimWithCompensationDetails cwcd = new ClaimWithCompensationDetails(c);

      // TODO: refactor handle with airportCodeToAirport
      cwcd.maximumTimeToClaimCompensation = 3;
      // countryToClaimSubmissionTimeLimit.get(
      //   c.Country__c
      // );

      // check if the claim matches any other claim by PNR
      for (LIA_Claim__c otherClaim : otherClaimsWithMatchingPnrs) {
        if (
          c.Liability_PNR__c == otherClaim.Liability_PNR__c &&
          c.Id != otherClaim.Id
        ) {
          cwcd.hasPotentiallyDuplicateClaims = true;
        }
      }

      // check if there are any files linked to the parent case, problematic due to PoAs
      for (ContentDocumentLink cdl : filesForClaims) {
        if (cdl.LinkedEntityId == c.Case__c) {
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
    LIA_Claim__c c,
    ClaimWithCompensationDetails cwcd,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById
  ) {
    // Get bookings for claim
    List<Booking__c> bookingsForClaim = new List<Booking__c>();
    for (CaseToBooking__c ctb : caseIdToCaseToBookings.get(c.Case__c)) {
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
    LIA_Claim__c c,
    ClaimWithCompensationDetails cwcd,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    cwcd.trips = cwcd.booking.getTrips(airportCodeToAirport);

    // Todo: use stringutils / the flight domain (implement)
    String flightNumberDate =
      c.Flight_Number__c +
      '-' +
      String.valueOf(c.Flight_Date__c).remove('-');

    if (cwcd.booking.instanceRecords.size() > 0) {
      for (Trip t : cwcd.trips.get(cwcd.booking.instanceRecords[0].Id)) {
        if (t.containsFlight(flightNumberDate)) {
          cwcd.tripWithClaimFlight = t;
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
          claimSpecificIrregularities.put(
            s.Flight__c,
            flightIdToIrregularities.get(s.Flight__c)
          );
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
    for (ClaimWithCompensationDetails c : claimsWhichCannotBeEvaluated) {
      c.claim.instanceRecords[0].EU261_Handling_Note__c = c.unhandledReason;
      c.claim.instanceRecords[0].EU261_Handling_Status__c = 'Unable to handle';
      uow.registerDirty(c.claim.instanceRecords);
    }

    for (ClaimWithCompensationDetails c : claimsToReject) {
      c.claim.instanceRecords[0].EU261_Handling_Note__c = c.rejectionReason;
      c.claim.instanceRecords[0]
        .EU261_Handling_Status__c = 'Ineligible for compensation';
      uow.registerDirty(c.claim.instanceRecords);
    }

    for (ClaimWithCompensationDetails c : claimsToPayOut) {
      c.claim.instanceRecords[0].EU261_Handling_Note__c =
        'Compensation: ' +
        c.EU261Compensation +
        ' | Reimbursement: ' +
        c.careReimbursement;
      c.claim.instanceRecords[0]
        .EU261_Handling_Status__c = 'Eligible for compensation';
      uow.registerDirty(c.claim.instanceRecords);
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
        '. customerEntitledToRefund: ' +
        c.customerEntitledToRefund +
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
