public with sharing class RunEU261AutomationScheduler implements Schedulable {
  public void execute(SchedulableContext jobId) {
    List<LIA_Claim__c> allClaimsToAutomate = ClaimsSelector.newInstance()
      .selectUnhandledEU261ClaimsByDataStatus('Completed');
    Set<Id> claimIdsWithMonetary = new Set<Id>();
    Set<Id> claimIdsWithEBPointsOrVoucher = new Set<Id>();
    for (LIA_Claim__c cl : allClaimsToAutomate) {
      if (cl.Preferred_Compensation_Method__c == 'Monetary') {
        claimIdsWithMonetary.add(cl.Id);
      } else {
        claimIdsWithEBPointsOrVoucher.add(cl.Id);
      }
    }
    EU261Service.newInstance().batchProcessEU261Claims(claimIdsWithMonetary);
    EU261Service.newInstance()
      .batchProcessEU261Claims(claimIdsWithEBPointsOrVoucher);
  }
}
