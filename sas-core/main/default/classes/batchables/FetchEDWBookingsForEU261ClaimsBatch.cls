public with sharing class FetchEDWBookingsForEU261ClaimsBatch implements Database.Batchable<LIA_Claim__c>, Database.Stateful, Database.AllowsCallouts {
  public Set<Id> successfulFetches;
  public fflib_ISObjectUnitOfWork uowUpsert;
  public fflib_ISObjectUnitOfWork uowDelete;
  public Iterable<LIA_Claim__c> start(Database.BatchableContext jobId) {
    this.successfulFetches = new Set<Id>();
    this.uowUpsert = SAS_Service_Application.UnitOfWork.newInstance();
    this.uowDelete = SAS_Service_Application.UnitOfWork.newInstance();
    return ClaimsSelector.newInstance().selectUnhandledClaimsToAutomate();
  }

  public void execute(
    Database.BatchableContext bc,
    List<LIA_Claim__c> claimsToFetch
  ) {
    for (LIA_Claim__c c : claimsToFetch) {
      Bookings b = BookingService.fetchEDWBookingByBookingReference(
        c.Liability_PNR__c,
        this.uowUpsert,
        this.uowDelete
      );
      if (b == null) {
        c.EU261_Handling_Status__c = 'Unable to handle';
        this.uowUpsert.registerDirty(c);
      } else {
        this.successfulFetches.add(c.Id);
      }
    }
  }

  public void finish(Database.BatchableContext jobId) {
    String completionMessage = String.format(
      'Finished processing {0} records. \nList of records: {1}',
      new List<Object>{ successfulFetches.size(), successfulFetches.toString() }
    );
    C_Log.log(C_Log.Severity.Info, completionMessage, null, 'EDW', null);
    this.uowDelete.commitWork();
    this.uowUpsert.commitWork();
  }
}
