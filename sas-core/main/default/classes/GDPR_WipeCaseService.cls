/**
Service class providing the functionality to wipe and Delete the case
I.e. remove fields except the fields to retain and delete
all interactions connected to the case.
@author Peter Södergren
*/
global with sharing class GDPR_WipeCaseService {
  /**
  Additional retained fields used by test due to a Salesforce bug with testing and field definitions
  */
  @TestVisible
  static Set<String> RETAIN_ADD;

  /*    Wipes the cases with the supplied case ids and deletes any connected interactions
  @param caseIds THe ids of the cases to wipe
  */
  global static void wipeCases(Id[] caseIds) {
    Integer sz = caseIds.size();
    Case[] caseList = new List<Case>(sz);
    for (Integer i = 0; i < sz; i++) {
      caseList[i] = new Case(Id = caseIds[i]);
    }
    wipeCases(caseList);
  }

  /**
  Wipes the provided cases and deletes any connected interactions
  @param caseList The list of cases to wipe
  */
  global static void wipeCases(Case[] caseList) {
    wipeCases(caseList, GDPR_Util.getCaseFieldsToClear('Case'));
  }
  /**
  Wipes the provided cases and wipe any connected interactions
  with a custom set of connected fields.
  @param caseList The list of cases to wipe
  @param fieldsToClear The fields to clear on the case record
  */
  global static void wipeCases(Case[] caseList, String[] fieldsToClear) {
    Integer sz = caseList.size();
    Integer fSz = fieldsToClear.size();
    Set<Id> caseIds = new Set<Id>();
    boolean wipeCase = true;
    for (Integer i = 0; i < sz; i++) {
      Case c = caseList[i];
      caseIds.add(c.Id);
      for (Integer j = 0; j < fSz; j++) {
        c.put(fieldsToClear[j], null);
      }
      c.GDPR_Wiped__c = true;
    }
    wipeRelatedEntities(caseIds);
    update caseList;
  }

  /**
  Deletes the entities related to the provided case ids
  @param caseIds The case ids for which to delete the related entities
  @param wipecase used to recognize whether we are wiping the cases or deleting the cases.
  
  */
  global static void deleteRelatedEntities(Set<Id> caseIds) {
    List<String> socialAccts = new List<String>(); // lst to store social accounts
    Set<Id> setLinkEntityIds = new Set<Id>(); // set to capture the related case and messagesession Ids;
    Set<Id> setContDocumentIds = new Set<Id>(); // set to remove the duplicates
    List<Sobject> lstSobjectDelete = new List<SObject>();
    socialAccts.add(
      C_Settings.getSettings('Social Accounts').get('ManagedFacebookPage')
    );
    socialAccts.add(
      C_Settings.getSettings('Social Accounts').get('ManagedTwitterPage')
    );

    LiveChatTranscript[] lctList = [
      SELECT Id, LiveChatVisitorId
      FROM LiveChatTranscript
      WHERE CaseId IN :caseIds
    ];

    lstSobjectDelete.addAll(lctList);

    MessagingSession[] msList = [
      SELECT Id, MessagingEndUserId
      FROM MessagingSession
      WHERE CaseId IN :caseIds
    ];

    lstSobjectDelete.addAll(msList);

    SocialPost[] spList = [
      SELECT Id
      FROM SocialPost
      WHERE ParentId IN :caseIds AND Persona.name NOT IN :socialAccts
    ];
    lstSobjectDelete.addAll(spList);
    Task[] tList = [SELECT Id FROM Task WHERE WhatId IN :caseIds];
    lstSobjectDelete.addAll(tList);
    CaseComment[] ccList = [
      SELECT Id
      FROM CaseComment
      WHERE ParentId IN :caseIds
    ];
    lstSobjectDelete.addAll(ccList);
    CaseToBooking__c[] cbList = [
      SELECT Id
      FROM CaseToBooking__c
      WHERE Case__c IN :caseIds
    ];
    lstSobjectDelete.addAll(cbList);
    Map<ID, EmailMessage> mapEmailMessages = new Map<ID, EmailMessage>(
      [SELECT Id FROM EmailMessage WHERE ParentId IN :caseIds]
    );
    EmailMessage[] emList = mapEmailMessages.values();
    lstSobjectDelete.addAll(emList);
    //form Objects
    Group_Travel_Request__c[] gtrList = [
      SELECT Id
      FROM Group_Travel_Request__c
      WHERE
        ID IN (SELECT Group_Travel_Request__c FROM Case WHERE ID IN :caseIds)
    ];
    lstSobjectDelete.addAll(gtrList);
    Refund_Request__c[] rfList = [
      SELECT Id
      FROM Refund_Request__c
      WHERE ID IN (SELECT Refund_Request__c FROM Case WHERE ID IN :caseIds)
    ];
    lstSobjectDelete.addAll(rfList);
    Special_Service_Request__c[] ssrList = [
      SELECT Id
      FROM Special_Service_Request__c
      WHERE
        ID IN (SELECT Special_Service_Request__c FROM Case WHERE ID IN :caseIds)
    ];
    lstSobjectDelete.addAll(ssrList);

    setLinkEntityIds.addAll(caseIds);
    setLinkEntityIds.addAll(mapEmailMessages.keySet());
    ContentDocumentLink[] cdlList = [
      SELECT
        Id,
        ContentDocumentId,
        ContentDocument.LatestPublishedVersion.FirstPublishLocationId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :setLinkEntityIds
    ];
    List<ContentDocument> cdDelList = new List<ContentDocument>();
    for (ContentDocumentLink cdl : cdlList) {
      if (
        cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId !=
        null &&
        !setContDocumentIds.contains(
          cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId
        )
      ) {
        cdDelList.add(new ContentDocument(Id = cdl.ContentDocumentId));
        setContDocumentIds.add(
          cdl.ContentDocument.LatestPublishedVersion.FirstPublishLocationId
        );
      }
    }
    lstSobjectDelete.addAll(cdDelList);
    delete cdDelList;

    Set<Id> lcvIds = new Set<Id>();
    for (Integer i = 0, lctSz = lctList.size(); i < lctSz; i++) {
      LiveChatTranscript lct = lctList[i];
      if (lct.LiveChatVisitorId != null)
        lcvIds.add(lct.LiveChatVisitorId);
    }
    if (!lcvIds.isEmpty()) {
      LiveChatVisitor[] lcvList = [
        SELECT Id
        FROM LiveChatVisitor
        WHERE
          Id IN :lcvIds
          AND Id NOT IN (
            SELECT LiveChatVisitorId
            FROM LiveChatTranscript
            WHERE LiveChatVisitorId IN :lcvIds
          )
      ];
      delete lcvList;
    }

    Set<Id> meuIds = new Set<Id>();
    for (Integer i = 0, msSz = msList.size(); i < msSz; i++) {
      MessagingSession ms = msList[i];
      if (ms.MessagingEndUserId != null)
        meuIds.add(ms.MessagingEndUserId);
    }
    if (!meuIds.isEmpty()) {
      MessagingEndUser[] meuList = [
        SELECT Id
        FROM MessagingEndUser
        WHERE
          Id IN :meuIds
          AND Id NOT IN (
            SELECT MessagingEndUserId
            FROM MessagingSession
            WHERE MessagingEndUserId IN :meuIds
          )
      ];
      delete meuList;
    }
  }
  /**
  wipe the related connection to case
  @param caseIds setof CaseIds needs to wiped
  */
  global static void wipeRelatedEntities(Set<Id> caseIds) {
    // Channel Objects
    List<Sobject> lstWipeRelatedRecords = new List<Sobject>();
    lstWipeRelatedRecords.addAll(
      getRelatedRecordsForWiping(
        caseIds,
        MessagingSession.SObjectType,
        'CaseId'
      )
    );
    lstWipeRelatedRecords.addAll(
      getRelatedRecordsForWiping(caseIds, SocialPost.SObjectType, 'parentId')
    );
    lstWipeRelatedRecords.addAll(
      getRelatedRecordsForWiping(
        caseIds,
        LiveChatTranscript.SObjectType,
        'CaseId'
      )
    );
    lstWipeRelatedRecords.addAll(
      getRelatedRecordsForWiping(
        caseIds,
        CaseToBooking__c.SObjectType,
        'Case__c'
      )
    );
    lstWipeRelatedRecords.addAll(
      getRelatedFormRecordsForWiping(
        caseIds,
        Group_Travel_Request__c.SObjectType,
        'Group_Travel_Request__c'
      )
    );
    lstWipeRelatedRecords.addAll(
      getRelatedFormRecordsForWiping(
        caseIds,
        Refund_Request__c.SObjectType,
        'Refund_Request__c'
      )
    );
    lstWipeRelatedRecords.addAll(
      getRelatedFormRecordsForWiping(
        caseIds,
        Special_Service_Request__c.SObjectType,
        'Special_Service_Request__c'
      )
    );

    update lstWipeRelatedRecords;
  }
  /**
  Set the Related records of the case for wiping
  @params caseIds, set of case caseIds
  @params sot The Sobject related to Case
  @params caseField the fields which related the case and related Object
  */
  global static List<Sobject> getRelatedRecordsForWiping(
    Set<Id> caseIds,
    Schema.SObjectType sot,
    String caseField
  ) {
    String sObjName = sot + '';
    String q = 'SELECT Id, CreatedDate';
    q += ' FROM ' + sObjName + ' WHERE ';
    q += caseField + '=:caseIds';
    List<SObject> listSobjects = GDPR_Util.createSobjectFieldsToClear(
      Database.query(q),
      sObjName
    );
    return listSobjects;
  }
  global static List<SObject> getRelatedFormRecordsForWiping(
    Set<Id> caseIds,
    Schema.SObjectType sot,
    String caseField
  ) {
    String sObjName = sot + '';
    String q = 'SELECT Id, CreatedDate FROM ' + sObjName + ' WHERE Id IN ';
    q += '( SELECT ' + caseField + ' FROM CASE WHERE Id IN :caseIds )';
    List<SObject> listSobjects = GDPR_Util.createSobjectFieldsToClear(
      Database.query(q),
      sObjName
    );
    return listSobjects;
  }
}
