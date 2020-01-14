/**
    Batch class which ensures that  cases created without explicit consent to store information for longer
    is wiped X number of days after case close. Wiping involves clearing most field values from the case
    and deleting the interactions.
    @author Peter Södergren
*/
global with sharing class GDPR_WipeCase_Batch extends SBS_ScheduledBatch{
    /**
        The date at which cases will be wiped
    */
    private DateTime lastRetentionDate;
    /**
        The fields to clear for the case
    */
    private String[] fieldsToClear;
    /**
        Initiates the batch class and extracts the date used to filter out cases for removal
    */
    global GDPR_WipeCase_Batch(){
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-C_Settings.getSettings('GDPR').getInt('WipePeriodCase')),Time.newInstance(0,0,0,0));
        fieldsToClear = GDPR_WipeCaseService.getCaseFieldsToClear();
    }

    /**
        Iterates over all cases closed before the retention period
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Case WHERE IsClosed=true AND ClosedDate<:lastRetentionDate AND GDPR_Consent__c=false');
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
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        GDPR_WipeCaseService.wipeCases((Case[])sObjScope, fieldsToClear);
    }

    
}
