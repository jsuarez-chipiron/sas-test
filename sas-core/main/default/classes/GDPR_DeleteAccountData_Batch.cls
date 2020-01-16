/**
    Batch class which ensures that all data except the CODS id and system fields
    are deleted from the account record X days after the last case was closed for the account.
    This ensures that data originating from another SOR is not stored for longer than necessary.
    Note: This batch only operates on person accounts
    @author Peter Södergren
*/
global with sharing class GDPR_DeleteAccountData_Batch extends SBS_ScheduledBatch{
    /**
        The fields to clear for the account
    */
    private String[] fieldsToClear;
    /**
        The date at which if cases of the account were closed after this date the account should be kept
    */
    private DateTime lastRetentionDate;
    /**
        The name which a wiped account receives
    */
    private String wipedAccountName;
    /**
        Initiates the batch class and storing the fields which should be removed
    */
    global GDPR_DeleteAccountData_Batch(){
        fieldsToClear = GDPR_WipeAccountService.getAccountFieldsToClear(true);
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-C_Settings.getSettings('GDPR').getInt('WipePeriodAccount')),Time.newInstance(0,0,0,0));
        wipedAccountName = GDPR_WipeAccountService.getWipedAccountName();
    }

    /**
        Iterates over all active accounts
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Account WHERE GDPR_WipedSoft__c=false AND GDPR_Wiped__c=false AND IsPersonAccount=true');
    }


    /**
		Checks the last closed case for the accounts and deletes the data of the accoiun
		@param bc The batchable context of the batch job
		@param sObjScope The accounts to process
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        Integer sz = sObjScope.size();
        Id[] accIds = new Id[sz];
        for(Integer i=0;i<sz;i++){
            accIds[i]=sObjScope[i].Id;
        }
        Account[] retentionAccs = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Case WHERE AccountId IN :accIds AND (IsClosed=false OR ClosedDate>=:lastRetentionDate))];
        Set<Id> retentionAccIds = C_Util.getIdSet(retentionAccs);
        Set<Id> accWipeIds = new Set<Id>(accIds);
        accWipeIds.removeAll(retentionAccIds);
        if(!accWipeIds.isEmpty())GDPR_WipeAccountService.wipeAccounts(new List<Id>(accWipeIds), fieldsToClear, wipedAccountName, false, false);
    }

    
}
