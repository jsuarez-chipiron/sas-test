public without sharing class FetchCAREDataEvents {
  public static void onAfterInsert(List<Fetch_CARE_Data__e> Records) {
    for (Fetch_CARE_Data__e fetchDataEvent : Records) {
      ClaimService.checkIfClaimsExistInCARE(
        fetchDataEvent.Claim_Id__c,
        fetchDataEvent.Booking_Reference__c
      );
    }
  }
}
