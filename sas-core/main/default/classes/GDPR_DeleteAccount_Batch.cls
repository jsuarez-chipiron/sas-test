/**
    Deletes all accounts which no longer have any cases associated to it
    @author Peter Södergren
*/
global with sharing class GDPR_DeleteAccount_Batch extends SBS_ScheduledBatch{
    /**
        Iterates over all person accounts
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Account WHERE IsPersonAccount=true');
    }

    /**
		Deletes the accounts if they have no cases
		@param bc The batchable context of the batch job
		@param sObjScope The accounts to process whether they have cases or not
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        delete [SELECT Id FROM Account WHERE Id IN :C_Util.getIdSet(sObjScope) AND Id NOT IN(SELECT AccountId FROM Case WHERE AccountId IN :C_Util.getIdSet(sObjScope))];
    }
}
