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
  private static final String COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE = 'We will therefore reimburse you with a total amount of {0} {1}. Where {2} {1} is the flat rate compensation and {3} {1} Is the reimbursement for the expenses you experienced during the delay.';

  @TestVisible
  private Decimal percentageRequiringManualApproval;

  @TestVisible
  private Boolean enabledSettlements;

  @TestVisible
  private Boolean enabledRejections;

  private Map<Id, Case> parentCasesById = new Map<Id, Case>();
  private Map<Id, Settlement__c> existingSettlementsByClaimId = new Map<Id, Settlement__c>();

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
        Percentage_Sent_to_Control__c
      FROM EU261_Automation_Configuration__mdt
      WHERE Label = 'Default'
    ];

    if (automationConfig == null || automationConfig.size() == 0) {
      this.enabledRejections = false;
      this.enabledSettlements = false;
    } else {
      EU261_Automation_Configuration__mdt config = automationConfig[0];
      this.enabledRejections = config.Automatic_Rejection__c == null
        ? false
        : config.Automatic_Rejection__c;
      this.enabledSettlements = config.Automatic_Settlement__c == null
        ? false
        : config.Automatic_Settlement__c;
      this.percentageRequiringManualApproval = config.Percentage_Sent_to_Control__c ==
        null
        ? 0
        : config.Percentage_Sent_to_Control__c;
    }
  }

  public class AutomationException extends Exception {
  }

  public void processEU261Claims(Set<Id> claimIds) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    this.automateEU261Claims(claimIds, uow);
    uow.commitWork();
  }

  public void batchProcessEU261Claims(Set<Id> claimIds) {
    List<Id> claimIdsOdered = new List<Id>(claimIds);
    Integer claimsRemaining = claimIdsOdered.size();
    while (claimsRemaining > 0) {
      if (claimsRemaining > 100) {
        // 200 is too much
        List<Id> notAllClaimIds = new List<Id>{};
        for (Integer i = 0; i < 100; i++) {
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
  private List<EU261Claim> automateEU261Claims(
    Set<Id> claimIds,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<EU261Claim> claimsToAutomate = gatherAllNecessaryInformation(claimIds);

    for (EU261Claim c : claimsToAutomate) {
      c.evaluate();
    }

    storeClaimDecision(uow, claimsToAutomate);

    settleAndRejectClaims(uow, claimsToAutomate);

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
      enabledSettlements &&
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
    for (Booking__c b : allBookingsFoundInClaims) {
      for (Segment__c s : b.Segments__r) {
        allTEDSFlightIds.add(s.Flight__r.TEDS_Identifier__c);
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

    return constructClaimWithCompensationDetails(
      claims,
      countryToClaimSubmissionTimeLimit,
      otherClaimsWithMatchingPnrs,
      caseIdToCaseToBookings,
      bookingsById,
      flightIrregularities,
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
          b.setAirports(airportCodeToAirportObjects);
        }
      }

      EU261Claim fullClaim = new EU261Claim(
        c,
        booking.objects,
        hasPotentiallyDuplicateClaims
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
          ac.decision.compensationPerCustomer.values() +
          ' | Reimbursement: ' +
          ac.decision.reimbursementAmount;
      } else if (
        ac.decision.verdict ==
        Claim.EU261HandlingStatus.PossiblyEligibleForCompensation
      ) {
        c.eu261HandlingNote =
          'Compensation: ' +
          ac.decision.compensationPerCustomer.values() +
          ' | Reimbursement: ' +
          ac.decision.reimbursementAmount +
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

  private List<EU261Claim> settleAndRejectClaims(
    fflib_ISObjectUnitOfWork uow,
    List<EU261Claim> claimsToAutomate
  ) {
    ClaimService claimService = ClaimService.newInstance();

    List<EU261Claim> claimsToPayOut = new List<EU261Claim>();
    List<EU261Claim> claimsToReject = new List<EU261Claim>();
    Set<Id> claimsToRejectIds = new Set<Id>();

    for (EU261Claim c : claimsToAutomate) {
      if (
        c.decision.verdict == Claim.EU261HandlingStatus.EligibleForCompensation
      ) {
        claimsToPayOut.add(c);
      } else if (
        c.decision.verdict ==
        Claim.EU261HandlingStatus.IneligibleForCompensation
      ) {
        claimsToRejectIds.add(c.claimObj.id);
        claimsToReject.add(c);
      }
    }

    if (enabledSettlements) {
      Map<Id, Settlement__c> settlementsByClaimId = createSettlementsForClaims(
        claimsToPayOut
      );

      List<EU261Claim> automaticallyApprovedClaims = new List<EU261Claim>();
      List<EU261Claim> manualApprovalClaims = new List<EU261Claim>();
      Set<Id> manualApprovalClaimIds = new Set<Id>();
      Set<Id> automaticallyApprovedClaimIds = new Set<Id>();

      for (EU261Claim cl : claimsToPayOut) {
        if (shouldApproveAutomatically(cl)) {
          automaticallyApprovedClaims.add(cl);
          automaticallyApprovedClaimIds.add(cl.claimObj.id);
        } else {
          manualApprovalClaims.add(cl);
          manualApprovalClaimIds.add(cl.claimObj.id);
        }
      }

      if (manualApprovalClaimIds.size() > 0) {
        claimService.submitClaimsToApproval(
          uow,
          manualApprovalClaimIds,
          createDraftApprovedEmails(manualApprovalClaims, settlementsByClaimId)
        );
      }

      if (automaticallyApprovedClaimIds.size() > 0) {
        claimService.settleClaims(
          uow,
          automaticallyApprovedClaimIds,
          createApprovedEmails(
            automaticallyApprovedClaims,
            settlementsByClaimId
          )
        );
      }
    }

    if (enabledRejections && claimsToRejectIds.size() > 0) {
      claimService.rejectClaims(
        uow,
        claimsToRejectIds,
        createRejectionEmails(claimsToReject)
      );
    }

    return claimsToAutomate;
  }

  private Boolean shouldApproveAutomatically(EU261Claim cl) {
    return Math.random() * 100 >= percentageRequiringManualApproval;
  }

  /**
   * Does two DB inserts.
   *
   * @return A map from claim id to settlement for that claim.
   */
  private Map<Id, Settlement__c> createSettlementsForClaims(
    List<EU261Claim> claimsToPayOut
  ) {
    Map<Id, List<SettlementItem>> settlementsItemsBySettlementId = new Map<Id, List<SettlementItem>>();
    Map<String, Exchange_Rate__c> exchangeRatesByToCurrency = new Map<String, Exchange_Rate__c>();

    List<LIA_Claim__c> payableClaimSObjects = new List<LIA_Claim__c>();

    for (EU261Claim c : claimsToPayOut) {
      payableClaimSObjects.add(c.claimObj.underlyingSObject);
    }

    for (
      Exchange_Rate__c er : ExchangeRatesSelector.newInstance()
        .selectByFromCurrency('EUR')
    ) {
      exchangeRatesByToCurrency.put(er.To_Currency__c, er);
    }

    fflib_ISObjectUnitOfWork uow1 = SAS_Service_Application.UnitOfWork.newInstance();
    Settlements s = Settlements.createFromClaim(
      payableClaimSObjects,
      null,
      uow1
    );
    uow1.commitWork();

    for (EU261Claim c : claimsToPayOut) {
      List<SettlementItem> settlementsItemsForClaim = new List<SettlementItem>();
      Settlement__c settlementForClaim;
      for (Settlement__c ss : s.instanceRecords) {
        if (ss.Claim__c == c.claimObj.id) {
          settlementForClaim = ss;
          break;
        }
      }

      for (
        ClaimCustomer customer : c.decision.compensationPerCustomer.keySet()
      ) {
        SettlementItem si = new SettlementItem();
        si.customerName = customer.fullName;
        si.costAccount = COMPENSATION_COST_ACCOUNT;
        si.comments = 'Automatic EU261 compensation';
        si.recordType = SettlementItem.RecordType.DefaultRecordType;
        settlementsItemsForClaim.add(si);

        switch on c.claimObj.preferredCompensationMethod {
          when EBPoints {
            si.amount =
              c.decision.compensationPerCustomer.get(customer) *
              Settlements.CONVERSION_RATE_EUR_TO_EB_POINTS;
          }
          when Voucher {
            si.amount =
              c.decision.compensationPerCustomer.get(customer) *
              Settlements.CONVERSION_RATE_EUR_TO_VOUCHER_EUR;
          }
          when else {
            // Default to monetary
            Decimal rate = 1.0; // EUR-EUR
            if (settlementForClaim.Currency__c != 'EUR') {
              Exchange_Rate__c exchangeRateObj = exchangeRatesByToCurrency.get(
                settlementForClaim.Currency__c
              );
              if (exchangeRateObj == null) {
                throw new AutomationException('Cannot find exchange rate.');
              } else {
                rate = exchangeRateObj.Rate__c;
              }
            }

            Decimal amount =
              c.decision.compensationPerCustomer.get(customer) * rate;
            si.amount = amount.setScale(0);
          }
        }
      }
      /*if (
        c.decision.reimbursementAmount != null &&
        c.decision.reimbursementAmount > 0
      ) { // TODO: This needs to support creating a separate settlement in case we need to make a reimbusement
        SettlementItem si = new SettlementItem();
        si.customerName = c.claimObj.contactFullName;
        si.costAccount = REIMBURSEMENT_COST_ACCOUNT;
        si.amount = c.decision.reimbursementAmount; // TODO: Currency conversion!
        si.comments = 'Automatic EU261 reimbursement';
        settlementsItemsForClaim.add(si);
      }*/
      settlementsItemsBySettlementId.put(
        settlementForClaim.Id,
        settlementsItemsForClaim
      );
    }

    fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
    s.updateSettlementItems(settlementsItemsBySettlementId, uow2);
    uow2.commitWork();

    Map<Id, Settlement__c> settlementsByClaimId = new Map<Id, Settlement__c>();

    for (Settlement__c ss : s.instanceRecords) {
      settlementsByClaimId.put(ss.Claim__c, ss);
    }

    return settlementsByClaimId;
  }

  private List<EmailMessage> createDraftApprovedEmails(
    List<EU261Claim> claimsToApproval,
    Map<Id, Settlement__c> settlementsByClaimId
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

      emailsByClaimId.put(c.claimObj.id, emailToSend);
    }

    return emailsByClaimId;
  }

  private Map<Id, Messaging.SingleEmailMessage> createApprovedEmails(
    List<EU261Claim> claimsToSettle,
    Map<Id, Settlement__c> settlementsByClaimId
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

      emailsByClaimId.put(c.claimObj.id, emailToSend);
    }

    return emailsByClaimId;
  }

  private String createCompesationText(Settlement__c settlementForClaim) {
    Decimal compensationAmount = settlementForClaim.Amount__c;
    // Decimal reimbursementAmount = 0;
    String settlementCurrency = settlementForClaim.Currency__c;
    String compensationText;
    // if (reimbursementAmount == 0) {
    List<Object> parameters = new List<Object>{
      compensationAmount,
      settlementCurrency
    };
    compensationText = String.format(
      COMPENSATION_WITHOUT_REIMBURSEMENT_TEXT_TEMPLATE,
      parameters
    );
    /*} else {
      List<Object> parameters = new List<Object>{
        compensationAmount,
        reimbursementAmount,
        settlementCurrency
      };
      compensationText = String.format(
        COMPENSATION_WITH_REIMBURSEMENT_TEXT_TEMPLATE,
        parameters
      );
    }*/
    return compensationText;
  }
}
