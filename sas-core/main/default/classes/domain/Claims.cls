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

  private List<LIA_Claim__c> instanceRecords;

  public enum RecordType {
    CustomerClaim
  }

  public static Map<RecordType, String> recordTypeToDeveloperName = new Map<RecordType, String>{
    RecordType.CustomerClaim => 'CustomerClaim'
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
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    checkIfExistsInCARE((Map<Id, LIA_Claim__c>) existingRecords);
    updateParentCaseBookings((Map<Id, LIA_Claim__c>) existingRecords);
    // TODO: We should also update EB accounts correctly. Requires fixing of the entire EB accounts fetching flow.
  }

  public override void onBeforeInsert() {
    capitalisePNR();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    clearClaimInCareField();
    capitalisePNR();
  }

  private void assignToQueueUsingFlow() {
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

  private void updateParentCaseBookings(Map<Id, LIA_Claim__c> existingRecords) {
    if (instanceRecords.size() == 1) {
      LIA_Claim__c claim = instanceRecords[0];
      // TODO: Fix this when we can support several bookings at once
      if (
        claim.Liability_PNR__c != null &&
        existingRecords.get(claim.Id).Liability_PNR__c != claim.Liability_PNR__c
      ) {
        BookingService.removeBookingFromCase(
          claim.Case__c,
          existingRecords.get(claim.Id).Liability_PNR__c
        );
        BookingService.addBookingToCaseAsync(
          claim.Case__c,
          claim.Liability_PNR__c
        );
      }
    }
  }

  private void capitalisePNR() {
    for (LIA_Claim__c claim : instanceRecords) {
      if (claim.Liability_PNR__c != null) {
        claim.Liability_PNR__c = claim.Liability_PNR__c.toUpperCase();
      }
    }
  }
}
