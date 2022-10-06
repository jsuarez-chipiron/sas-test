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

  public static EU261Service newInstance() {
    return (EU261Service) SAS_Service_Application.Service.newInstance(
      EU261Service.class
    );
  }

  public void processEU261Claims(Set<Id> claimIds) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    this.automateEU261Claims(claimIds, uow);
    uow.commitWork();
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

    storeClaimResolution(claimsToAutomate, uow);

    /**
     * TODO: Enable when we can create settlements.
        List<EU261Claim> claimsToPayOut = new List<EU261Claim>();
        for (EU261Claim c : claimsToAutomate) {
          if (c.decision.verdict == Claim.EU261HandlingStatus.EligibleForCompensation) {
            claimsToPayOut.add(c);
          }
        }
        settleClaims(claimsToPayOut, uow);
        // TODO: Send approval emails
     */

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

    // 4. Map cases to bookings and get bookings
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
      airportCodeToAirport
    );
  }

  private static List<EU261Claim> constructClaimWithCompensationDetails(
    List<Claim> claims,
    Map<String, Decimal> countryToClaimSubmissionTimeLimit,
    List<Claim> otherClaimsWithMatchingPnrs,
    Map<Id, List<CaseToBooking__c>> caseIdToCaseToBookings,
    Map<Id, Booking__c> bookingsById,
    List<FlightIrregularities__c> flightIrregularities,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    List<EU261Claim> toReturn = new List<EU261Claim>{};

    FlightIrregularities irregularities = new FlightIrregularities(
      flightIrregularities
    );
    irregularities.removeNA0Delay(); // Remove irrelevant irregularities
    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities = irregularities.getFlightIdToIrregularities();

    for (Claim c : claims) {
      List<Booking__c> bookingsForClaim = new List<Booking__c>();
      for (CaseToBooking__c ctb : caseIdToCaseToBookings.get(c.parentCaseId)) {
        // TODO: Fix this can be null.
        Booking__c booking = bookingsById.get(ctb.Booking__c);
        if (booking != null) {
          bookingsForClaim.add(booking);
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

      Map<Id, List<FlightIrregularities__c>> claimSpecificIrregularities = new Map<Id, List<FlightIrregularities__c>>{};
      if (booking.instanceRecords.size() > 0) {
        for (Segment__c s : booking.instanceRecords[0].Segments__r) {
          List<FlightIrregularities__c> flightIrreg = flightIdToIrregularities.get(
            s.Flight__c
          );
          if (flightIrreg == null) {
            flightIrreg = new List<FlightIrregularities__c>{};
          }
          claimSpecificIrregularities.put(s.Flight__c, flightIrreg);
        }
      }

      EU261Claim fullClaim = new EU261Claim(
        c,
        booking,
        claimSpecificIrregularities,
        hasPotentiallyDuplicateClaims,
        airportCodeToAirport
      );

      toReturn.add(fullClaim);
    }

    return toReturn;
  }

  private static void storeClaimResolution(
    List<EU261Claim> claimsToAutomate,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (EU261Claim ac : claimsToAutomate) {
      Claim c = ac.claimObj.objects[0];

      c.eu261HandlingStatus = ac.decision.verdict;

      if (
        ac.decision.verdict == Claim.EU261HandlingStatus.EligibleForCompensation
      ) {
        c.eu261HandlingNote =
          'Compensation: ' +
          ac.decision.compensationAmount +
          ' | Reimbursement: ' +
          ac.decision.reimbursementAmount;
      } else {
        c.eu261HandlingNote = ac.decision.reasoning;
      }

      ac.claimObj.upsertToDB(uow);
    }
  }

  /**
   * Settle the claims which can be settled. For the time being just adds description of
   * what was processed.
   */
  /*private static void settleClaims(
    List<EU261Claim> claimsToPayOut,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (EU261Claim c : claimsToPayOut) {
      List<SettlementItem> settlementsItemsForDecision = new List<SettlementItem>();
      for (
        ClaimCustomer customer : c.decision.compensationPerCustomer.keySet()
      ) {
        settlementsItemsForDecision.add(
          new SettlementItem(
            customer,
            COMPENSATION_COST_ACCOUNT,
            c.decision.compensationPerCustomer.get(customer),
            'Automatic EU261 compensation'
          )
        );
      }
      if (
        c.decision.reimbursementAmount != null &&
        c.decision.reimbursementAmount > 0
      ) {
        settlementsItemsForDecision.add(
          new SettlementItem(
            c.claimObj.objects[0].contactFullName,
            REIMBURSEMENT_COST_ACCOUNT,
            c.decision.compensationPerCustomer.get(c.claimObj.objects[0].contactFullName),
            'Automatic EU261 reimbursement'
          )
        );
      }
      Settlements s = Settlements.createFromSettlementItems(
        c.claimObj,
        settlementsItemsForDecision,
        uow
      );
      // claim.claim.settle(uow);
    }
  }*/

  /*private static void debugResult(
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
  }*/
}
