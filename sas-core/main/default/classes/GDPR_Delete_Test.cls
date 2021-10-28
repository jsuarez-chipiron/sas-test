/**
Unit tests for GDPR delete batches to ensure that the correct entities are deleted
@author Peter Södergren
*/
@isTest
private class GDPR_Delete_Test {
  /**
Creates the records used to tests data deletion
*/
  @testSetup
  static void setup() {
    Account[] accs = FCS_TestDataFactory.createFrequentFlyers(2);
    accs[0].LastName = 'TESTACC1';
    accs[1].LastName = 'TESTACC2';
    insert accs;
    Case[] cList = FCS_TestDataFactory.createCases(
      5,
      accs[0].Id,
      accs[0].PersonContactId,
      C_RecordTypeHelper.CASE_SUPPORT,
      'Baggage'
    );
    cList.addAll(
      FCS_TestDataFactory.createCases(
        1,
        accs[0].Id,
        accs[0].PersonContactId,
        C_RecordTypeHelper.CASE_SUPPORT,
        'Baggage'
      )
    );
    List<Del_Sensitive_Data_Based_on_Case_Origin__mdt> lstDelSens = [
      SELECT Id, Case_Origin__c
      FROM Del_Sensitive_Data_Based_on_Case_Origin__mdt
    ];
    cList[0].origin = lstDelSens[0].Case_Origin__c;
    cList[0].Status = 'Closed';
    cList[1].Status = 'Closed';
    cList[2].Status = 'Closed';
    cList[3].Status = 'Closed';
    cList[4].Status = 'Closed';
    cList[5].Status = 'Open';
    insert cList;
    EmailMessage emailMsge = new EmailMessage(
      FromAddress = 'test@example.com.invalid',
      FromName = 'Test',
      Incoming = true,
      Subject = 'TestSubject',
      TextBody = 'TestBody',
      ToAddress = 'test@sas.se'
      // ParentId = cList[0].Id
    );
    insert emailMsge;
    // create ContentVersion record
    ContentVersion conteVersion = new ContentVersion(
      Title = 'SAS Logo',
      PathOnClient = 'Pic.jpg',
      VersionData = Blob.valueOf('SAS Image'),
      IsMajorVersion = true
    );
    insert conteVersion;

    List<ContentDocument> documents = [
      SELECT Id, Title, LatestPublishedVersionId
      FROM ContentDocument
      LIMIT 1
    ];

    //create ContentDocumentLink  record
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = emailMsge.Id;
    cdl.ContentDocumentId = documents[0].Id;
    cdl.ShareType = 'V';
    cdl.Visibility = 'AllUsers';
    insert cdl;

    // insert Attachement
    Attachment obj = new Attachment();
    obj.Body = Blob.valueOf('SAS Image');
    obj.ParentId = emailMsge.Id;
    obj.Name = 'Test.pdf';
    obj.ContentType = 'application/pdf';
    insert obj;

    cList[0].Status = 'Closed';
    update cList;
    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;
    insert new LiveChatTranscript(
      Body = 'Test',
      Status = 'Missed',
      LiveChatVisitorId = lcv.Id
    );
    MessagingChannel mc = new MessagingChannel(
      DeveloperName = 'TESTFB123',
      IsActive = false,
      MasterLabel = 'TESTFB123',
      MessageType = 'Facebook',
      MessagingPlatformKey = 'TESTFB1244567'
    );
    User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(u) {
      insert mc;
    }
    MessagingEndUser meu = new MessagingEndUser(
      AccountId = accs[0].Id,
      ContactId = accs[0].PersonContactId,
      MessageType = 'Facebook',
      Name = 'Test',
      MessagingPlatformKey = 'TESTXYZ',
      MessagingChannelId = mc.Id
    );
    insert meu;
    insert new MessagingSession(
      //CaseId = cList[2].Id,
      MessagingEndUserId = meu.Id,
      Status = 'Ended',
      MessagingChannelId = mc.Id
    );
    SocialPost[] spList = FCS_TestDataFactory.createSocialPosts(1);
    spList[0].Content = 'test';
    insert spList;
    //spList[0].ParentId = cList[3].Id;

    //update spList;
    // booking and flight Data
    DateTime arrivalTime = Datetime.now().adddays(2);
    DateTime departuteTime = Datetime.now().adddays(1);
    List<Flight__c> lstFlights = new List<Flight__c>();
    lstFlights.add(
      FCS_TestDataFactory.createFlights(
        'BNG',
        'CHN',
        arrivalTime,
        departuteTime,
        'MANUAL-1'
      )
    );
    List<Booking__c> lstBookings = FCS_TestDataFactory.createBookings(
      1,
      'OneWay'
    );
    insert lstFlights;
    insert lstBookings;
    List<Passenger__c> lstPassengers = FCS_TestDataFactory.createPassengerss(
      1,
      accs[0].Id,
      lstBookings[0].Id
    );
    insert lstPassengers;
    Segment__c seg = FCS_TestDataFactory.createSegment(
      lstBookings[0].Id,
      lstFlights[0].Id
    );
    insert seg;
  }
  /**
Tests deletion of accounts (Should only occur when the account has no cases or interactions)
*/
  @isTest
  static void deleteAccount() {
    Test.startTest();
    Database.executeBatch(new GDPR_DeleteAccount_Batch());
    Test.stopTest();
    Account[] accList = [SELECT Id, LastName FROM Account];
    System.assertEquals(1, accList.size());
    System.assertNotEquals('TESTACC2', accList[0].LastName);
  }
  /**
Tests wiping of ChatTranscript (Should only occur when the ChatTranscript has no cases or interactions)
*/
  @isTest
  static void wipeChatTranscript() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{ 'Body' };
    gdprwipeInt.setVariables('LiveChatTranscript', 1, 'CaseId', null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    LiveChatTranscript[] lctList = [SELECT Id, body FROM LiveChatTranscript];
    System.assertEquals(null, lctList[0].body);
  }
  /**
Tests wiping of EmailMessage(Should only occur when the EmailMessage has no cases or interactions)
*/
  @isTest
  static void wipeEmailMessage() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{ 'TextBody' };
    gdprwipeInt.setVariables('EmailMessage', 1, 'parentId', null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    EmailMessage[] lctem = [SELECT Id, TextBody FROM EmailMessage];
    System.assertEquals(null, lctem[0].TextBody);
  }

