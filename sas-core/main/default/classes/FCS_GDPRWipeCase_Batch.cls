/**
    Batch class which ensures that  cases created without explicit consent to store information for longer
    is wiped X number of days after case close. Wiping involves clearing most field values from the case
    and deleting the interactions.
    @author Peter Södergren
*/
global with sharing class FCS_GDPRWipeCase_Batch extends SBS_ScheduledBatch{
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
    global FCS_GDPRWipeCase_Batch(){
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-sg.getInt('NoConsentRetentionPeriod')),Time.newInstance(0,0,0,0));

        Set<String> retainedFields = new Set<String>();
        C_Settings.SettingsGroup sgf = C_Settings.getSettings('CWRF');
        for(String k : sgf.keySet()){
            retainedFields.add(sgf.get(k));
        }

        fieldsToClear = new List<String>();
        Map<String,Schema.SObjectField> fMap = Case.getSObjectType().getDescribe().fields.getMap();
        for(String k : fMap.keySet()){
            Schema.SObjectField f = fMap.get(k);
            if(!retainedFields.contains(f+'')){
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if(dfr.isNillable() && dfr.getType()!=Schema.DisplayType.ADDRESS && dfr.isUpdateable())fieldsToClear.add(k);
            }
        }
    }

    /**
        Iterates over all cases closed before the retention period
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Case WHERE IsClosed=true AND ClosedDate<:lastRetentionDate AND FCS_Consent__c=false');
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
        Integer sz = sObjScope.size();
        Integer fSz = fieldsToClear.size();
        Id[] caseIds = new Id[sz];
        for(Integer i=0;i<sz;i++){
            SObject so = sObjScope[i];
            caseIds[i]=so.Id;
            for(Integer j=0;j<fSz;j++){
                so.put(fieldsToClear[j],null);
            }
        }
        LiveChatTranscript lctList = [SELECT Id FROM LiveChatTranscript WHERE CaseId IN :caseIds];
        EmailMessage emList = [SELECT Id FROM EmailMessage WHERE ParentId IN :caseIds];
        MessagingSession msList = [SELECT Id FROM MessagingSession WHERE CaseId IN :caseIds];
        SocialPost spList = [SELECT Id FROM SocialPost WHERE ParentId IN :caseIds];
        delete lctList;
        delete emList;
        delete msList;
        delete spList;
        update sObjScope;
    }

    
}
