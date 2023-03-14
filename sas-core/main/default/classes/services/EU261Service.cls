/**
 * An overall service class for running the automation process for EU261
 * claims. See EU261Claim.cls and Confluence for more details.
 *
 * Evaluation logic lives in EU261Claim and this class contains the infra
 * around that: fetching data, creating settlements and moving claims
 * around based on the results of the evaluation.
 *
 * An instance of this class is a single (batch) run of EU261 automation.
 */
public without sharing class EU261Service {
  private static final SettlementItem.CostAccount COMPENSATION_COST_ACCOUNT = SettlementItem.CostAccount.CA6727;
  private static final SettlementItem.CostAccount REIMBURSEMENT_COST_ACCOUNT = SettlementItem.CostAccount.CA6738;

  @TestVisible
  private static final String AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved';
  @TestVisible
  private static final String AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved_halved_late_arrival';
  @TestVisible
  private static final String AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved_halved_early_departure';

  @TestVisible
  private static final Map<EU261Protocol.DenialReason, String> DENIAL_REASON_TO_EMAIL_TEMPLATE_NAME = new Map<EU261Protocol.DenialReason, String>{
    EU261Protocol.DenialReason.NOTOUTSIDETIMEFRAME => 'eu261_automation_rejected_not_outside_timeframe',
    EU261Protocol.DenialReason.NOTFILEDONTIME => 'eu261_automation_rejected_not_filed_on_time',
    EU261Protocol.DenialReason.CANCELLEDWELLINTIME => 'eu261_automation_rejected_cancelled_well_in_time',
    EU261Protocol.DenialReason.CUSTOMERCANCELLED => 'eu261_automation_rejected_cusomter_cancelled',
    EU261Protocol.DenialReason.NOTWITHINSASCONTROL => 'eu261_automation_rejected_not_within_SAS_control'
    // EU261Protocol.DenialReason.DELAYTOOSMALL => null,
    // EU261Protocol.DenialReason.NODELAYORCANCELLATION => null
  }; // TODO: make delay templates (will increase the denial emails by ~3-6)

  private static final String AUTOMATION_REPLY_TO_ADDRESS = 'customercare@sas.se';

  private static final String COMPENSATION_WITHOUT_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a total amount of {0} {1}.';
  private static final String COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a flat rate compensation of {0} {1} and with a reimbursement of {2} {3} for the expenses you experienced during the delay.';

  private static final String SEMI_AUTOMATION_QUEUE = 'Claims_EU261_Semi_Automation';
  private static final String MANUAL_HANDLING_QUEUE = ''; // TODO: fix!

  @TestVisible
  private static final Map<EU261Claim.SemiAutomationReason, String> SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS = new Map<EU261Claim.SemiAutomationReason, String>{
    EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney => 'Check passenger names so they match claim and PNR, and if needed ask/validate PoA and submit to approval.',
    EU261Claim.SemiAutomationReason.HasPotentialDuplicates => 'Potential duplicates might exist, validate potential duplicate according to duplicate procedure, and submit to approval.',
    EU261Claim.SemiAutomationReason.HasHighClaimExpenses => 'Validate the expenses, create settlement, and submit to approval.',
    EU261Claim.SemiAutomationReason.InvalidSettlementDetails => 'Ask/validate the account details, correct the settlement, and submit to approval.'
  };

  public Config config;

  @TestVisible
  private Map<Id, Case> parentCasesById = new Map<Id, Case>();
  private Map<Id, Settlement__c> existingSettlementsByClaimId = new Map<Id, Settlement__c>();

  public class Config {
    public Decimal percentageRequiringManualApproval;

    public Boolean enabledCancellationAutomation;
    public Boolean enabledDelayAutomation;
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

      enabledCancellationAutomation = false;
      enabledDelayAutomation = false;
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
      this.enabledCancellationAutomation = U.getOr(
        false,
        config.Cancellation_Automation__c
      );
      this.enabledDelayAutomation = U.getOr(false, config.Delay_Automation__c);
      this.enabledRejections = U.getOr(false, config.Automatic_Rejection__c);
      this.enabledSettlements = U.getOr(false, config.Automatic_Settlement__c);
      this.enabledSemiAutomation = U.getOr(
        false,
        config.Semi_Automation_Enabled__c
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
        Delay_Automation__c,
        Cancellation_Automation__c,
        Claim_Expense_Max_Amount__c,
        Claims_Per_Batch__c,
        Expense_Limit_Accommodation__c,
        Expense_Limit_Food__c,
        Expense_Limit_Phone_Calls__c,
        Expense_Limit_Transportation__c,
        Percentage_Sent_to_Control__c,
        Semi_Automation_Enabled__c
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
  public class EmailTemplateException extends Exception {
  }

  //Separera?
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
   * Runs the EU261 evaluation and processing for the given set of claims
   * synchronously. See Config for options on what kinds of automation should
   * be done, and for other configuration parameters.
   *
   * @param claimIds A set of claim Ids to process.
   *
   * @return A list of EU261Claims which contain the decision of how the automation handled them.
   */
  public List<EU261Claim> processEU261Claims(Set<Id> claimIds) {
    U.verifyNotNull(claimIds);

    List<EU261Claim> claimsToAutomate = gatherAllNecessaryInformation(claimIds);

    claimsToAutomate = filterClaimTypes(claimsToAutomate);

    for (EU261Claim c : claimsToAutomate) {
      c.evaluate();
    }

    storeClaimDecision(claimsToAutomate);

    settleAndRejectClaims(claimsToAutomate);

    return claimsToAutomate;
  }

  /**
   * Filters claims which are not enabled in the config.
   */
  private List<EU261Claim> filterClaimTypes(List<EU261Claim> claimsToAutomate) {
    List<EU261Claim> filteredClaims = new List<EU261Claim>();
    for (EU261Claim c : claimsToAutomate) {
      if (
        !EU261Claim.DELAY_CLAIM_TYPES.contains(c.claimObj.type) &&
        !EU261Claim.CANCELLATION_CLAIM_TYPES.contains(c.claimObj.type)
      ) {
        throw new AutomationException('Unsupported claim type');
      } else if (
        EU261Claim.CANCELLATION_CLAIM_TYPES.contains(c.claimObj.type) &&
        this.config.enabledCancellationAutomation
      ) {
        filteredClaims.add(c);
      } else if (
        EU261Claim.DELAY_CLAIM_TYPES.contains(c.claimObj.type) &&
        this.config.enabledDelayAutomation
      ) {
        filteredClaims.add(c);
      }
    }
    return filteredClaims;
  }

  /**
   * Fetches all of the necessary data to construct EU261Claim objects which
   * can be evaluated by the automation, and constructs the objects.
   *
   * All information must already exist in Salesforce.
   *
   * @return A list of EU261Claims, one per given Id.
   */
  private List<EU261Claim> gatherAllNecessaryInformation(Set<Id> claimIds) {
    ClaimsSelector claimsSel = ClaimsSelector.newInstance();
    List<Claim> claims = new List<Claim>();
    List<List<String>> pnrFlightNumberTuples = new List<List<String>>();

    Set<Id> claimIdsIgnored = new Set<Id>();

    for (LIA_Claim__c c : claimsSel.selectByIdWithCustomers(claimIds)) {
      try {
        Flight.normalizeFlightNumber(c.Flight_Number__c);
        claims.add(new Claim(c));
        pnrFlightNumberTuples.add(
          new List<String>{ c.Liability_PNR__c, c.Flight_Number__c }
        );
      } catch (Exception e) {
        System.debug(
          'Unable to normalize flight number: ' +
          c.Flight_Number__c +
          ' for claim: ' +
          c.Id
        );
        claimIdsIgnored.add(c.Id);
      }
    }

    Set<String> allCountriesInClaims = new Set<String>{};
    Set<Id> allCaseIdsInClaims = new Set<Id>();
    Set<String> allPnrsInClaims = new Set<String>();
    for (Claim c : claims) {
      allCountriesInClaims.add(c.contactCountry);
      allCaseIdsInClaims.add(c.parentCaseId);
      allPnrsInClaims.add(c.bookingReference);
    }

    List<Claim> otherClaimsWithMatchingPnrs = new List<Claim>();
    for (LIA_Claim__c c : claimsSel.selectByBookingReference(allPnrsInClaims)) {
      otherClaimsWithMatchingPnrs.add(new Claim(c));
    }

    List<CARE_Claim__c> possiblyDuplicateCAREClaims = CAREClaimsSelector.newInstance()
      .selectPotentialDuplicates(pnrFlightNumberTuples);

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

    Map<String, Airport> airportCodeToAirportObjects = new Airports(
        AirportsSelector.newInstance().selectByIATACode(allAirportCodes)
      )
      .getAirportCodeToAirportObject();

    List<FlightIrregularities__c> flightIrregularities = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(allTEDSFlightIds);

    List<Segment_Event__c> segmentEvents = SegmentEventsSelector.newInstance()
      .selectBySegmentId(segmentIds);

    return constructClaimWithCompensationDetails(
      claims,
      otherClaimsWithMatchingPnrs,
      caseIdToCaseToBookings,
      bookingsById,
      flightIrregularities,
      segmentEvents,
      airportCodeToAirportObjects,
      possiblyDuplicateCAREClaims
    );
  }

  /**
   * Constructs a list of EU261Claims given all necessary information.
   *
   * Helper for gatherAllNecessaryInformation().
   */
  private List<EU261Claim> constructClaimWithCompensationDetails(
    List<Claim> claims,
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

  /**
   * Stores the evaluation decision and possible reasoning to the claim object.
   */
  private void storeClaimDecision(List<EU261Claim> claimsToAutomate) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
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
          ' ' +
          ac.decision.caveats;
      } else {
        c.eu261HandlingNote = ac.decision.reasoning;
      }

      toUpsert.add(c);
    }

    Claims.newInstance(toUpsert).upsertToDB(uow);
    uow.commitWork();
  }

  /**
   * Processes all of the claims which we can settle, reject or automate
   * partially. Creates settlements, emails and prepares them and the claim and
   * case to updated in the DB.
   *
   * Splits claims into several groups based on the evaluation decision and
   * finalizes the processing accordingly.
   *
   * At this stage claims can be split into four different categories based on
   * what we want to do with them:
   * 1. Ones we want to pay out automatically
   * 2. Ones where customer appears to be eligible for payment but there are some caveats
   * 3. Ones we can reject automatically
   * 4. Ones where we cannot determine eligibility at all
   *
   * Claims in the first category we pay out directly, but some of these fall
   * to the approval queue for spot checks. Claims in the second category we
   * can send to a specific manual handling queue with instructions for the
   * agents on what they need to check before rejecting or sending the claim to
   * approval. Claims in the third category we can just close and email the
   * customer the result and claims in the fourth category we do nothing with
   * as they need to go to manual handling.
   */
  private void settleAndRejectClaims(List<EU261Claim> claimsToAutomate) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    ClaimService claimService = ClaimService.newInstance();

    List<EU261Claim> claimsToApproveAutomatically = new List<EU261Claim>();
    List<EU261Claim> claimsToManualApproval = new List<EU261Claim>();
    List<EU261Claim> claimsToReject = new List<EU261Claim>();
    List<EU261Claim> claimsToSemiAutomate = new List<EU261Claim>();

    List<Case> parentCasesForAutomaticApproval = new List<Case>();
    List<Case> parentCasesForManualApproval = new List<Case>();
    List<Case> parentCasesForInvalidSettlements = new List<Case>();
    List<Case> parentCasesForSemiAutomation = new List<Case>();
    List<Case> parentCasesForRejection = new List<Case>();

    List<Case> parentCasesForManualHandling = new List<Case>();

    for (EU261Claim c : claimsToAutomate) {
      switch on c.decision.verdict {
        when EligibleForCompensation {
          if (shouldApproveAutomatically(c)) {
            claimsToApproveAutomatically.add(c);
          } else {
            claimsToManualApproval.add(c);
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
        when else {
          // TODO: handle ReimbursementOnly separately
          parentCasesForManualHandling.add(
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
      } else {
        parentCasesForManualHandling.addAll(parentCasesForSemiAutomation);
      }

      Map<Id, List<Settlement__c>> settlementsByClaimId = createSettlementsForClaims(
        claimsWhichNeedSettlements
      );

      List<EU261Claim> invalidSettlementClaims = new List<EU261Claim>();
      List<EU261Claim> validatedManualHandlingClaims = new List<EU261Claim>();
      List<EU261Claim> validatedAutomaticApprovalClaims = new List<EU261Claim>();

      for (EU261Claim cl : claimsToManualApproval) {
        Integer numberOfSettlementsWithValidationErrors = Settlements.validateWithoutThrowing(
            settlementsByClaimId.get(cl.claimObj.id)
          )
          .keySet()
          .size();

        if (numberOfSettlementsWithValidationErrors > 0) {
          invalidSettlementClaims.add(cl);
          parentCasesForInvalidSettlements.add(
            parentCasesById.get(cl.claimObj.parentCaseId)
          );
        } else {
          validatedManualHandlingClaims.add(cl);
          parentCasesForManualApproval.add(
            parentCasesById.get(cl.claimObj.parentCaseId)
          );
        }
      }

      for (EU261Claim cl : claimsToApproveAutomatically) {
        Integer numberOfSettlementsWithValidationErrors = Settlements.validateWithoutThrowing(
            settlementsByClaimId.get(cl.claimObj.id)
          )
          .keySet()
          .size();

        if (numberOfSettlementsWithValidationErrors > 0) {
          invalidSettlementClaims.add(cl);
          parentCasesForInvalidSettlements.add(
            parentCasesById.get(cl.claimObj.parentCaseId)
          );
        } else {
          validatedAutomaticApprovalClaims.add(cl);
          parentCasesForAutomaticApproval.add(
            parentCasesById.get(cl.claimObj.parentCaseId)
          );
        }
      }

      if (validatedManualHandlingClaims.size() > 0) {
        List<Settlement__c> settlementsForManualApproval = new List<Settlement__c>();

        for (EU261Claim cl : validatedManualHandlingClaims) {
          settlementsForManualApproval.addAll(
            settlementsByClaimId.get(cl.claimObj.id)
          );
          parentCasesForManualApproval.add(
            parentCasesById.get(cl.claimObj.parentCaseId)
          );
        }

        uow.registerNew(
          createDraftApprovedEmails(
            validatedManualHandlingClaims,
            settlementsByClaimId
          )
        );

        Settlements.newInstance(settlementsForManualApproval)
          .validate()
          .submitToApproval(uow)
          .lock();

        Cases.newInstance(parentCasesForManualApproval).submitToApproval(uow);
      }

      if (validatedAutomaticApprovalClaims.size() > 0) {
        Cases.newInstance(parentCasesForAutomaticApproval)
          .emailContactPeople(
            createApprovedEmails(
              validatedAutomaticApprovalClaims,
              settlementsByClaimId
            ),
            uow
          )
          .close(uow);

        Claims.newInstance(
            EU261Claim.getClaimSObjectsFor(validatedAutomaticApprovalClaims)
          )
          .settle(uow);
      }

      if (invalidSettlementClaims.size() > 0) {
        // If automatically created settlements aren't valid, we can't fully
        // resolve these claims automatically. An agent needs to either fix the
        // payment details, or reach out to the customer to ask for new ones.
        Map<Id, String> handlingInstructionsByCaseId = new Map<Id, String>();
        for (Case c : parentCasesForInvalidSettlements) {
          handlingInstructionsByCaseId.put(
            c.Id,
            SEMI_AUTOMATION_REASON_TO_INSTRUCTIONS.get(
              EU261Claim.SemiAutomationReason.InvalidSettlementDetails
            )
          );
        }
        Cases.newInstance(parentCasesForInvalidSettlements)
          .setHandlingInstructions(uow, handlingInstructionsByCaseId)
          .routeToQueue(SEMI_AUTOMATION_QUEUE, uow);
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
            String.join(handlingInstructions, ' | ')
          );
        }

        Claims.newInstance(EU261Claim.getClaimSObjectsFor(claimsToSemiAutomate))
          .upsertToDB(uow);

        Cases.newInstance(parentCasesForSemiAutomation)
          .setHandlingInstructions(uow, handlingInstructionsByCaseId)
          .routeToQueue(SEMI_AUTOMATION_QUEUE, uow);
      }
    } else {
      for (EU261Claim c : claimsToApproveAutomatically) {
        parentCasesForManualHandling.add(
          parentCasesById.get(c.claimObj.parentCaseId)
        );
      }
      for (EU261Claim c : claimsToManualApproval) {
        parentCasesForManualHandling.add(
          parentCasesById.get(c.claimObj.parentCaseId)
        );
      }
    }

    if (this.config.enabledRejections && claimsToReject.size() > 0) {
      Cases.newInstance(parentCasesForRejection)
        .emailContactPeople(createRejectionEmails(claimsToReject), uow)
        .close(uow);
    } else {
      parentCasesForManualHandling.addAll(parentCasesForRejection);
    }

    if (parentCasesForManualHandling.size() > 0) {
      Cases.newInstance(parentCasesForManualHandling)
        .routeToQueue(MANUAL_HANDLING_QUEUE, uow);
    }

    uow.commitWork();
  }

  private Boolean shouldApproveAutomatically(EU261Claim cl) {
    return Math.random() * 100 >= this.config.percentageRequiringManualApproval;
  }

  /**
   * Creates settlements with settlement items for the given claims and inserts
   * them to the DB.
   *
   * Creates one or two settlements for each claim. If a claim has only
   * reimbursement or compensation this creates one settlement. If the claim
   * has both reimbursement and compensation, it creates two. We could combine
   * these into one settlement when the preferred compensation and
   * reimbursement methods are the same, but separating them out makes later
   * processing simpler.
   *
   * Does two DB inserts.
   *
   * @param claimsToPayOut A list of claims to be paid out. Must not include claims which shouldn't be settled.
   * @return A map from claim id to settlements for that claim. There can be one or two settlements per claim.
   */
  @TestVisible
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
  @TestVisible
  private List<EmailMessage> createDraftApprovedEmails(
    List<EU261Claim> claimsToApproval,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    List<EmailMessage> toReturn = new List<EmailMessage>();

    for (EU261Claim cl : claimsToApproval) {
      String templateName = AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME;
      if (cl.protocol.compensationIsHalved) {
        if (
          cl.protocol.minutesLateOnArrival >=
          cl.protocol.minutesEarlyOnDeparture * 2
        ) {
          templateName = AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME;
        } else {
          templateName = AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME;
        }
      }

      EmailMessage draftEmailForClaim = EmailMessages.createEmailMessageFromTemplate(
        templateName,
        cl.claimObj.parentCaseId
      );

      String compensationText;
      if (Test.isRunningTest()) {
        compensationText = 'placeholder';
      } else {
        compensationText = createCompesationText(
          settlementsByClaimId.get(cl.claimObj.id)
        );
      }

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

      injectVariables(draftEmailForClaim, cl);

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

  private static void injectVariables(EmailMessage email, EU261Claim cl) {
    Map<String, String> placeholderToValue = getVariables(cl);

    for (String placeholder : placeholderToValue.keySet()) {
      if (email.HtmlBody.contains(placeholder)) {
        email.HtmlBody = email.HtmlBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }

      if (email.TextBody != null && email.TextBody.contains(placeholder)) {
        email.TextBody = email.TextBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }
    }

    if (email.HtmlBody != null && email.HtmlBody.contains('|||')) {
      throw new EmailTemplateException('Email contains unsupported variables');
    }
  }

  private static void injectVariables(
    Messaging.SingleEmailMessage email,
    EU261Claim cl
  ) {
    Map<String, String> placeholderToValue = getVariables(cl);

    String htmlBody = email.getHtmlBody();
    String plainTextBody = email.getPlainTextBody();
    for (String placeholder : placeholderToValue.keySet()) {
      if (htmlBody.contains(placeholder)) {
        htmlBody = htmlBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }

      if (plainTextBody != null && plainTextBody.contains(placeholder)) {
        plainTextBody = plainTextBody.replace(
          placeholder,
          placeholderToValue.get(placeholder)
        );
      }
    }

    email.setHtmlBody(htmlBody);
    if (plainTextBody != null) {
      email.setPlainTextBody(plainTextBody);
    }

    if (email.HtmlBody != null && email.HtmlBody.contains('|||')) {
      throw new EmailTemplateException('Email contains unsupported variables');
    }
  }

  private static Map<String, String> getVariables(EU261Claim cl) {
    Flight f = cl.protocol.claimFlight;
    String flightPlan = cl.protocol.getFlightPlanHistory();
    String flightDate = StringUtils.dateToReadable(
      f.scheduledDepartureTime.date()
    );
    String flightNumber = f.tedsIdentifier.substring(0, 6);
    String flightDistanceKm = String.valueOf(cl.protocol.flightDistanceInKm);
    String departureAirport = f.departureAirport;
    String departureAirportName = f.departureAirportObject.name;
    String departureCountry = f.departureAirportObject.countryName;
    String departureTime = StringUtils.dateTimeToReadable(
      f.scheduledDepartureTime
    );
    String arrivalAirport = f.arrivalAirport;
    String arrivalAirportName = f.arrivalAirportObject.name;
    String arrivalCountry = f.arrivalAirportObject.countryName;
    String cancellationDate = StringUtils.dateToReadable(
      cl.protocol.irregularity.cancellationTime.date()
    );
    String cancellationTime = StringUtils.dateTimeToReadable(
      cl.protocol.irregularity.cancellationTime
    );
    String cancellationReason = cl.protocol.irregularity.getExplanation();
    String daysBetweenInformedAndDeparture = String.valueOf(
      cl.protocol.daysUntilFlightWhenInformedOfCancellation
    );
    String timeFrame = cl.protocol.daysUntilFlightWhenInformedOfCancellation <=
      7
      ? '1 hour early departure and 2 hours late arrival'
      : '2 hours early departure and 4 hours late arrival';
    String minutesDelayed = String.valueOf(cl.protocol.minutesLateOnArrival);
    String minutesEarly = String.valueOf(cl.protocol.minutesEarlyOnDeparture);

    // How the flight was cancelled, e.g. on the website
    String cancellationType = '|||NONE|||';
    String monthLimit = '|||NONE|||';
    if (cl.protocol.initialTrip != null) {
      Trip.CancellationTime cancellationInfo = cl.protocol.initialTrip.cancellationTimeInfo;
      cancellationType = SegmentEvent.getOfficeCodeExplanation(
        cancellationInfo.officeRemoving
      );
      monthLimit = String.valueOf(cl.getClaimFilingTimeLimitInMonths());
    }

    String tripDestinationArrivalType = departureCountry == arrivalCountry
      ? 'domestic trip within ' + departureCountry
      : 'trip between ' + departureCountry + ' and ' + arrivalCountry; // The reservation was for a ... trip between Sweden and USA, ... domestic trip within Sweden

    return new Map<String, String>{
      '|||flightPlan|||' => flightPlan,
      '|||flightNumber|||' => flightNumber,
      '|||flightDistanceKm|||' => flightDistanceKm,
      '|||flightDate|||' => flightDate,
      '|||departureAirport|||' => departureAirport,
      '|||departureTime|||' => departureTime,
      '|||arrivalAirport|||' => arrivalAirport,
      '|||cancellationDate|||' => cancellationDate,
      '|||cancellationTime|||' => cancellationTime,
      '|||cancellationType|||' => cancellationType,
      '|||cancellationReason|||' => cancellationReason,
      '|||daysBetweenInformedAndDeparture|||' => daysBetweenInformedAndDeparture,
      '|||timeFrame|||' => timeFrame,
      '|||monthLimit|||' => monthLimit,
      '|||tripDestinationArrivalType|||' => tripDestinationArrivalType,
      '|||minutesDelayed|||' => minutesDelayed,
      '|||minutesEarly|||' => minutesEarly
    };
  }

  /**
   * Creates emails for rejected claims which will be closed automatically.
   */
  @TestVisible
  private Map<Id, Messaging.SingleEmailMessage> createRejectionEmails(
    List<EU261Claim> claimsToReject
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToReject) {
      List<EmailMessage> toReturn = new List<EmailMessage>();

      String templateName = DENIAL_REASON_TO_EMAIL_TEMPLATE_NAME.get(
        c.protocol.denialReason
      );

      if (templateName == null) {
        throw new EmailMessages.EmailTemplateNameException(
          'Denial reason does not have an email template'
        );
      }

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
        c.claimObj.parentCaseId
      );

      injectVariables(emailToSend, c);

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
  @TestVisible
  private Map<Id, Messaging.SingleEmailMessage> createApprovedEmails(
    List<EU261Claim> claimsToSettle,
    Map<Id, List<Settlement__c>> settlementsByClaimId
  ) {
    Map<Id, Messaging.SingleEmailMessage> emailsByClaimId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToSettle) {
      String templateName = AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME;
      if (c.protocol.compensationIsHalved) {
        if (
          c.protocol.minutesLateOnArrival >=
          c.protocol.minutesEarlyOnDeparture * 2
        ) {
          templateName = AUTOMATION_APPROVED_HALVED_EARLY_DEPARTURE_EMAIL_TEMPLATE_NAME;
        } else {
          templateName = AUTOMATION_APPROVED_HALVED_LATE_ARRIVAL_EMAIL_TEMPLATE_NAME;
        }
      }

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
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

      injectVariables(emailToSend, c);

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

  @TestVisible
  private static String getSettlementAmount(Settlement__c s) {
    Id euroBonusRtId = Settlements.getRecordTypeId(
      Settlements.RecordType.EBPoints
    );

    if (s.RecordTypeId == euroBonusRtId) {
      return String.valueOf(s.EuroBonus_Points__c);
    } else {
      Decimal amount = s.Amount__c;
      return String.valueOf(amount.round(RoundingMode.FLOOR));
    }
  }
}
