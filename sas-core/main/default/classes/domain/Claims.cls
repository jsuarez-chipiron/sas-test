public without sharing class Claims extends fflib_SObjectDomain {
  public Claims(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<LIA_Claim__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Claims(records);
    }
  }

  public static Claims newInstance(List<LIA_Claim__c> sObjectList) {
    return (Claims) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public List<LIA_Claim__c> instanceRecords;

  public enum RecordType {
    CompensationCard,
    CustomerClaim,
    LiabilityClaim
  }

  public enum Category {
    AccidentAndInjury,
    AirportExperience,
    Baggage,
    Booking,
    FlightDisruptions,
    FlightExperience,
    Other,
    PassengerIrregularities,
    TravelExtras
  }

  public enum Priority {
    Medium,
    High,
    Pandion,
    HighCareCosts
  }

  public static Map<String, Category> categoryNameToEnum = new Map<String, Category>{
    'Accident &amp; injury' => Category.AccidentAndInjury,
    'Airport experience' => Category.AirportExperience,
    'Baggage' => Category.Baggage,
    'Booking' => Category.Booking,
    'Flight disruptions' => Category.FlightDisruptions,
    'Flight experience' => Category.FlightExperience,
    'Other' => Category.Other,
    'Passenger irregularities' => Category.PassengerIrregularities,
    'Travel extras bought not rendered' => Category.TravelExtras
  };

  public static Map<RecordType, String> recordTypeToDeveloperName = new Map<RecordType, String>{
    RecordType.CompensationCard => 'CompensationCard',
    RecordType.CustomerClaim => 'CustomerClaim',
    RecordType.LiabilityClaim => 'LiabilityClaim'
  };

  public static Map<Priority, String> priorityToName = new Map<Priority, String>{
    Priority.Medium => 'Medium',
    Priority.High => 'High',
    Priority.Pandion => 'Pandion',
    Priority.HighCareCosts => 'High Care Costs'
  };

  private static Map<RecordType, Id> recordTypeToId = new Map<RecordType, String>();

  public static Id getRecordTypeId(RecordType rt) {
    Id rtId = recordTypeToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.LIA_Claim__c.getRecordTypeInfosByName()
        .get(recordTypeToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeToId.put(rt, rtId);
    }
    return rtId;
  }

  public override void onAfterInsert() {
    checkIfExistsInCARE();
    assignToQueueUsingFlow();
    updateParentCaseBookings();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    checkIfExistsInCARE((Map<Id, LIA_Claim__c>) existingRecords);
    updateParentCaseBookings((Map<Id, LIA_Claim__c>) existingRecords);
    // TODO: We should also update EB accounts correctly. Requires fixing of the entire EB accounts fetching flow.
  }

  public override void onBeforeInsert() {
    normalizeFields();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    clearClaimInCareField();
    normalizeFields();
  }

  /**
   * A claim can be prorated if it is a baggage claim and has at least one
   * leg with an operating carrier which is not a part of Star Alliance. It
   * must also have at least one paid out settlement.
   *
   * Proration of a claim is splitting costs related to a baggage claim between
   * the airlines in the booking the claims is about. See Confluence for more
   * details.
   *
   * @return A map from claim id to whether that claim can be prorated.
   */
  public Map<Id, Boolean> canBeProrated() {
    Set<Id> parentCaseIds = new Set<Id>();
    for (LIA_Claim__c claim : instanceRecords) {
      Boolean isABaggageCaseWithSettlements =
        categoryNameToEnum.get(claim.Customer_Claim_Category__c) ==
        Category.Baggage &&
        claim.Settlements__r != null &&
        !claim.Settlements__r.isEmpty();

      if (isABaggageCaseWithSettlements) {
        parentCaseIds.add(claim.Case__c);
      }
    }

    Map<Id, Boolean> bookingIdsToProrationStatus = new Map<Id, Boolean>();
    List<Booking__c> bookingsForInstanceClaims = new List<Booking__c>();

    if (parentCaseIds.size() > 0) {
      bookingsForInstanceClaims = BookingsSelector.newInstance()
        .selectByCaseId(parentCaseIds);

      // Claim can potentially be prorated if the booking it is about
      // has an operating carrier which is not a part of Star Alliance.
      bookingIdsToProrationStatus = Bookings.newInstance(
          bookingsForInstanceClaims
        )
        .haveNonStarAllianceOperatingCarriers();
    }

    Map<Id, Boolean> claimIdsToProrationStatus = new Map<Id, Boolean>();

    for (LIA_Claim__c claim : instanceRecords) {
      claimIdsToProrationStatus.put(claim.Id, false);
      if (
        categoryNameToEnum.get(claim.Customer_Claim_Category__c) ==
        Category.Baggage
      ) {
        for (Booking__c booking : bookingsForInstanceClaims) {
          if (booking.Booking_Reference__c == claim.Liability_PNR__c) {
            claimIdsToProrationStatus.put(
              claim.Id,
              bookingIdsToProrationStatus.get(booking.Id)
            );
            break;
          }
        }
      }
    }

    return claimIdsToProrationStatus;
  }

  /**
   * Settles the given instance claims. The claims will be approved
   * automatically and skip control.
   *
   * Settlements must already exist for the claims for this to succeed.
   *
   * If settling fails, sets the settlements as failed and keeps the case in
   * progress.
   */
  public Claims settle(fflib_ISObjectUnitOfWork uow) {
    List<Settlement__c> settlementsForClaims = SettlementsSelector.newInstance()
      .selectByClaimId((new Map<Id, LIA_Claim__c>(instanceRecords)).keySet());

    Set<Id> caseIds = new Set<Id>();
    for (LIA_Claim__c claim : instanceRecords) {
      caseIds.add(claim.Case__c);
    }
    List<Case> casesForClaims = CasesSelector.newInstance().selectById(caseIds);

    Settlements.newInstance(settlementsForClaims)
      .validate()
      .approve(uow)
      .lock();

    return this;
  }

  public Claims createFromCompensationCardForm(CaseFormJSON2Apex formData) {
    List<LIA_Claim__c> claimsToCreate = new List<LIA_Claim__c>();

    LIA_Claim__c newClaim = new LIA_Claim__c();

    return newInstance(new List<LIA_Claim__c>{ newClaim });
  }

  public void assignToQueueUsingFlow() {
    //Assign one Claim at a time
    if (instanceRecords.size() > 1) {
      return;
    }
    LIA_Claim__c lc = instanceRecords[0];
    if (lc.RecordTypeId == getRecordTypeId(RecordType.CustomerClaim)) {
      Map<String, Object> inputs = new Map<String, Object>();
      inputs.put('recordId', lc.Id);

      Flow.Interview.CLAIM_Route_Case_to_Queue claimRoutingFlow = new Flow.Interview.CLAIM_Route_Case_to_Queue(
        inputs
      );
      claimRoutingFlow.start();
    }
  }

  private void checkIfExistsInCARE(Map<Id, LIA_Claim__c> existingRecords) {
    for (LIA_Claim__c claim : instanceRecords) {
      if (claim.Liability_PNR__c != null) {
        Boolean shouldCheckEDW =
          existingRecords.get(claim.Id).Liability_PNR__c !=
          claim.Liability_PNR__c;
        if (shouldCheckEDW) {
          EventBus.publish(
            new Fetch_CARE_Data__e(
              Claim_Id__c = claim.Id,
              Booking_Reference__c = claim.Liability_PNR__c
            )
          );
        }
      }
    }
  }

  private void checkIfExistsInCARE() {
    for (LIA_Claim__c claim : instanceRecords) {
      if (claim.Liability_PNR__c != null) {
        EventBus.publish(
          new Fetch_CARE_Data__e(
            Claim_Id__c = claim.Id,
            Booking_Reference__c = claim.Liability_PNR__c
          )
        );
      }
    }
  }

  private void clearClaimInCareField() {
    for (LIA_Claim__c claim : instanceRecords) {
      if (claim.Liability_PNR__c == null) {
        claim.Claims_Exist_In_CARE_For_PNR__c = false;
      }
    }
  }

  private void updateParentCaseBookings() {
    if (instanceRecords.size() == 1) {
      LIA_Claim__c claim = instanceRecords[0];
      // TODO: Fix this when we can support several bookings at once
      if (
        claim.Liability_PNR__c != null &&
        claim.RecordTypeId != getRecordTypeId(RecordType.CompensationCard) &&
        claim.Case__c != null
      ) {
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            claim.Case__c,
            claim.Liability_PNR__c
          )
        );
      }
    }
  }

  private void updateParentCaseBookings(Map<Id, LIA_Claim__c> existingRecords) {
    if (instanceRecords.size() == 1) {
      LIA_Claim__c claim = instanceRecords[0];
      // TODO: Fix this when we can support several bookings at once
      if (
        claim.Liability_PNR__c != null &&
        existingRecords.get(claim.Id).Liability_PNR__c !=
        claim.Liability_PNR__c &&
        claim.RecordTypeId != getRecordTypeId(RecordType.CompensationCard)
      ) {
        BookingService.removeBookingFromCase(
          claim.Case__c,
          existingRecords.get(claim.Id).Liability_PNR__c
        );
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            claim.Case__c,
            claim.Liability_PNR__c
          )
        );
      }
    }
  }

  private void normalizeFields() {
    for (LIA_Claim__c claim : instanceRecords) {
      if (!String.isBlank(claim.Liability_PNR__c)) {
        claim.Liability_PNR__c = StringUtils.removeWhitespace(
          claim.Liability_PNR__c.toUpperCase()
        );
      }
      if (!String.isBlank(claim.BIC_Swift__c)) {
        claim.BIC_Swift__c = StringUtils.removeWhitespace(
          claim.BIC_Swift__c.toUpperCase()
        );
      }
      if (!String.isBlank(claim.Bank_Account_Number__c)) {
        claim.Bank_Account_Number__c = StringUtils.removeWhitespace(
          claim.Bank_Account_Number__c.toUpperCase()
        );
      }
      if (!String.isBlank(claim.Flight_Number__c)) {
        claim.Flight_Number__c = StringUtils.removeWhitespace(
          claim.Flight_Number__c.toUpperCase()
        );
      }
    }
  }

  /*
   * Returns the priority of the case depending of EB level and level of costs.
   * Todo: this could be moved to the cases domain depending on how we rewrite the routing.
   */
  public List<Priority> getPriority() {
    List<Priority> toReturn = new List<Priority>{};

    Set<Id> caseIds = new Set<Id>();
    for (LIA_Claim__c claim : instanceRecords) {
      caseIds.add(claim.Case__c);
    }
    List<Case> casesForClaims = CasesSelector.newInstance().selectById(caseIds);

    Map<Id, Case> claimIdToCase = new Map<Id, Case>{};

    for (Case c : casesForClaims) {
      claimIdToCase.put(c.LIA_Claim__c, c);
    }

    for (LIA_Claim__c claim : instanceRecords) {
      Case c = claimIdToCase.get(claim.Id);
      Priority casePriority = Priority.Medium;

      switch on c.FCS_EBLevel__c {
        when 'P' {
          toReturn.add(Priority.Pandion);
          continue;
        }
        when 'D', 'G' {
          casePriority = Priority.High;
        }
      }

      if (claim.Submitted_Claim_Expenses_in_SEK__c > 25000) {
        casePriority = Priority.HighCareCosts;
      }

      toReturn.add(casePriority);
    }

    return toReturn;
  }
}
