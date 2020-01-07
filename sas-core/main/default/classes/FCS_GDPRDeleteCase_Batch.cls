/**
    Batch class which ensures that all cases and interactions related to the cases are deleted after
    X number of days after case closed.
    @author Peter Södergren
*/
global with sharing class FCS_GDPRDeleteCase_Batch extends SBS_ScheduledBatch{
    /**
        The date at which cases will be removed
    */
    private DateTime lastRetentionDate;
    /**
        Initiates the batch class and extracts the date used to filter out cases for removal
    */
    global FCS_GDPRDeleteCase_Batch(){
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-sg.getInt('MaxRetentionPeriod')),Time.newInstance(0,0,0,0));
    }

    /**
        Iterates over all cases closed before the retention period
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Case WHERE IsClosed=true AND ClosedDate<:lastRetentionDate');
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
        Id[] caseIds = new Id[sz];
        for(Integer i=0;i<sz;i++){
            caseIds[i]=sObjScope[i].Id;
        }
        LiveChatTranscript lctList = [SELECT Id FROM LiveChatTranscript WHERE CaseId IN :caseIds];
        EmailMessage emList = [SELECT Id FROM EmailMessage WHERE ParentId IN :caseIds];
        MessagingSession msList = [SELECT Id FROM MessagingSession WHERE CaseId IN :caseIds];
        SocialPost spList = [SELECT Id FROM SocialPost WHERE ParentId IN :caseIds];
        delete lctList;
        delete emList;
        delete msList;
        delete spList;
        delete sObjScope;
    }

    
}
