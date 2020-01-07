/**
    Batch class which ensures that all data except the CODS id and system fields
    are deleted from the account record X days after the last case was closed for the account.
    This ensures that data originating from another SOR is not stored for longer than necessary.
    Note: This batch only operates on person accounts
    @author Peter Södergren
*/
global with sharing class FCS_GDPRDeleteAccountData_Batch extends SBS_ScheduledBatch{
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
    global FCS_GDPRDeleteAccountData_Batch(){
        fieldsToClear = new List<String>(); 
        Map<String,Schema.SObjectField> fMap = Account.getSObjectType().getDescribe().fields.getMap();
        Set<Schema.SObjectField> excludedFields = new Set<Schema.SObjectField>{Account.CodsId__c,Account.MasterRecordId,Account.RecordTypeId,Account.Name};
        for(String k : fMap.keySet()){
            Schema.SObjectField f = fMap.get(k);
            if(!excludedFields.contains(f)){
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if(dfr.isNillable() && dfr.getType()!=Schema.DisplayType.ADDRESS && dfr.isUpdateable())fieldsToClear.add(k);
            }
        }
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-sg.getInt('AccountDataWipePeriod')),Time.newInstance(0,0,0,0));
        wipedAccountName = sg.get('AccountDataWipeName');
    }

    /**
        Iterates over all active accounts
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Account WHERE FCS_Wiped__c=false AND IsPersonAccount=true');
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
        List<Account> accUpdList = new List<Account>();
        for(Integer i=0;i<sz;i++){
            Id accId = accIds[i];
            if(!retentionAccIds.contains(accId)){
                Account acc = new Account(Id=accId);
                for(Integer j=0,jSz=fieldsToClear.size();j<jSz;j++){
                    acc.put(fieldsToClear[j],null);
                }
                acc.FCS_Wiped__c = true;
                acc.FirstName = null;
                acc.LastName = wipedAccountName;
                accUpdList.add(acc);
            }
        }
        update accUpdList;
    }

    
}
