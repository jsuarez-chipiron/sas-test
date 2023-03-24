public with sharing class FetchEDWBookingsForEU261ClaimsBatch implements Database.Batchable<LIA_Claim__c>, Database.AllowsCallouts, Database.Stateful {
  private static final Decimal MAX_RETRIEVE_COUNT = 3.0;
  private Set<Id> caseIdsToManualHandling;
  private Map<String, Boolean> retrievedPNR;

  public FetchEDWBookingsForEU261ClaimsBatch() {
    this.caseIdsToManualHandling = new Set<Id>();
    this.retrievedPNR = new Map<String, Boolean>();
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
      if (!this.retrievedPNR.containsKey(c.Liability_PNR__c)) {
        Bookings b = BookingService.fetchEDWBookingByBookingReference(
          c.Liability_PNR__c,
          uowUpsert,
          uowDelete
        );
        foundBooking = b != null;
        this.retrievedPNR.put(c.Liability_PNR__c, foundBooking);
      } else {
        foundBooking = this.retrievedPNR.get(c.Liability_PNR__c);
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
