/**
    Batch in order to delete log entries
    @author Peter Södergren
*/
global class C_LogDelete_Batch extends SBS_ScheduledBatch{
    /**
        The retention date of the of the log records. Logs created prior to this date will be deleted by the batch
    */
    private DateTime logRetentionDate;
    /**
        Creates an instance of batch to delete logs outside the retention period
    */
    global C_LogDelete_Batch() {
        C_Settings.SettingsGroup sg = C_Settings.getSettings('Log');
        logRetentionDate = DateTime.newInstance(Date.today().addDays(-sg.getInt('LogRetentionPeriod')),Time.newInstance(0, 0, 0, 0));
    }

    /**
        Iterates over the log records to delete
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM C_Log__c WHERE CreatedDate<:logRetentionDate');
    }

    /**
		Deletes the log records
		@param bc The batchable context of the batch job
		@param sObjScope The accounts to process
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        delete sObjScope;
    }
}
