public with sharing class RunEU261AutomationScheduler implements Schedulable {
  public void execute(SchedulableContext jobId) {
    List<LIA_Claim__c> allClaimsToAutomate = [select id,Preferred_Compensation_Method__c from LIA_Claim__c where EU261_Handling_Status__c ='Unhandled' and External_Data_Status__c ='Completed' and Customer_Claim_Type__c IN :ClaimsSelector.EU261_CLAIM_TYPES and Case__r.Owner.Name = 'SAS Automation Queue' LIMIT 1600];
    Set<Id> claimIdsWithMonetary = new Set<Id>();
    Set<Id> claimIdsWithEBPointsOrVoucher = new Set<Id>();
    for (LIA_Claim__c cl : allClaimsToAutomate) {
      if (cl.Preferred_Compensation_Method__c == 'Monetary') {
        claimIdsWithMonetary.add(cl.Id);
       } else {
        claimIdsWithEBPointsOrVoucher.add(cl.Case__c);
      }
    }
    EU261Service.newInstance().batchProcessEU261Claims(claimIdsWithMonetary);
    // EU261Service.newInstance()
    //   .batchProcessEU261Claims(claimIdsWithEBPointsOrVoucher);
    //route claimIdsWithEBPointsOrVoucher to manual handling queue/routing
    CaseService.assignPriorityAndRouteToQueue(claimIdsWithEBPointsOrVoucher);
  }
}
