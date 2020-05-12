/**
    Batch class which ensures that all Communication Logs are deleted after
    X number of days of created date.
    @author Ludvig Wälimaa
*/
global with sharing class GDPR_DeleteCommunicationLog_Batch extends SBS_ScheduledBatch{
    /**
        The date at which Communication Logs will be removed
    */
    private DateTime lastRetentionDate;
    /**
        Initiates the batch class and extracts the date used to filter out Communication Logs for removal
    */
    global GDPR_DeleteCommunicationLog_Batch(){
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-C_Settings.getSettings('GDPR').getInt('DeletePeriodCommunicationLog')),Time.newInstance(0,0,0,0));
        this.setUseTransactionControl(false);
    }

    /**
        Iterates over all Communication Logs before the retention period
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return IRR_SEL_CommunicationLogsSelector.newInstance().getGDPRLogsQueryLocator(lastRetentionDate);
    }


    /**
		Deletes the Communication Logs 
		@param bc The batchable context of the batch job
		@param sObjScope The Communication Logs to delete
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        Set<Id> idSet = new Set<Id>();
        for(SObject so : sObjScope) idSet.add(so.Id);
        IRR_SVC_CommunicationService.processGDPRLogs(idSet, lastRetentionDate);
    }

    
}