  /**
Tests wiping of SocialPost(Should only occur when the SocialPost has no cases or interactions)
*/
  @isTest
  static void wipeSocialPost() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    GDPR_Util.RETAIN_ADD = new Set<String>{ 'Content' };
    gdprwipeInt.setVariables('SocialPost', 1, 'parentId', null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    SocialPost[] lctSp = [SELECT Id, Content FROM SocialPost];
    System.assertEquals(null, lctSp[0].Content);
  }
  /**
Tests wiping of MessagingSession(Should only occur when the MessagingSession has no cases or interactions)
*/
  @isTest
  static void wipeMessagingSession() {
    GDPR_WipeInteraction_Batch gdprwipeInt = new GDPR_WipeInteraction_Batch();
    gdprwipeInt.setVariables('MessagingSession', 1, 'caseId', null, null);
    gdprwipeInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprwipeInt);
    Test.stopTest();
    MessagingSession[] lctMs = [SELECT Id, GDPR_Wiped__c FROM MessagingSession];
    System.assertEquals(true, lctMs[0].GDPR_Wiped__c);
  }

  /**
Tests deletion of LiveChatTranscript (Should only occur when the LiveChatTranscript has no cases or interactions)
*/
  @isTest
  static void deleteChatTranscript() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables('LiveChatTranscript', 1, 'CaseId', null, null);
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    //LiveChatTranscript[] lctList = [SELECT Id,body from LiveChatTranscript];
    System.assertEquals(
      0,
      [SELECT COUNT() FROM LiveChatTranscript WHERE CaseId != NULL]
    );
  }
  /**
Tests deletion of EmailMessage (Should only occur when the EmailMessage has no cases or interactions)
*/
  @isTest
  static void deleteEmailMessage() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables('EmailMessage', 1, 'parentId', null, null);
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM EmailMessage WHERE parentId != NULL]
    );
  }
  /**
Tests deletion of SocialPost(Should only occur when the SocialPost has no cases or interactions)
*/
  @isTest
  static void deleteSocialPost() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables('SocialPost', 1, 'parentId', null, null);
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM SocialPost WHERE parentId != NULL]
    );
  }
  /**
Tests deletion of MessagingSession(Should only occur when the MessagingSession has no cases or interactions)
*/
  @isTest
  static void deleteMessagingSession() {
    GDPR_DeleteInteraction_Batch gdprDelInt = new GDPR_DeleteInteraction_Batch();
    gdprDelInt.setVariables('MessagingSession', 1, 'caseId', null, null);
    gdprDelInt.lastRetentionDate = dateTime.now().addDays(3);
    Test.startTest();
    Database.executeBatch(gdprDelInt);
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT COUNT() FROM MessagingSession WHERE caseId != NULL]
    );
  }
}
