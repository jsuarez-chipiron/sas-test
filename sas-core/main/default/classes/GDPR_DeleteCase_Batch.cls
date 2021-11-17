/**
Batch class which ensures that all cases and interactions related to the cases are deleted after
X number of days after case closed.
@author Peter Södergren
*/
global with sharing class GDPR_DeleteCase_Batch extends SBS_ScheduledBatch {
  /**
The date at which cases will be removed
*/
  @testVisible
  private DateTime lastRetentionDate;
  /**
The Case Type in which batch job executes
*/
  private string caseType;

  /**
  The Name of the Batch in GDPR Retention policy , based on which related metadata will be retrived
  */
  private string batchName;

  global GDPR_DeleteCase_Batch() {
  }
  /**
Overiding of the abstract method used to set the Batch class params
*/
  global override void setVariables(
    String obj,
    Integer retentionPeriod,
    string caseField,
    string caseType,
    String batchName
  ) {
    lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-retentionPeriod),
      Time.newInstance(0, 0, 0, 0)
    );
    this.caseType = caseType;
    this.batchName = batchName;
  }
  /**
Iterates over all cases closed before the retention period
@param bc The batch context
*/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id FROM Case WHERE IsClosed=true AND ClosedDate<:lastRetentionDate AND FCS_CaseType__c=:caseType'
    );
  }

  /**
Deletes the cases and any related interactions
- Chat Transcripts
- Emails
- Messaging Sessions
- Social Posts
@param bc The batchable context of the batch job
@param sObjScope The cases to delete
*/
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    Integer sz = sObjScope.size();
    Set<Id> caseIds = new Set<Id>();
    for (Integer i = 0; i < sz; i++) {
      caseIds.add(sObjScope[i].Id);
    }
    
    GDPR_WipeCaseService.deleteRelatedEntities(caseIds, batchName);
    delete sObjScope;
  }
}