public without sharing class Claims extends fflib_SObjectDomain {
  public Claims(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<LIA_Claim__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Claims(records);
    }
  }

  private List<LIA_Claim__c> instanceRecords;

  public static Claims newInstance(List<LIA_Claim__c> sObjectList) {
    return (Claims) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public override void onAfterInsert() {
    checkIfExistsInCARE();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    checkIfExistsInCARE((Map<Id, LIA_Claim__c>) existingRecords);
    updateParentCaseBookings((Map<Id, LIA_Claim__c>) existingRecords);
    // TODO: We should also update EB accounts correctly. Requires fixing of the entire EB accounts fetching flow.
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    clearClaimInCareField();
  }

  private void checkIfExistsInCARE(Map<Id, LIA_Claim__c> existingRecords) {
    for (LIA_Claim__c claim : instanceRecords) {
      if (claim.Liability_PNR__c != null) {
        Boolean shouldCheckEDW =
          existingRecords.get(claim.Id).Liability_PNR__c !=
          claim.Liability_PNR__c;
        if (shouldCheckEDW) {
          ClaimService.checkIfClaimsExistInCARE(
            claim.Id,
            claim.Liability_PNR__c
          );
        }
      }
    }
  }

  private void checkIfExistsInCARE() {
    for (LIA_Claim__c claim : instanceRecords) {
      if (claim.Liability_PNR__c != null) {
        ClaimService.checkIfClaimsExistInCARE(claim.Id, claim.Liability_PNR__c);
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
}
