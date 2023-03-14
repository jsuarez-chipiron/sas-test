public with sharing class FetchEDWBookingsForEU261ClaimsBatch implements Database.Batchable<LIA_Claim__c>, Database.AllowsCallouts {
  private static final Decimal MAX_RETRIEVE_COUNT = 3.0;

  public Iterable<LIA_Claim__c> start(Database.BatchableContext jobId) {
    return ClaimsSelector.newInstance()
      .selectUnhandledEU261ClaimsByDataStatus('In Progress');
  }

  public void execute(
    Database.BatchableContext bc,
    List<LIA_Claim__c> claimsToFetch
  ) {
    fflib_ISObjectUnitOfWork uowUpsert = SAS_Service_Application.UnitOfWork.newInstance();
    fflib_ISObjectUnitOfWork uowDelete = SAS_Service_Application.UnitOfWork.newInstance();
    for (LIA_Claim__c c : claimsToFetch) {
      Bookings b = BookingService.fetchEDWBookingByBookingReference(
        c.Liability_PNR__c,
        uowUpsert,
        uowDelete
      );
      Decimal newRetrieveCount = c.External_Data_Retrieve_Count__c + 1;
      if (b == null) {
        if (newRetrieveCount > MAX_RETRIEVE_COUNT) {
          c.EU261_Handling_Status__c = 'Unable to handle';
          c.External_Data_Status__c = 'Unavailable';
        }
      } else {
        c.External_Data_Status__c = 'Completed';
      }
      c.External_Data_Retrieve_Count__c = newRetrieveCount;
      uowUpsert.registerDirty(c);
    }
    uowDelete.commitWork();
    uowUpsert.commitWork();
  }

  public void finish(Database.BatchableContext jobId) {
  }
}
