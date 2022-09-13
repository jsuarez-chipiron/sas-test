public without sharing class Claims extends fflib_SObjectDomain {
  public Claims(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();

    this.instanceRecords = (List<LIA_Claim__c>) Records;

    List<Claim> claimObjects = new List<Claim>();
    for (LIA_Claim__c c : this.instanceRecords) {
      claimObjects.add(new Claim(c));
    }

    this.objects = claimObjects;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Claims(records);
    }
  }

  public static Claims newInstance(List<LIA_Claim__c> sObjectList) {
    return (Claims) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public List<Claim> objects;

  public List<LIA_Claim__c> instanceRecords;

  public override void onAfterInsert() {
    checkIfExistsInCARE();
    fetchCAREClaims();
    updateParentCaseBookings();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    checkIfExistsInCARE((Map<Id, LIA_Claim__c>) existingRecords);
    fetchCAREClaims((Map<Id, LIA_Claim__c>) existingRecords);
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
    for (Claim cl : objects) {
      Boolean isABaggageCaseWithSettlements =
        cl.category == Claim.Category.Baggage &&
        !cl.underlyingSObject.Settlements__r.isEmpty();

      if (isABaggageCaseWithSettlements) {
        parentCaseIds.add(cl.parentCaseId);
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

    for (Claim cl : objects) {
      claimIdsToProrationStatus.put(cl.underlyingSObject.Id, false);
      if (cl.category == Claim.Category.Baggage) {
        for (Booking__c booking : bookingsForInstanceClaims) {
          if (booking.Booking_Reference__c == cl.bookingReference) {
            claimIdsToProrationStatus.put(
              cl.id,
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
    for (Claim cl : objects) {
      caseIds.add(cl.parentCaseId);
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
    if (objects.size() == 1) {
      Claim cl = objects[0];
      // TODO: Fix this when we can support several bookings at once
      if (
        cl.bookingReference != null &&
        cl.recordType != Claim.RecordType.CompensationCard &&
        cl.parentCaseId != null
      ) {
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            cl.parentCaseId,
            cl.bookingReference
          )
        );
      }
    }
  }

  private void updateParentCaseBookings(Map<Id, LIA_Claim__c> existingRecords) {
    if (objects.size() == 1) {
      Claim cl = objects[0];
      Claim oldRecord = new Claim(existingRecords.get(cl.id));
      // TODO: Fix this when we can support several bookings at once
      if (
        cl.bookingReference != null &&
        oldRecord.bookingReference != cl.bookingReference &&
        cl.recordType != Claim.RecordType.CompensationCard
      ) {
        BookingService.removeBookingFromCase(
          cl.parentCaseId,
          oldRecord.bookingReference
        );
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            cl.parentCaseId,
            cl.bookingReference
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

  private void fetchCAREClaims(Map<Id, LIA_Claim__c> existingRecords) {
    if (objects.size() == 1) {
      Claim newRecord = objects[0];
      Claim oldRecord = new Claim(existingRecords.get(newRecord.id));

      Boolean hasChangedPNROrPIR =
        oldRecord.bookingReference != newRecord.bookingReference ||
        oldRecord.pir != newRecord.pir;

      if (hasChangedPNROrPIR) {
        fetchCAREClaims();
      }
    }
  }

  private void fetchCAREClaims() {
    if (objects.size() == 1) {
      System.enqueueJob(
        new ClaimService.FetchCAREClaimsFromEDWAsync(
          objects[0].bookingReference,
          objects[0].pir,
          null
        )
      );
    }
  }
}
