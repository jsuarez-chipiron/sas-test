/**
Service class providing the functionality to wipe a case
I.e. remove fields except the fields to retain and delete
all interactions connected to the case.
@author Peter Södergren
*/
global with sharing class GDPR_WipeCaseService {
    /**
Additional retained fields used by test due to a Salesforce bug with testing and field definitions
*/
    @TestVisible static Set<String> RETAIN_ADD;
    /**
Retrieves the case fields to clear based where the fields 
stored in the general setting group CWRF are removed
@return The list fo fields which should be wiped from the case
*/
    global static String[] getCaseFieldsToClear(){
        Set<String> retainedFields = RETAIN_ADD!=null ? RETAIN_ADD : new Set<String>();
        //TODO When issue related to retrieving multiple field definitions in on transaction os solved, remove Account filter from this query and filter in loop below
        FieldDefinition[] fdList = [SELECT QualifiedAPIName,ComplianceGroup, EntityDefinitionId FROM FieldDefinition WHERE (EntityDefinitionId ='Account' OR EntityDefinitionId ='Case') AND ComplianceGroup!=null];
        for(FieldDefinition fd : fdList){
            if(fd.EntityDefinitionId == 'Case' && fd.ComplianceGroup.split(';').contains('WipeRetain'))retainedFields.add(fd.QualifiedAPIName);
        }
        //Add fields for which compliance cannot be set
        retainedFields.add('RecordTypeId');
        
        List<String> fieldsToClear = new List<String>();
        Map<String,Schema.SObjectField> fMap = Case.getSObjectType().getDescribe().fields.getMap();
        for(String k : fMap.keySet()){
            Schema.SObjectField f = fMap.get(k);
            if(!retainedFields.contains(f+'')){
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if(dfr.isNillable() && dfr.getType()!=Schema.DisplayType.ADDRESS && dfr.isUpdateable())fieldsToClear.add(k);
            }
        }
        return fieldsToClear;
    }
    /**
Wipes the cases with the supplied case ids and deletes any connected interactions
@param caseIds THe ids of the cases to wipe
*/
    global static void wipeCases(Id[] caseIds){
        Integer sz = caseIds.size();
        Case[] caseList = new Case[sz];
        for(Integer i=0;i<sz;i++){
            caseList[i] = new Case(Id=caseIds[i]);
        }
        wipeCases(caseList);
    }
    
    /**
Wipes the provided cases and deletes any connected interactions
@param caseList The list of cases to wipe
*/
    global static void wipeCases(Case[] caseList){
        wipeCases(caseList,getCaseFieldsToClear());
    }
    
    /**
Wipes the provided cases and deletes any connected interactions
with a custom set of connected fields.
@param caseList The list of cases to wipe
@param fieldsToClear The fields to clear on the case record
*/
    global static void wipeCases(Case[] caseList,String[] fieldsToClear){
        Integer sz = caseList.size();
        Integer fSz = fieldsToClear.size();
        Set<Id> caseIds = new Set<Id>();
        boolean wipeCase = true;
        for(Integer i=0;i<sz;i++){
            Case c = caseList[i];
            caseIds.add(c.Id);
            for(Integer j=0;j<fSz;j++){
                c.put(fieldsToClear[j],null);
            }
            c.GDPR_Wiped__c = true;
        }
        deleteRelatedEntities(caseIds,wipeCase);
        update caseList;
    }
    
    /**
Deletes the entities related to the provided case ids
@param caseIds The case ids for which to delete the related entities
@param wipecase used to recognize whether we are wiping the cases or deleting the cases.

*/
    global static void deleteRelatedEntities(Set<Id> caseIds, boolean wipeCase){
        List<String> socialAccts = new List<String>(); // lst to store social accounts
        Set<Id> setLinkEntityIds = new set<Id>(); // set to capture the related case and messagesession Ids;
        Set<Id> setContDocumentIds = new Set<Id>(); // set to remove the duplicates
        socialAccts.add(C_Settings.getSettings('Social Accounts').get('ManagedFacebookPage'));
        socialAccts.add(C_Settings.getSettings('Social Accounts').get('ManagedTwitterPage'));   
        LiveChatTranscript[] lctList = [SELECT Id,LiveChatVisitorId FROM LiveChatTranscript WHERE CaseId IN :caseIds];
        MessagingSession[] msList = [SELECT Id,MessagingEndUserId FROM MessagingSession WHERE CaseId IN :caseIds];
        Map<ID, EmailMessage> mapEmailMessages = new Map<ID, EmailMessage>([SELECT Id FROM EmailMessage WHERE ParentId IN :caseIds]);
        EmailMessage[] emList = mapEmailMessages.values();
        SocialPost[] spList = [SELECT Id FROM SocialPost WHERE ParentId IN :caseIds AND Persona.name NOT IN :socialAccts];
        Task[] tList = [SELECT Id FROM Task WHERE WhatId IN :caseIds];
        CaseComment[] ccList = [SELECT Id FROM CaseComment WHERE ParentId IN :caseIds];
        CaseToBooking__c[] cbList = [Select Id FROM CaseToBooking__c WHERE Case__c IN :caseIds];
        setLinkEntityIds.addAll(caseIds);
        setLinkEntityIds.addAll(mapEmailMessages.keySet());
        ContentDocumentLink[] cdlList = [SELECT Id,ContentDocumentId,ContentDocument.LatestPublishedVersion.FirstPublishLocationId FROM ContentDocumentLink WHERE LinkedEntityId IN :setLinkEntityIds];
        List<ContentDocument> cdDelList = new List<ContentDocument>();
        for(ContentDocumentLink cdl:cdlList){
            if(cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId!=null && !setContDocumentIds.contains(cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId ))
            {
                cdDelList.add(new ContentDocument(Id=cdl.ContentDocumentId));
                setContDocumentIds.add(cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId);
            }
        }
        delete lctList;    
        delete msList;
        delete spList;
        delete tList;
        delete ccList;
        delete cbList;
        if(!wipeCase)
        {
            delete emList;
            delete cdDelList;
        }
        
        Set<Id> lcvIds = new Set<Id>();
        for(Integer i=0,lctSz=lctList.size();i<lctSz;i++){
            LiveChatTranscript lct = lctList[i];
            if(lct.LiveChatVisitorId!=null)lcvIds.add(lct.LiveChatVisitorId);
        }
        if(!lcvIds.isEmpty()){
            LiveChatVisitor[] lcvList = [SELECT Id FROM LiveChatVisitor WHERE Id IN :lcvIds AND Id NOT IN (SELECT LiveChatVisitorId FROM LiveChatTranscript WHERE LiveChatVisitorId IN :lcvIds)];   
            delete lcvList;
        }
        
        Set<Id> meuIds = new Set<Id>();
        for(Integer i=0,msSz=msList.size();i<msSz;i++){
            MessagingSession ms = msList[i];
            if(ms.MessagingEndUserId!=null)meuIds.add(ms.MessagingEndUserId);
        }
        if(!meuIds.isEmpty()){
            MessagingEndUser[] meuList = [SELECT Id FROM MessagingEndUser WHERE Id IN :meuIds AND Id NOT IN (SELECT MessagingEndUserId FROM MessagingSession WHERE MessagingEndUserId IN :meuIds)];   
            delete meuList;
        }
    }
}