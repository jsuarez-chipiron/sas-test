/**
    Extensible class used to process the deletion of interactions
    The batch processes interactions which are not associated to a case
    and ensures that they are not saved for longer than thier retention period
    @author Peter Södergren
*/
global abstract class GDPR_DeleteInteraction_Batch extends SBS_ScheduledBatch{
    /**
        The sobject name of the interaction sobject
    */
    private String sObjName;
    /**
        The field which links the interaction with a case and thus should be excluded
    */
    private String caseField;
    /**
        SObject name of related SObject which should be removed as well
    */
    private String relSObjName;
    /**
        The field on the primary obejct which links the primary object to the parent object
    */
    private String relSObjField;
    /**
        Whether to assume consent for the interactions (true= assume all interactions have consent, false=assume no interactions have consent, null=check each interaction for consent)
    */
    private Boolean assumeConsent;
    /**
        The date until which to retain interactions without consent
    */
    private DateTime noConsentRetentionDate;
    /**
        The date until which to max retain interactions
    */
    private DateTime maxRetentionDate;

    /**
        Creates a batch instance to delete all the interactions with the supplied logic
        @param sot The SObject type of the interaction object to delete
        @param caseField The field which links the interaction with a case and thus should be excluded
        @param relSot The related SObject Type in case that a related SObject should be removed
        @param relSObjField The Sobject field which links primary deleted object to the parent record
        @param assumeConsent Whether to assume consent for the interactions (true= assume all interactions have consent, false=assume no interactions have consent, null=check each interaction for consent)
    */
    global GDPR_DeleteInteraction_Batch(Schema.SObjectType sot,Schema.SObjectField caseField,Schema.SobjectType relSot,Schema.SObjectField relSObjField,Boolean assumeConsent){
        this.sObjName = sot+'';
        this.caseField = caseField!=null ? caseField+'' : null;
        this.relSObjName = relSot!=null && relSObjField!=null ? relSot+'' : null;
        this.relSObjField = relSot!=null && relSObjField!=null ? relSObjField+'' : null;
        this.assumeConsent = assumeConsent;
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        noConsentRetentionDate = DateTime.newInstance(Date.today().addDays(-sg.getInt('NoConsentRetentionPeriod')),Time.newInstance(0,0,0,0));
        maxRetentionDate = DateTime.newInstance(Date.today().addDays(-sg.getInt('MaxRetentionPeriod')),Time.newInstance(0,0,0,0));
    }

    /**
        Iterates over all interactions to be processed
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id, CreatedDate';
        if(assumeConsent==null)q+=', GDPR_Consent__c';
        if(relSObjField!=null)q+=', '+relSObjField;
        q+=' FROM '+sObjName;
        if(caseField!=null)q+=' WHERE '+caseField+'=null';
        return Database.getQueryLocator(q);
    }

    /**
		Deletes the interactions which should be deleted according to the retention logic
		@param bc The batchable context of the batch job
		@param sObjScope The interactions to delete
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
        List<SObject> delList = new List<SObject>();
        Set<Id> relIds = new Set<Id>();
        for(Integer i=0,sz=sObjScope.size();i<sz;i++){
            SObject so = sObjScope[i];
            Boolean consent = assumeConsent!=null ? assumeConsent : (Boolean)so.get('GDPR_Consent__c');
            DateTime createdDate = (DateTime)so.get('CreatedDate');
            Boolean del = consent ? createdDate<maxRetentionDate : createdDate<noConsentRetentionDate;
            if(del){
                delList.add(so);
                if(relSObjField!=null){
                    Id relId = (Id)so.get(relSObjField);
                    if(relId!=null)relIds.add(relId);
                }
            }
        }
        delete delList;
        if(!relIds.isEmpty()){
            SObject[] relRecs = Database.query('SELECT Id FROM '+relSObjName+' WHERE Id IN :relIds AND Id NOT IN (SELECT '+relSObjField+' FROM '+sObjName+' WHERE '+relSObjField+' IN :relIds)');
            delete relRecs;
        }
    }
}