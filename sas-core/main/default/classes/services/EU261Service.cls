/**
 * @param claim a LIA_Claim__c to be automated
 * @param booking a BookingJSON associated with the claim
 *
 * Service class which handles case/claim automation
 * Contains all information needed (not currently) to automate a claim.
 *
 * WARNING: The automation is currently built with the assumption that there is exactly one flight per claim.
 * This can relatively easily be changed, but keep it in mind before allowing more than one flight in a claim.
 */
public without sharing class EU261Service {
  private static final SettlementItem.CostAccount COMPENSATION_COST_ACCOUNT = SettlementItem.CostAccount.CA6727;
  private static final SettlementItem.CostAccount REIMBURSEMENT_COST_ACCOUNT = SettlementItem.CostAccount.CA6738;

  @TestVisible
  private static final String AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME = 'eu261_automation_approved';
  @TestVisible
  private static final String AUTOMATION_REJECTED_EMAIL_TEMPLATE_NAME = 'eu261_automation_rejected';
  private static final String AUTOMATION_REPLY_TO_ADDRESS = 'test@example.com';

  @TestVisible
  private Boolean enabledSettlements;

  @TestVisible
  private Boolean enabledRejections;

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
        Claim_Expense_Max_Amount__c
      FROM EU261_Automation_Configuration__mdt
      WHERE Label = 'Default'
    ];

    if (automationConfig == null || automationConfig.size() == 0) {
      this.enabledRejections = false;
      this.enabledSettlements = false;
    } else {
      this.enabledRejections = automationConfig[0].Automatic_Rejection__c ==
        null
        ? false
        : automationConfig[0].Automatic_Rejection__c;
      this.enabledSettlements = automationConfig[0].Automatic_Settlement__c ==
        null
        ? false
        : automationConfig[0].Automatic_Settlement__c;
    }
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

    storeClaimDecision(claimsToAutomate, uow);

    // TODO: Enable when we can create settlements.
    List<EU261Claim> claimsToPayOut = new List<EU261Claim>();
    for (EU261Claim c : claimsToAutomate) {
      if (
        c.decision.verdict == Claim.EU261HandlingStatus.EligibleForCompensation
      ) {
        claimsToPayOut.add(c);
      }
    }

    if (enabledSettlements) {
      createSettlementsForClaims(claimsToPayOut);
    }

    if (enabledSettlements || enabledRejections) {
      settleAndRejectClaims(claimsToPayOut, uow);
    }

    /**
     * TODO: Enable when we can send out rejection emails.
     *
     */

    // debugResult(claimsToAutomate);

    return claimsToAutomate;

    // TODO: Log out some details about how many were handled.
  }

  /**
   * @param claims a list of claims for which to find information.
   *
   * @return a list of ClaimWithCompensationDetails containing all information necessary to automate the claim.
   */
  private static List<EU261Claim> gatherAllNecessaryInformation(
    Set<Id> claimIds
  ) {
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

  private static List<EU261Claim> constructClaimWithCompensationDetails(
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

      Boolean foundMultipleMatchingBookings =
        booking.instanceRecords.size() > 1;

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

  private static void storeClaimDecision(
    List<EU261Claim> claimsToAutomate,
    fflib_ISObjectUnitOfWork uow
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

  /**
   * Does two DB inserts.
   */
  private static Settlements createSettlementsForClaims(
    List<EU261Claim> claimsToPayOut
  ) {
    Map<Id, List<SettlementItem>> settlementsItemsByClaimId = new Map<Id, List<SettlementItem>>();

    List<LIA_Claim__c> payableClaimSObjects = new List<LIA_Claim__c>();

    for (EU261Claim c : claimsToPayOut) {
      List<SettlementItem> settlementsItemsForClaim = new List<SettlementItem>();
      for (
        ClaimCustomer customer : c.decision.compensationPerCustomer.keySet()
      ) {
        SettlementItem si = new SettlementItem();
        si.customerName = customer.fullName;
        si.costAccount = COMPENSATION_COST_ACCOUNT;
        si.amount = c.decision.compensationPerCustomer.get(customer);
        si.comments = 'Automatic EU261 compensation';
        settlementsItemsForClaim.add(si);
      }
      if (
        c.decision.reimbursementAmount != null &&
        c.decision.reimbursementAmount > 0
      ) {
        SettlementItem si = new SettlementItem();
        si.customerName = c.claimObj.contactFullName;
        si.costAccount = REIMBURSEMENT_COST_ACCOUNT;
        si.amount = c.decision.reimbursementAmount;
        si.comments = 'Automatic EU261 reimbursement';
        settlementsItemsForClaim.add(si);
      }
      settlementsItemsByClaimId.put(c.claimObj.id, settlementsItemsForClaim);
      payableClaimSObjects.add(c.claimObj.underlyingSObject);
    }

    fflib_ISObjectUnitOfWork uow1 = SAS_Service_Application.UnitOfWork.newInstance();

    Settlements s = Settlements.createFromClaim(
      payableClaimSObjects,
      null,
      uow1
    );
    uow1.commitWork();

    Map<Id, List<SettlementItem>> settlementsItemsBySettlementId = new Map<Id, List<SettlementItem>>();

    for (Settlement__c singleSettlement : s.instanceRecords) {
      settlementsItemsBySettlementId.put(
        singleSettlement.Id,
        settlementsItemsByClaimId.get(singleSettlement.Claim__c)
      );
    }

    fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
    s.updateSettlementItems(settlementsItemsBySettlementId, uow2);
    uow2.commitWork();

    return s;
  }

  private void settleAndRejectClaims(
    List<EU261Claim> claimsToRejectAndSettle,
    fflib_ISObjectUnitOfWork uow
  ) {
    Set<Id> parentCaseIds = new Set<Id>();
    for (EU261Claim c : claimsToRejectAndSettle) {
      parentCaseIds.add(c.claimObj.parentCaseId);
    }
    Cases parentCases = Cases.newInstance(
      CasesSelector.newInstance().selectById(parentCaseIds)
    );

    Map<Id, Messaging.SingleEmailMessage> emailsByCaseId = new Map<Id, Messaging.SingleEmailMessage>();

    for (EU261Claim c : claimsToRejectAndSettle) {
      if (
        !enabledRejections &&
        c.decision.verdict ==
        Claim.EU261HandlingStatus.IneligibleForCompensation
      ) {
        continue;
      }
      if (
        !enabledSettlements &&
        c.decision.verdict == Claim.EU261HandlingStatus.EligibleForCompensation
      ) {
        continue;
      }

      String templateName = c.decision.verdict ==
        Claim.EU261HandlingStatus.EligibleForCompensation
        ? AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME
        : AUTOMATION_REJECTED_EMAIL_TEMPLATE_NAME;

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        templateName,
        c.claimObj.parentCaseId
      );
      emailToSend.setReplyTo(AUTOMATION_REPLY_TO_ADDRESS);

      emailsByCaseId.put(c.claimObj.parentCaseId, emailToSend);
    }

    parentCases.emailContactPeople(emailsByCaseId, uow).close(uow);
  }
}
