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
    private DateTime cutOffNoConsent;
    /**
        The date until which to max retain interactions
    */
    private DateTime cutOffConsent;

    /**
        Creates a batch instance to delete all the interactions with the supplied logic
        @param sot The SObject type of the interaction object to delete
        @param maxDaysConsentName The name of the general GDPR setting which defines the maximum number of days for which an interaction may be stored with consent
        @param maxDaysNoConsentName The name of the general GDPR setting which defines the maximum number of days for which and interaction may be stored without consent (null=use consent setting)
        @param caseField The relationship field to a case (If present it assumed that the case holds the consent for the conversation)
        @param relSot The related SObject Type in case that a related SObject should be removed
        @param relSObjField The Sobject field which links primary deleted object to the parent record
    */
    global GDPR_DeleteInteraction_Batch(Schema.SObjectType sot,String maxDaysConsentName,String maxDaysNoConsentName,Schema.SObjectField caseField,Schema.SobjectType relSot,Schema.SObjectField relSObjField){
        this.sObjName = sot+'';
        this.caseField = caseField!=null ? caseField+'' : null;
        this.relSObjName = relSot!=null && relSObjField!=null ? relSot+'' : null;
        this.relSObjField = relSot!=null && relSObjField!=null ? relSObjField+'' : null;
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        Integer maxDaysConsent = maxDaysConsentName!=null ? sg.getInt(maxDaysConsentName) : null;
        Integer maxDaysNoConsent = maxDaysNoConsentName!=null ? sg.getInt(maxDaysNoConsentName) : null;
        cutOffConsent = DateTime.newInstance(Date.today().addDays(-maxDaysConsent),Time.newInstance(0,0,0,0));
        cutOffNoConsent = maxDaysNoConsent!=null ? DateTime.newInstance(Date.today().addDays(-maxDaysNoConsent),Time.newInstance(0,0,0,0)) : cutOffConsent;
    }

    /**
        Iterates over all interactions to be processed
        @param bc The batch context
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id, CreatedDate';
        if(caseField==null)q+=', GDPR_Consent__c';
        else q+=', '+caseField;
        if(relSObjField!=null)q+=', '+relSObjField;
        q+=' FROM '+sObjName+' WHERE CreatedDate<:cutOffConsent';
        System.debug(q);
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
        Map<Id,Case> caseMap;
        if(caseField!=null && cutOffConsent!=cutOffNoConsent){
            Set<Id> caseIds = new Set<Id>();
            for(Integer i=0,sz=sObjScope.size();i<sz;i++){
                Id caseId = (Id)sObjScope[i].get(caseField);
                if(caseId!=null)caseIds.add(caseId);
            }
            caseMap = new Map<Id,Case>([SELECT Id,GDPR_Consent__c FROM Case WHERE Id IN :caseIds]);
        }
        for(Integer i=0,sz=sObjScope.size();i<sz;i++){
            SObject so = sObjScope[i];
            Boolean consent = false;
            if(cutOffConsent!=cutOffNoConsent){
                SObject conSO = caseField!=null ? (so.get(caseField)!=null ? caseMap.get((Id)so.get(caseField)) : null) : so;
                if(conSO!=null)consent = (Boolean)conSO.get('GDPR_Consent__c');
            }
            DateTime createdDate = (DateTime)so.get('CreatedDate');
            Boolean del = consent ? createdDate<cutOffConsent : createdDate<cutOffNoConsent;
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