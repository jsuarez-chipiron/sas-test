public with sharing class FetchEDWBookingsForEU261ClaimsBatch implements Database.Batchable<LIA_Claim__c>, Database.AllowsCallouts, Database.Stateful {
  private static final Decimal MAX_RETRIEVE_COUNT = 3.0;
  private Set<Id> caseIdsToManualHandling;
  private Set<String> retrievedPNR;

  public FetchEDWBookingsForEU261ClaimsBatch() {
    this.caseIdsToManualHandling = new Set<Id>();
    this.retrievedPNR = new Set<String>();
  }

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
      Boolean foundBooking = false;

      //No need to fetch the same booking multiple times per batch job
      if (!this.retrievedPNR.contains(c.Liability_PNR__c)) {
        this.retrievedPNR.add(c.Liability_PNR__c);
        Bookings b = BookingService.fetchEDWBookingByBookingReference(
          c.Liability_PNR__c,
          uowUpsert,
          uowDelete
        );
        foundBooking = b != null;
      }

      Decimal newRetrieveCount = c.External_Data_Retrieve_Count__c + 1;
      if (foundBooking) {
        c.External_Data_Status__c = 'Completed';
      } else {
        if (newRetrieveCount > MAX_RETRIEVE_COUNT) {
          c.EU261_Handling_Status__c = 'Unable to handle';
          c.External_Data_Status__c = 'Unavailable';
          caseIdsToManualHandling.add(c.Case__c);
        }
      }
      c.External_Data_Retrieve_Count__c = newRetrieveCount;
      uowUpsert.registerDirty(c);
    }
    uowDelete.commitWork();
    uowUpsert.commitWork();
  }

  public void finish(Database.BatchableContext jobId) {
    if (caseIdsToManualHandling.size() > 0) {
      CaseService.assignPriorityAndRouteToQueue(caseIdsToManualHandling);
    }
  }
}
