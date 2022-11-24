/**
 *
 * An instance of this class is a single (batch) run of EU261 automation.
 */
public without sharing class EU261Service {
  private static final SettlementItem.CostAccount COMPENSATION_COST_ACCOUNT = SettlementItem.CostAccount.CA6727;
  private static final SettlementItem.CostAccount REIMBURSEMENT_COST_ACCOUNT = SettlementItem.CostAccount.CA6738;

  @TestVisible
  private static final String AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved';
  @TestVisible
  private static final String AUTOMATION_REJECTED_EMAIL_TEMPLATE_NAME = 'eu261_automation_rejected';
  private static final String AUTOMATION_REPLY_TO_ADDRESS = 'customercare@sas.se';

  private static final String COMPENSATION_WITHOUT_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a total amount of {0} {1}.';
  private static final String COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a flat rate compensation of {0} {1} and with a reimbursement of {2} {3} for the expenses you experienced during the delay.';

  private static final String MANUAL_HANDLING_QUEUE = 'Customer_Claim';

  @TestVisible
  private static final Map<EU261Claim.SemiAutomationReason, String> SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS = new Map<EU261Claim.SemiAutomationReason, String>{
    EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney => 'Requires power of attorney',
    EU261Claim.SemiAutomationReason.HasPotentialDuplicates => 'Check and close duplicate case. Check the settlement and submit to approval.',
    EU261Claim.SemiAutomationReason.HasHighClaimExpenses => '...',
    EU261Claim.SemiAutomationReason.InvalidSettlementDetails => '...'
  };

  public Config config;

  private Map<Id, Case> parentCasesById = new Map<Id, Case>();
  private Map<Id, Settlement__c> existingSettlementsByClaimId = new Map<Id, Settlement__c>();

  public class Config {
    public Decimal percentageRequiringManualApproval;

    public Boolean enabledSettlements;
    public Boolean enabledRejections;
    public Boolean enabledSemiAutomation;

    public Money expenseLimitAccommodation;
    public Money expenseLimitFood;
    public Money expenseLimitPhoneCalls;
    public Money expenseLimitTransportation;
    public Money expenseLimitTotal;

    public Integer claimsPerBatch;

    public Config() {
      percentageRequiringManualApproval = 0;

      enabledSettlements = false;
      enabledRejections = false;
      enabledSemiAutomation = false;

      expenseLimitAccommodation = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitFood = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitPhoneCalls = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitTransportation = new Money(0, Money.CurrencyCode.SEK);
      expenseLimitTotal = new Money(0, Money.CurrencyCode.SEK);

      claimsPerBatch = 40;
    }

    public Config(EU261_Automation_Configuration__mdt config) {
      this.enabledRejections = U.getOr(false, config.Automatic_Rejection__c);
      this.enabledSettlements = U.getOr(false, config.Automatic_Settlement__c);
      this.enabledSemiAutomation = U.getOr(
        false,
        config.Automatic_Settlement__c
      ); // TODO: FIX to correct field.
      this.expenseLimitAccommodation = new Money(
        U.getOr(0, config.Expense_Limit_Accommodation__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitFood = new Money(
        U.getOr(0, config.Expense_Limit_Food__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitPhoneCalls = new Money(
        U.getOr(0, config.Expense_Limit_Phone_Calls__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitTransportation = new Money(
        U.getOr(0, config.Expense_Limit_Transportation__c),
        Money.CurrencyCode.SEK
      );
      this.expenseLimitTotal = new Money(
        U.getOr(0, config.Claim_Expense_Max_Amount__c),
        Money.CurrencyCode.SEK
      );
      this.percentageRequiringManualApproval = U.getOr(
        0,
        config.Percentage_Sent_to_Control__c
      );
      this.claimsPerBatch = U.getOr(40, (Integer) config.Claims_Per_Batch__c);
    }
  }

  public static EU261Service newInstance() {
    return (EU261Service) SAS_Service_Application.Service.newInstance(
      EU261Service.class
    );
  }

  public EU261Service() {
    List<EU261_Automation_Configuration__mdt> automationConfig = [
      SELECT
        Automatic_Rejection__c,
        Automatic_Settlement__c,
        Claim_Expense_Max_Amount__c,
        Claims_Per_Batch__c,
        Expense_Limit_Accommodation__c,
        Expense_Limit_Food__c,
        Expense_Limit_Phone_Calls__c,
        Expense_Limit_Transportation__c,
        Percentage_Sent_to_Control__c
      FROM EU261_Automation_Configuration__mdt
      WHERE Label = 'Default'
    ];

    if (automationConfig == null || automationConfig.size() != 1) {
      throw new AutomationException(
        'Missing EU261_Automation_Configuration__mdt.'
      );
    }

    this.config = new Config(automationConfig[0]);
  }

  public class AutomationException extends Exception {
  }

  public void processEU261Claims(Set<Id> claimIds) {
    U.verifyNotNull(claimIds);
    //fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    this.automateEU261Claims(claimIds);
    //uow.commitWork();
  }

  public void batchProcessEU261Claims(Set<Id> claimIds) {
    Integer limitPerBatchRun = 40;
    List<Id> claimIdsOdered = new List<Id>(claimIds);
    Integer claimsRemaining = claimIdsOdered.size();
    while (claimsRemaining > 0) {
      if (claimsRemaining > limitPerBatchRun) {
        // 200 is too much
        List<Id> notAllClaimIds = new List<Id>{};
        for (Integer i = 0; i < limitPerBatchRun; i++) {
          notAllClaimIds.add(claimIdsOdered[0]);
          claimIdsOdered.remove(0);
        }
        claimsRemaining = claimIdsOdered.size();
        System.enqueueJob(
          new ProcessEU261ClaimsAsync(new Set<Id>(notAllClaimIds))
        );
      } else {
        System.enqueueJob(
          new ProcessEU261ClaimsAsync(new Set<Id>(claimIdsOdered))
        );
        claimsRemaining = 0;
      }
    }
  }

  public class ProcessEU261ClaimsAsync implements Queueable, Database.AllowsCallouts {
    private Set<Id> claimIds;

    public ProcessEU261ClaimsAsync(Set<Id> claimIds) {
      this.claimIds = claimIds;
    }

    public void execute(QueueableContext ctx) {
      EU261Service.newInstance().processEU261Claims(claimIds);
    }
  }

  /**
   * @param claimIds a Set of Ids of the claims to be automated
   *
   * @return A list of EU261Claims which contain the decision of how the automation handled them.
   */
  @TestVisible
  private List<EU261Claim> automateEU261Claims(Set<Id> claimIds) {
    List<EU261Claim> claimsToAutomate = gatherAllNecessaryInformation(claimIds);

    for (EU261Claim c : claimsToAutomate) {
      c.evaluate();
    }

    fflib_ISObjectUnitOfWork uow1 = SAS_Service_Application.UnitOfWork.newInstance();
    storeClaimDecision(uow1, claimsToAutomate);
    uow1.commitWork();

    fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
    settleAndRejectClaims(uow2, claimsToAutomate);
    uow2.commitWork();

    // debugResult(claimsToAutomate);

    return claimsToAutomate;

    // TODO: Log out some details about how many were handled.
  }

  /**
   * @param claims a list of claims for which to find information.
   *
   * @return a list of ClaimWithCompensationDetails containing all information necessary to automate the claim.
   */
  private List<EU261Claim> gatherAllNecessaryInformation(Set<Id> claimIds) {
    // 1. Get claims
    ClaimsSelector claimsSel = ClaimsSelector.newInstance();
    List<Claim> claims = new List<Claim>();
    List<List<String>> pnrFlightNumberTuples = new List<List<String>>();

    for (LIA_Claim__c c : claimsSel.selectByIdWithCustomers(claimIds)) {
      claims.add(new Claim(c));
      pnrFlightNumberTuples.add(
        new List<String>{ c.Liability_PNR__c, c.Flight_Number__c }
      );
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

    List<CARE_Claim__c> possiblyDuplicateCAREClaims = CAREClaimsSelector.newInstance()
      .selectPotentialDuplicates(pnrFlightNumberTuples);

    // 4. Map cases to bookings and get bookings
    List<CaseToBooking__c> ctbs = CaseToBookingsSelector.newInstance()
      .selectByCaseId(allCaseIdsInClaims);
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings = new Map<Id, List<CaseToBooking__c>>();
    Set<Id> allBookingIds = new Set<Id>();

    for (Case c : CasesSelector.newInstance().selectById(allCaseIdsInClaims)) {
      parentCasesById.put(c.Id, c);
    }

    if (ctbs != null) {
      for (CaseToBooking__c c : ctbs) {
        if (caseIdToCaseToBookings.get(c.Case__c) == null) {
          caseIdToCaseToBookings.put(
            c.Case__c,
            new List<CaseToBooking__c>{ c }
          );
        } else {
          caseIdToCaseToBookings.get(c.Case__c).add(c);
        }

        allBookingIds.add(c.Booking__c);
      }
    }

    List<Settlement__c> allSettlementsForClaims = SettlementsSelector.newInstance()
      .selectByClaimId(claimIds);
    if (
      this.config.enabledSettlements &&
      allSettlementsForClaims != null &&
      allSettlementsForClaims.size() > 0
    ) {
      //
      List<String> claimsHavingSettlements = new List<String>();
      for (Settlement__c s : allSettlementsForClaims) {
        claimsHavingSettlements.add(s.Claim__c);
      }
      throw new AutomationException(
        'Found settlements for claims: ' +
        String.join(claimsHavingSettlements, ', ')
      );
    }

    List<Booking__c> allBookingsFoundInClaims = BookingsSelector.newInstance()
      .selectByIdFull(allBookingIds);

    Map<Id, Booking__c> bookingsById = new Map<Id, Booking__c>(
      allBookingsFoundInClaims
    );

    Set<String> allTEDSFlightIds = new Set<String>{};
    Set<String> allAirportCodes = new Set<String>{};
    Set<Id> segmentIds = new Set<Id>{};
    for (Booking__c b : allBookingsFoundInClaims) {
      for (Segment__c s : b.Segments__r) {
        allTEDSFlightIds.add(s.Flight__r.TEDS_Identifier__c);
        segmentIds.add(s.Id);
        allAirportCodes.add(s.Flight__r.Departure_Airport__c);
        allAirportCodes.add(s.Flight__r.Arrival_Airport__c);
      }
    }

    List<Airport__c> allAirports = AirportsSelector.newInstance()
      .selectByIATACode(allAirportCodes);
    Map<String, Airport> airportCodeToAirportObjects = new Airports(allAirports)
      .getAirportCodeToAirportObject();

    // 5. Get time limits for how long a pax can wait before filing a claim. Todo: Reimplement, do after airports are fetched in constructClaimWithCompensationDetails
    Map<String, Decimal> countryToClaimSubmissionTimeLimit = new Map<String, Decimal>{};
    // CountryUtils.getAmountOfYearsYouCanWaitToFileAClaim(
    //   allCountriesInClaims
    // );

    // 6. Get flight irregularities:
    List<FlightIrregularities__c> flightIrregularities = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(allTEDSFlightIds);

    // 7. Get all segment events (massive):
    List<Segment_Event__c> segmentEvents = SegmentEventsSelector.newInstance()
      .selectBySegmentId(segmentIds);

    return constructClaimWithCompensationDetails(
      claims,
      countryToClaimSubmissionTimeLimit,
      otherClaimsWithMatchingPnrs,
      caseIdToCaseToBookings,
      bookingsById,
      flightIrregularities,
      segmentEvents,
      airportCodeToAirportObjects,
      possiblyDuplicateCAREClaims
    );
  }

  private List<EU261Claim> constructClaimWithCompensationDetails(
    List<Claim> claims,
    Map<String, Decimal> countryToClaimSubmissionTimeLimit,
    List<Claim> otherClaimsWithMatchingPnrs,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById,
    List<FlightIrregularities__c> flightIrregularities,
    List<Segment_Event__c> segmentEvents,
    Map<String, Airport> airportCodeToAirportObjects,
    List<CARE_Claim__c> possiblyDuplicateCAREClaims
  ) {
    List<EU261Claim> toReturn = new List<EU261Claim>{};

    Map<Id, List<FlightIrregularity>> flightIdToIrregularities = new Map<Id, List<FlightIrregularity>>();

    for (FlightIrregularities__c fi : flightIrregularities) {
      FlightIrregularity newFi = new FlightIrregularity(fi);
      if (flightIdToIrregularities.get(newFi.flightId) == null) {
        flightIdToIrregularities.put(
          newFi.flightId,
          new List<FlightIrregularity>()
        );
      }

      if (!newFi.isNA0Delay()) {
        flightIdToIrregularities.get(newFi.flightId).add(newFi);
      }
    }

    for (Id flightId : flightIdToIrregularities.keySet()) {
      flightIdToIrregularities.put(
        flightId,
        FlightIrregularity.unique(flightIdToIrregularities.get(flightId))
      );
    }

    Map<Id, List<SegmentEvent>> segmentIdToSegmentEvents = new Map<Id, List<SegmentEvent>>();
    for (Segment_Event__c se : segmentEvents) {
      SegmentEvent newSe = new SegmentEvent(se);
      if (segmentIdToSegmentEvents.get(newSe.segmentId) == null) {
        segmentIdToSegmentEvents.put(newSe.segmentId, new List<SegmentEvent>());
      }

      segmentIdToSegmentEvents.get(newSe.segmentId).add(newSe);
    }

    for (Claim c : claims) {
      List<Booking__c> bookingsForClaim = new List<Booking__c>();

      List<CaseToBooking__c> ctbsForClaim = caseIdToCaseToBookings.get(
        c.parentCaseId
      );

      if (ctbsForClaim != null) {
        for (CaseToBooking__c ctb : ctbsForClaim) {
          Booking__c booking = bookingsById.get(ctb.Booking__c);
          if (booking != null) {
            bookingsForClaim.add(booking);
          }
        }
      }

      Bookings booking = Bookings.newInstance(bookingsForClaim);

      // Check if the claim matches any other claim by PNR
      Boolean hasPotentiallyDuplicateClaims = false;
      for (Claim otherClaim : otherClaimsWithMatchingPnrs) {
        if (
          c.bookingReference == otherClaim.bookingReference &&
          c.id != otherClaim.id
        ) {
          hasPotentiallyDuplicateClaims = true;
        }
      }
      for (CARE_Claim__c cc : possiblyDuplicateCAREClaims) {
        if (
          c.bookingReference == cc.Booking_Reference__c &&
          c.flightNumber == cc.Flight_Number__c
        ) {
          hasPotentiallyDuplicateClaims = true;
        }
      }

      Map<Id, List<FlightIrregularity>> claimSpecificIrregularities = new Map<Id, List<FlightIrregularity>>{};
      if (booking.instanceRecords.size() > 0) {
        for (Segment__c s : booking.instanceRecords[0].Segments__r) {
          List<FlightIrregularity> flightIrreg = flightIdToIrregularities.get(
            s.Flight__c
          );
          if (flightIrreg == null) {
            flightIrreg = new List<FlightIrregularity>{};
          }
          claimSpecificIrregularities.put(s.Flight__c, flightIrreg);
        }
      }

      for (Booking b : booking.objects) {
        for (Segment s : b.segments) {
          s.flight.irregularities = claimSpecificIrregularities.get(
            s.flight.id
          );
          List<SegmentEvent> events = segmentIdToSegmentEvents.get(s.Id);
          s.setEvents(events);
          b.setAirports(airportCodeToAirportObjects);
        }
      }

      EU261Claim fullClaim = new EU261Claim(
        c,
        booking.objects,
        hasPotentiallyDuplicateClaims,
        this.config
      );

      toReturn.add(fullClaim);
    }

    return toReturn;
  }

  private void storeClaimDecision(
    fflib_ISObjectUnitOfWork uow,
    List<EU261Claim> claimsToAutomate
  ) {
    List<Claim> toUpsert = new List<Claim>();
    for (EU261Claim ac : claimsToAutomate) {
      Claim c = ac.claimObj;

      c.eu261HandlingStatus = ac.decision.verdict;

      if (
        ac.decision.verdict == Claim.EU261HandlingStatus.EligibleForCompensation
      ) {
        c.eu261HandlingNote =
          'Compensation: ' +
          ac.decision.compensationPerCustomerInEUR.values() +
          ' | Reimbursement: ' +
          ac.decision.reimbursementAmountInSEK;
      } else if (
        ac.decision.verdict ==
        Claim.EU261HandlingStatus.PossiblyEligibleForCompensation
      ) {
        c.eu261HandlingNote =
          'Compensation: ' +
          ac.decision.compensationPerCustomerInEUR.values() +
          ' | Reimbursement: ' +
          ac.decision.reimbursementAmountInSEK +
          ' (' +
          ac.decision.reasoning +
          ')';
      } else {
        c.eu261HandlingNote = ac.decision.reasoning;
      }

      toUpsert.add(c);
    }

    Claims.newInstance(toUpsert).upsertToDB(uow);
  }

  /**
   * Processes all of the claims which we can settle, reject or automate
   * partially. Creates settlements, emails and prepares them and the claim and
   * case to updated in the DB.
   *
   * Splits claims into several groups based on w
   *
   * At this stage claims can be split into four different categories based on
   * what we want to do with them:
   * 1. Ones we want to pay out automatically
   * 2. Ones where customer appears to be eligible for payment but there are some caveats
   * 3. Ones we can reject automatically
   * 4. Ones where we cannot determine eligibility at all
   *
   * Claims in the first category we pay out directly, but some of these fall
   * to the approval queue for spot checcks. Claims in the second category we
   * can send to a specific manual handling queue with instructions for the
   * agents on what they need to check before rejecting or sending the claim to
   * approval. Claims in the third category we can just close and email the
   * customer the result and claims in the fourth category we do nothing with
   * as they need to go to manual handling.
   */
  private void settleAndRejectClaims(
    fflib_ISObjectUnitOfWork uow,
    List<EU261Claim> claimsToAutomate
  ) {
    ClaimService claimService = ClaimService.newInstance();

    List<EU261Claim> claimsToApproveAutomatically = new List<EU261Claim>();
    List<EU261Claim> claimsToManualApproval = new List<EU261Claim>();
    List<EU261Claim> claimsToReject = new List<EU261Claim>();
    List<EU261Claim> claimsToSemiAutomate = new List<EU261Claim>();

    List<Case> parentCasesForAutomaticApproval = new List<Case>();
    List<Case> parentCasesForManualApproval = new List<Case>();
    List<Case> parentCasesForSemiAutomation = new List<Case>();
    List<Case> parentCasesForRejection = new List<Case>();

    for (EU261Claim c : claimsToAutomate) {
      switch on c.decision.verdict {
        when EligibleForCompensation {
          if (shouldApproveAutomatically(c)) {
            claimsToApproveAutomatically.add(c);
            parentCasesForAutomaticApproval.add(
              parentCasesById.get(c.claimObj.parentCaseId)
            );
          } else {
            claimsToManualApproval.add(c);
            parentCasesForManualApproval.add(
              parentCasesById.get(c.claimObj.parentCaseId)
            );
          }
        }
        when PossiblyEligibleForCompensation {
          claimsToSemiAutomate.add(c);
          parentCasesForSemiAutomation.add(
            parentCasesById.get(c.claimObj.parentCaseId)
          );
        }
        when IneligibleForCompensation {
          claimsToReject.add(c);
          parentCasesForRejection.add(
            parentCasesById.get(c.claimObj.parentCaseId)
          );
        }
      }
    }

    if (this.config.enabledSettlements) {
      List<EU261Claim> claimsWhichNeedSettlements = new List<EU261Claim>(
        claimsToApproveAutomatically
      );
      claimsWhichNeedSettlements.addAll(claimsToManualApproval);

      if (this.config.enabledSemiAutomation) {
        claimsWhichNeedSettlements.addAll(claimsToSemiAutomate);
      }

      Map<Id, List<Settlement__c>> settlementsByClaimId = createSettlementsForClaims(
        claimsWhichNeedSettlements
      );

      if (claimsToManualApproval.size() > 0) {
        List<Settlement__c> settlementsForManualApproval = new List<Settlement__c>();
        for (EU261Claim cl : claimsToManualApproval) {
          settlementsForManualApproval.addAll(
            settlementsByClaimId.get(cl.claimObj.id)
          );
        }

        uow.registerNew(
          createDraftApprovedEmails(
            claimsToManualApproval,
            settlementsByClaimId
          )
        );

        Settlements.newInstance(settlementsForManualApproval)
          .validate()
          .submitToApproval(uow)
          .lock();

        Cases.newInstance(parentCasesForManualApproval).submitToApproval(uow);
      }

      if (claimsToApproveAutomatically.size() > 0) {
        Cases.newInstance(parentCasesForAutomaticApproval)
          .emailContactPeople(
            createApprovedEmails(
              claimsToApproveAutomatically,
              settlementsByClaimId
            ),
            uow
          )
          .close(uow);

        // TODO: Catch validation issues for the settlements and send to semi-automation.
        Claims.newInstance(
            EU261Claim.getClaimSObjectsFor(claimsToApproveAutomatically)
          )
          .settle(uow);
      }

      if (
        this.config.enabledSemiAutomation && claimsToSemiAutomate.size() > 0
      ) {
        Map<Id, String> handlingInstructionsByCaseId = new Map<Id, String>();
        for (EU261Claim cl : claimsToSemiAutomate) {
          List<EU261Claim.SemiAutomationReason> semiAutomationReasonsForClaim = cl.decision.caveats;

          List<String> handlingInstructions = new List<String>();
          for (
            EU261Claim.SemiAutomationReason reason : semiAutomationReasonsForClaim
          ) {
            handlingInstructions.add(
              SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS.get(reason)
            );
          }

          handlingInstructionsByCaseId.put(
            cl.claimObj.parentCaseId,
            'Action needed: ' + String.join(handlingInstructions, ' | ')
          );
        }

        Claims.newInstance(EU261Claim.getClaimSObjectsFor(claimsToSemiAutomate))
          .upsertToDB(uow);

        Cases.newInstance(parentCasesForSemiAutomation)
          .setHandlingInstructions(uow, handlingInstructionsByCaseId)
          .routeToQueue(MANUAL_HANDLING_QUEUE, uow);
      }
    }

    if (this.config.enabledRejections && claimsToReject.size() > 0) {
      Cases.newInstance(parentCasesForRejection)
        .emailContactPeople(createRejectionEmails(claimsToReject), uow)
        .close(uow);
    }
  }

  private Boolean shouldApproveAutomatically(EU261Claim cl) {
    return Math.random() * 100 >= this.config.percentageRequiringManualApproval;
  }

  /**
   * Creates settlements with settlement items for the given claims and inserts
   * them to the DB.
   *
   * Creates one or two settlements for each claim. If a claim
   * has only reimbursement or compensation this creates one settlement. If the
   * claim has both reimbursement and compensation, it creates two. We could
   * combine these into one settlement when the preferred compensation and
   * reimbursement methods are the same, but separating them out makes later
   * processing simpler.
   *
   * Does two DB inserts.
   *
   * @param claimsToPayOut A list of claims to be paid out. Must not include claims which shouldn't be settled.
   * @return A map from claim id to settlements for that claim. There can be one or two settlements per claim.
   */
  private Map<Id, List<Settlement__c>> createSettlementsForClaims(
    List<EU261Claim> claimsToPayOut
  ) {
    Map<Id, List<Settlement__c>> allSettlementsByClaimId = new Map<Id, List<Settlement__c>>();
    Map<Money.CurrencyCode, ExchangeRate> exchangeRatesFromEURByToCurrency = new Map<Money.CurrencyCode, ExchangeRate>();
    Map<Money.CurrencyCode, ExchangeRate> exchangeRatesFromSEKByToCurrency = new Map<Money.CurrencyCode, ExchangeRate>();

    for (
      ExchangeRate er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency(Money.CurrencyCode.EUR)
    ) {
      exchangeRatesFromEURByToCurrency.put(er.toCurrency, er);
    }
    for (
      ExchangeRate er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency(Money.CurrencyCode.SEK)
    ) {
      exchangeRatesFromSEKByToCurrency.put(er.toCurrency, er);
    }

    List<LIA_Claim__c> allPayableClaimSObjects = new List<LIA_Claim__c>();
    List<LIA_Claim__c> claimsRequiringTwoSettlements = new List<LIA_Claim__c>();

    for (EU261Claim c : claimsToPayOut) {
      allPayableClaimSObjects.add(c.claimObj.underlyingSObject);
      if (
        c.decision.reimbursementAmountInSEK.amount > 0 &&
        !c.hasHighClaimedExpenses()
      ) {
        claimsRequiringTwoSettlements.add(c.claimObj.underlyingSObject);
      }
    }

    fflib_ISObjectUnitOfWork uow1 = SAS_Service_Application.UnitOfWork.newInstance();
    Settlements compensationSettlements = Settlements.createFromClaim(
      allPayableClaimSObjects,
      null,
      false,
      uow1
    );
    Settlements reimbursementSettlements = Settlements.createFromClaim( // TODO: We shouldn't even create these if the amounts are too high.
      claimsRequiringTwoSettlements,
      null,
      true,
      uow1
    );
    uow1.commitWork();

    Map<Id, List<SettlementItem>> compensationSettlementItemsBySettlementId = new Map<Id, List<SettlementItem>>();
    Map<Id, List<SettlementItem>> reimbursementSettlementItemsBySettlementId = new Map<Id, List<SettlementItem>>();

    for (EU261Claim c : claimsToPayOut) {
      Settlement__c compensationSettlementForClaim;
      Settlement__c reimbursementSettlementForClaim;
      Boolean claimRequiresTwoSettlements = false;
      for (Settlement__c ss : compensationSettlements.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          compensationSettlementForClaim = ss;

          compensationSettlementItemsBySettlementId.put(
            ss.Id,
            new List<SettlementItem>()
          );

          allSettlementsByClaimId.put(
            ss.Claim__c,
            new List<Settlement__c>{ ss }
          );
          break;
        }
      }
      for (Settlement__c ss : reimbursementSettlements.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          reimbursementSettlementForClaim = ss;

          reimbursementSettlementItemsBySettlementId.put(
            ss.Id,
            new List<SettlementItem>()
          );

          claimRequiresTwoSettlements = true;

          allSettlementsByClaimId.get(ss.Claim__c).add(ss);
          break;
        }
      }

      for (
        ClaimCustomer customer : c.decision.compensationPerCustomerInEUR.keySet()
      ) {
        SettlementItem si = new SettlementItem();
        si.customerName = customer.fullName;
        si.costAccount = COMPENSATION_COST_ACCOUNT;
        si.comments = 'Automatic EU261 compensation';
        si.recordType = SettlementItem.RecordType.DefaultRecordType;
        compensationSettlementItemsBySettlementId.get(
            compensationSettlementForClaim.Id
          )
          .add(si);

        Money value = c.decision.compensationPerCustomerInEUR.get(customer);

        switch on c.claimObj.preferredCompensationMethod {
          when EBPoints {
            si.amount = value.inEuroBonusPoints();
          }
          when Voucher {
            si.setValue(
              value.multiplyBy(Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR)
                .setScale(0)
            );
          }
          when else {
            // Default to monetary
            Money.CurrencyCode settlementCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
              compensationSettlementForClaim.Currency__c
            );

            if (settlementCurrency != Money.CurrencyCode.EUR) {
              ExchangeRate exchangeRate = exchangeRatesFromEURByToCurrency.get(
                settlementCurrency
              );
              if (exchangeRate == null) {
                throw new AutomationException('Cannot find exchange rate.');
              } else {
                value = value.convertTo(settlementCurrency, exchangeRate);
              }
            }

            si.setValue(value.setScale(0));
          }
        }
      }

      Money reimbursement = c.decision.reimbursementAmountInSEK;
      if (
        reimbursement != null &&
        reimbursement.amount > 0 &&
        !c.hasHighClaimedExpenses()
      ) {
        // TODO: This needs to support creating a separate settlement in case we need to make a reimbusement
        // Cant have different methods in one settlement!
        SettlementItem si = new SettlementItem();
        si.customerName = c.claimObj.contactFullName;
        si.costAccount = REIMBURSEMENT_COST_ACCOUNT;
        si.comments = 'Automatic EU261 reimbursement';
        si.recordType = SettlementItem.RecordType.DefaultRecordType;

        reimbursementSettlementItemsBySettlementId.get(
            reimbursementSettlementForClaim.Id
          )
          .add(si);

        switch on c.claimObj.preferredReimbursementMethod {
          when EBPoints {
            ExchangeRate sekToEur = exchangeRatesFromSEKByToCurrency.get(
              Money.CurrencyCode.EUR
            );
            si.amount = reimbursement.convertTo(
                Money.CurrencyCode.EUR,
                sekToEur
              )
              .inEuroBonusPoints();
          }
          when Voucher {
            ExchangeRate sekToEur = exchangeRatesFromSEKByToCurrency.get(
              Money.CurrencyCode.EUR
            );

            si.setValue(
              reimbursement.convertTo(Money.CurrencyCode.EUR, sekToEur)
                .multiplyBy(Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR)
                .setScale(0)
            );
          }
          when else {
            // Default to monetary
            Money.CurrencyCode settlementCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
              reimbursementSettlementForClaim.Currency__c
            );

            if (settlementCurrency != Money.CurrencyCode.SEK) {
              ExchangeRate exchangeRate = exchangeRatesFromSEKByToCurrency.get(
                settlementCurrency
              );
              if (exchangeRate == null) {
                throw new AutomationException('Cannot find exchange rate.');
              } else {
                reimbursement = reimbursement.convertTo(
                  settlementCurrency,
                  exchangeRate
                );
              }
            }

            si.setValue(reimbursement.setScale(0));
          }
        }
      }
    }

    fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
    compensationSettlements.updateSettlementItems(
      compensationSettlementItemsBySettlementId,
      uow2
    );
    reimbursementSettlements.updateSettlementItems(
      reimbursementSettlementItemsBySettlementId,
      uow2
    );
    uow2.commitWork();

    return allSettlementsByClaimId;
  }

  /**
   * Creates emails for valid claims which will go through approval process.
   *
   * These will be sent only after approvers have approved the claim, following
   * the normal claim process.
   */
  private List<EmailMessage> createDraftApprovedEmails(
    List<EU261Claim> claimsToApproval,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    List<EmailMessage> toReturn = new List<EmailMessage>();

    for (EU261Claim cl : claimsToApproval) {
      EmailMessage draftEmailForClaim = EmailMessages.createEmailMessageFromTemplate(
        AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME,
        cl.claimObj.parentCaseId
      );

      String compensationText = createCompesationText(
        settlementsByClaimId.get(cl.claimObj.id)
      );

      draftEmailForClaim.HtmlBody = draftEmailForClaim.HtmlBody.replace(
        '|||compensationTextPlaceholder|||',
        compensationText
      );

      if (draftEmailForClaim.TextBody != null) {
        draftEmailForClaim.TextBody = draftEmailForClaim.TextBody.replace(
          '|||compensationTextPlaceholder|||',
          compensationText
        );
      }

      Case parentCase = parentCasesById.get(cl.claimObj.parentCaseId);
      draftEmailForClaim.ToAddress = parentCase.SuppliedEmail;
      draftEmailForClaim.Subject =
        'Your case ' +
        parentCase.CaseNumber +
        ' has been processed';

      toReturn.add(draftEmailForClaim);
    }

    return toReturn;
  }

  /**
   * Creates emails for rejected claims which will be closed automatically.
   */
  private Map<Id, Messaging.SingleEmailMessage> createRejectionEmails(
    List<EU261Claim> claimsToReject
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToReject) {
      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        AUTOMATION_REJECTED_EMAIL_TEMPLATE_NAME,
        c.claimObj.parentCaseId
      );

      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);
      emailToSend.setSubject(
        'Your case ' +
        parentCasesById.get(c.claimObj.parentCaseId).CaseNumber +
        ' has been processed'
      );

      emailsByClaimId.put(c.claimObj.parentCaseId, emailToSend);
    }

    return emailsByClaimId;
  }

  /**
   * Creates emails for valid claims which will be approved automatically.
   */
  private Map<Id, Messaging.SingleEmailMessage> createApprovedEmails(
    List<EU261Claim> claimsToSettle,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToSettle) {
      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME,
        c.claimObj.parentCaseId
      );

      String compensationText = createCompesationText(
        settlementsByClaimId.get(c.claimObj.id)
      );

      emailToSend.setHtmlBody(
        emailToSend.getHtmlBody()
          .replace('|||compensationTextPlaceholder|||', compensationText)
      );
      if (emailToSend.getPlainTextBody() != null) {
        emailToSend.setPlainTextBody(
          emailToSend.getPlainTextBody()
            .replace('|||compensationTextPlaceholder|||', compensationText)
        );
      }

      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);
      emailToSend.setSubject(
        'Your case ' +
        parentCasesById.get(c.claimObj.parentCaseId).CaseNumber +
        ' has been processed'
      );

      emailsByClaimId.put(c.claimObj.parentCaseId, emailToSend);
    }

    return emailsByClaimId;
  }

  /**
   * Returns the compensation text added to the email sent to the customer.
   *
   * @param settlementsByClaimId Values are lists of settlements where there should be one or two settlements.
   */
  private String createCompesationText(
    List<Settlement__c> settlementsForClaim
  ) {
    if (
      settlementsForClaim == null ||
      settlementsForClaim.isEmpty() ||
      settlementsForClaim.size() > 2
    ) {
      throw new U.InvalidArgumentException(
        'Invalid number of settlements: ' + settlementsForClaim
      );
    }

    String compensationText;

    Settlement__c compensationSettlement = settlementsForClaim[0];

    if (settlementsForClaim.size() == 1) {
      // There's only compensation
      List<Object> parameters = new List<Object>{
        getSettlementAmount(compensationSettlement),
        getSettlementCurrency(compensationSettlement)
      };
      compensationText = String.format(
        COMPENSATION_WITHOUT_REIMBURSEMENT_TEXT_TEMPLATE,
        parameters
      );
    } else {
      // There is both compensation and reimbursement
      Settlement__c reimbursementSettlement = settlementsForClaim[1];
      List<Object> parameters = new List<Object>{
        getSettlementAmount(compensationSettlement),
        getSettlementCurrency(compensationSettlement),
        getSettlementAmount(reimbursementSettlement),
        getSettlementCurrency(reimbursementSettlement)
      };
      compensationText = String.format(
        COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE,
        parameters
      );
    }

    return compensationText;
  }

  private static String getSettlementCurrency(Settlement__c s) {
    Id euroBonusRtId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );

    if (s.RecordTypeId == euroBonusRtId) {
      return 'points';
    } else {
      return s.Currency__c;
    }
  }

  private static String getSettlementAmount(Settlement__c s) {
    Id euroBonusRtId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );

    if (s.RecordTypeId == euroBonusRtId) {
      return String.valueOf(s.EuroBonus_Points__c);
    } else {
      return String.valueOf(s.Amount__c);
    }
  }
}
