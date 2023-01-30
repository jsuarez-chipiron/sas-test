public with sharing class RunEU261AutomationScheduler implements Schedulable {
  public void execute(SchedulableContext jobId) {
    Set<Id> claimIdsToAutomate = new Map<Id, LIA_Claim__c>(
        ClaimsSelector.newInstance().selectUnhandledClaimsToAutomate()
      )
      .keySet();
    System.enqueueJob(
      new EU261Service.ProcessEU261ClaimsAsync(claimIdsToAutomate)
    );
  }
}
