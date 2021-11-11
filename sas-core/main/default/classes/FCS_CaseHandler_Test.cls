/**
 * @author Sanna Sörberg
 * @date 2019-12-01
 * @description Test class for case handler case which includes operations performed on a case
 */

@isTest
private class FCS_CaseHandler_Test {
  private static final String CASE_STATUS_NEW = 'New';
  /**
       Test method for generation of test data used in more than one method
   */
  @TestSetup
  static void createTestUserSetup() {
    PermissionSet socialMediaPermission = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'SocialMediaUser'
    ];
    Profile vendorProfile = [SELECT Id FROM Profile WHERE Name = 'Vendor'];
    List<User> users = FCS_TestDataFactory.createUsers(4);
    insert users;
    PermissionSetAssignment[] assignments = new List<PermissionSetAssignment>{};
    Integer i = 0;
    for (User u : users) {
      u.ProfileId = vendorProfile.Id;
      u.FederationIdentifier = 'SoMe' + i;
      i++;
      assignments.add(
        new PermissionSetAssignment(
          AssigneeId = u.Id,
          PermissionSetId = socialMediaPermission.Id
        )
      );
    }
    insert assignments;
    update users;
  }

  static void createTestData() {
    Integer maxRetriesInDML = 3;
    Integer count = 0;
    boolean retry;
    List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(4);
    insert socialPosts;
    List<Case> newCases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    );
    newCases[0].FCS_CaseReason__c = 'TestReason 1';
    newCases[0].Subject = 'TestCase 2';
    newCases[0].FCS_CaseSubReason__c = 'TestSubReason 1';
    newCases[0].FCS_CaseTags__c = 'CommonTestTag1;CommonTestTag2';
    do {
      retry = false;
      try {
        System.debug('before insert');
        insert newCases;
        System.debug('After Insert');
      } catch (Exception lockerror) {
        count++;
        String lockingissue = String.valueOf(lockerror);
        if (
          lockingissue.contains('UNABLE_TO_LOCK_ROW') &&
          count <= maxRetriesInDML
        ) {
          System.debug('lockingissue' + lockingissue);
          retry = true;
        } else if (
          (!lockingissue.contains('UNABLE_TO_LOCK_ROW')) ||
          count > maxRetriesInDML
        ) {
          throw lockerror;
        }
      }
    } while (retry);
  }
  /**
    Test method for generation of case tag records from case
    Test if case tag records is created on insert of new Case
   */
  @isTest
  static void insertCaseTagRecords() {
    createTestData();
    List<Case> newCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    );
    newCase[0].FCS_CaseReason__c = 'TestReason 1';
    newCase[0].FCS_CaseSubReason__c = 'TestSubReason 1';
    newCase[0].FCS_CaseTags__c = 'TestTag1;TestTag2';
    newCase[0].Subject = 'TestCase';
    insert newCase;
    Case c = [SELECT Id, Subject FROM CASE WHERE Subject = 'TestCase'];
    System.debug('Subject****' + c.Subject);
    List<FCS_CaseTag__c> ctList = [
      SELECT Id, FCS_CaseTag__c, FCS_Type__c
      FROM FCS_CaseTag__c
      WHERE FCS_CaseId__c = :c.Id
    ];
    Map<String, List<FCS_CaseTag__c>> typeToTags = new Map<String, List<FCS_CaseTag__c>>();
    for (FCS_CaseTag__c ct : ctList) {
      if (typeToTags.containsKey(ct.FCS_Type__c)) {
        typeToTags.get(ct.FCS_Type__c).add(ct);
      } else {
        List<FCS_CaseTag__c> ctsTags = new List<FCS_CaseTag__c>();
        ctsTags.add(ct);
        typeToTags.put(ct.FCS_Type__c, ctsTags);
      }
      system.debug(typeToTags);
    }
    System.AssertEquals(
      'TestReason 1',
      typeToTags.get(FCS_CaseHandler.MAIN_TAG)[0].FCS_CaseTag__c
    );
    System.AssertEquals(
      'TestSubReason 1',
      typeToTags.get(FCS_CaseHandler.SUB_MAIN_TAG)[0].FCS_CaseTag__c
    );
    System.AssertEquals(
      2,
      typeToTags.get(FCS_CaseHandler.ADDITIONAL_TAG).size()
    );
    System.AssertEquals(4, ctList.size());
  }
  /**
       Test if case tag records is updated when a case is updated
    */
  @isTest
  static void updateCaseTagRecords() {
    createTestData();
    Case c2 = [SELECT Id FROM CASE WHERE Subject = 'TestCase 2'];
    c2.FCS_CaseReason__c = 'UpdatedTestReason 1';
    c2.FCS_CaseTags__c = 'TestTag2';
    update c2;
    List<FCS_CaseTag__c> ctList = [
      SELECT Id, FCS_CaseTag__c, FCS_Type__c
      FROM FCS_CaseTag__c
      WHERE FCS_CaseId__c = :c2.Id
    ];
    system.debug(ctList);
    Map<String, List<FCS_CaseTag__c>> typeToTags = new Map<String, List<FCS_CaseTag__c>>();
    for (FCS_CaseTag__c ct : ctList) {
      if (typeToTags.containsKey(ct.FCS_Type__c)) {
        typeToTags.get(ct.FCS_Type__c).add(ct);
      } else {
        List<FCS_CaseTag__c> ctsTags = new List<FCS_CaseTag__c>();
        ctsTags.add(ct);
        typeToTags.put(ct.FCS_Type__c, ctsTags);
      }
    }
    System.AssertEquals(
      'UpdatedTestReason 1',
      typeToTags.get(FCS_CaseHandler.MAIN_TAG)[0].FCS_CaseTag__c
    );
    System.AssertEquals(
      'TestSubReason 1',
      typeToTags.get(FCS_CaseHandler.SUB_MAIN_TAG)[0].FCS_CaseTag__c
    );
    System.AssertEquals(1, typeToTags.get(FCS_CaseHandler.MAIN_TAG).Size());
    System.AssertEquals(1, typeToTags.get(FCS_CaseHandler.SUB_MAIN_TAG).Size());
    System.AssertEquals(
      1,
      typeToTags.get(FCS_CaseHandler.ADDITIONAL_TAG).Size()
    );
    System.AssertEquals(1, typeToTags.get(FCS_CaseHandler.MAIN_TAG).Size());
    System.AssertEquals(1, typeToTags.get(FCS_CaseHandler.MAIN_TAG).Size());
    System.AssertEquals(3, ctList.Size());
  }

  /**
       Test if case tag records is deleted if case is deleted
    */
  @isTest
  static void deleteCaseTagRecords() {
    createTestData();
    Case c2 = [SELECT Id FROM CASE WHERE Subject = 'TestCase 2'];
    delete c2;
    System.AssertEquals(
      0,
      [SELECT Id FROM FCS_CaseTag__c WHERE FCS_CaseId__c = :c2.Id].size()
    );
  }

  /**
        Tests that cases (used to save tagging of cases where case is created with status closed) created from social posts is assigned to the owner of the source post if owner is a user
    */
  @isTest
  static void addSocialMediaTag() {
    createTestData();
    List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
    List<User> users = [
      SELECT Id
      FROM User
      WHERE FederationIdentifier LIKE 'SoMe%'
    ];
    for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
      socialPosts[i].OwnerId = users[i].Id;
    }
    update socialPosts;
    Case infoTag = new Case(
      Status = 'Closed',
      Origin = 'Facebook',
      SourceId = socialPosts[0].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION,
      FCS_CaseReason__c = 'Information'
    );
    Case supportTag = new Case(
      Status = 'Closed',
      Origin = 'Twitter',
      SourceId = socialPosts[1].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_FEEDBACK,
      FCS_CaseReason__c = 'Feedback'
    );
    Case feedbackTag = new Case(
      Status = 'Closed',
      Origin = 'Twitter',
      SourceId = socialPosts[2].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_SUPPORT,
      FCS_CaseReason__c = 'Support'
    );
    List<Case> soMeCases = new List<Case>();
    soMeCases.add(infoTag);
    soMeCases.add(supportTag);
    soMeCases.add(feedbackTag);
    insert soMeCases;
    Set<Id> caseIds = new Set<Id>();
    caseIds.add(infoTag.Id);
    caseIds.add(supportTag.Id);
    caseIds.add(feedbackTag.Id);
    List<Case> caseList = [SELECT OwnerId FROM Case WHERE Id = :caseIds];
    System.assertEquals(socialPosts[0].OwnerId, caseList[0].OwnerId);
    System.assertEquals(socialPosts[1].OwnerId, caseList[1].OwnerId);
    System.assertEquals(socialPosts[2].OwnerId, caseList[2].OwnerId);
  }

  /**
      Tests that it is not possible to create a case (as tag eg. in status closed) assigned to the owner of the source post if owner is a user
   */
  @isTest
  static void errorAddSocialMediaTag() {
    createTestData();
    List<SocialPost> socialPosts = [SELECT Id FROM SocialPost LIMIT 1];
    List<User> users = [
      SELECT Id
      FROM User
      WHERE FederationIdentifier = 'SoMe0'
    ];
    List<Group> groupList = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'SoMe_Support'
    ];
    for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
      socialPosts[i].OwnerId = groupList[i].Id;
    }
    update socialPosts;
    Case infoTag = new Case(
      Status = FCS_CaseHandler.CASE_STATUS_CLOSED,
      Origin = 'Facebook',
      SourceId = socialPosts[0].Id,
      RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION
    );
    List<Case> soMeCases = new List<Case>();
    soMeCases.add(infoTag);
    Database.SaveResult result = Database.insert(soMeCases[0], false);
    System.assert(result.isSuccess() == false);
    System.assert(result.getErrors().size() == 1);
  }

  /**  
       Test method for ValidateCaseTags - method check that you can not add a case tag with the same value as the case reason
       Test not to be able to create case with case reason and case tag with same value
    */
  @isTest
  static void testValidateCaseTagsOnInsert() {
    createTestData();
    // Test not to be able to create case with case reason and case tag with same value
    List<Case> newCases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    );
    newCases[0].FCS_CaseReason__c = 'TestReason 1';
    newCases[0].FCS_CaseSubReason__c = 'TestSubReason 1';
    newCases[0].FCS_CaseTags__c = 'TestTag1;TestTag2;TestReason 1';
    newCases[0].Subject = 'ValidateCaseTags';
    Database.SaveResult result = Database.insert(newCases[0], false);
    System.assert(result.isSuccess() == false);
    System.assert(result.getErrors().size() == 1);
    //Test that it is possible to insert with not the same case reason and case tag
    newCases[0].FCS_CaseReason__c = 'TestReason 1';
    newCases[0].FCS_CaseTags__c = 'TestTag2';
    Database.SaveResult result2 = Database.insert(newCases[0], false);
    System.assert(result2.isSuccess() == true);
    System.assert(result2.getErrors().size() == 0);
  }

  /**
     Test method for ValidateCaseTags - method check that you can not add a case tag with the same value as the case reason on update
    */
  @isTest
  static void testValidateCaseTagsOnUpdate() {
    createTestData();
    Case c3 = [SELECT Id FROM CASE WHERE Subject = 'TestCase 2'];
    c3.FCS_CaseReason__c = 'TestReason 1';
    c3.FCS_CaseTags__c = 'CommonTestTag2;TestReason 1';
    Database.SaveResult result3 = Database.update(c3, false);
    System.assert(result3.isSuccess() == false);
    System.assert(result3.getErrors().size() == 1);
    System.AssertEquals(
      0,
      [SELECT Id FROM CASE WHERE FCS_CaseTags__c INCLUDES ('TestReason1')]
        .size()
    );
    System.AssertEquals(
      1,
      [SELECT Id FROM CASE WHERE FCS_CaseTags__c INCLUDES ('CommonTestTag2')]
        .size()
    );
  }

  /**
        Test Method to see if social posts are updated correctly if new case is created from there (not closed).
    */
  @isTest
  static void testUpdateSocialPosts() {
    createTestData();
    List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
    List<User> users = [
      SELECT Id
      FROM User
      WHERE FederationIdentifier LIKE 'SoMe%'
    ];
    for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
      socialPosts[i].OwnerId = users[i].Id;
    }
    List<Case> newCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    );
    newCase[0].FCS_CaseReason__c = 'TestReason 12';
    newCase[0].FCS_CaseSubReason__c = 'TestSubReason 12';
    newCase[0].FCS_CaseTags__c = 'TestTag12;TestTag22';
    newCase[0].Subject = 'TestCase12';
    newCase[0].Status = CASE_STATUS_NEW;
    newCase[0].SourceId = socialPosts[0].Id;
    insert newCase;
    System.AssertEquals(
      true,
      [
        SELECT Id, FCS_CaseCreated__c
        FROM SocialPost
        WHERE Id = :newCase[0].SourceId
      ][0]
      .FCS_CaseCreated__c
    );
  }

  @IsTest
  static void shouldDeleteRelatedSurveyInvitationsOnDelete() {
    Case[] cases = FCS_TestDataFactory.createCases(2, null, null, null, null);
    insert cases;

    delete cases;
  }

  /*@IsTest
  static void creatingACaseWithEmailShouldAssociateItWithAccount() {
    List<Account> lstAcc = FCS_TestDataFactory.createFrequentFlyers(1);
    String testEBNumber = '0123456789';
    lstAcc[0].FCS_EBNumber__c = testEBNumber;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingQuerySuccessMock());
    insert lstAcc;

    Case c = new Case();
    c.SuppliedEmail = lstAcc[0].PersonEmail;

    insert c;

    Test.stopTest();
    Case caseAfterInsert = [
      SELECT AccountId, Id, FCS_EBNumber__c
      FROM Case
      WHERE Id = :c.Id
    ];
    System.AssertEquals(
      testEBNumber,
      caseAfterInsert.FCS_EBNumber__c,
      'The created case should have the accounts EB number.'
    );
    System.AssertEquals(
      lstAcc[0].Id,
      caseAfterInsert.AccountId,
      'The created case should be related to the account with the same email'
    );
  }*/ /* FIXME: Enable this test. The logic works, but current integration implementation doesn't allow for proper mocking.
  @IsTest
  static void creatingACaseWithEmailShouldFetchEBData() {
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingQuerySuccessMock());

    String testEmail = 'test@example.com';
    String testEBNumber = '0123456789';

    Case c = new Case();
    c.SuppliedEmail = testEmail;

    insert c;

    Test.stopTest();
    Case caseAfterInsert = [
      SELECT AccountId, Id, FCS_EBNumber__c
      FROM Case
      WHERE Id = :c.Id
    ];
    System.AssertEquals(
      testEBNumber,
      caseAfterInsert.FCS_EBNumber__c,
      'The created case should have the accounts EB number.'
    );
  }*/ @IsTest
  static void enrichCaseDataBasedOnOriginConfigMatchingOriginShouldFillCorrectData() {
    Case testCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    )[0];
    testCase.Origin = 'Email - Group Sales AT';

    Test.startTest();
    insert testCase;
    Test.stopTest();

    Case testCaseAfterTrigger = [
      SELECT Department__c, Team__c, Type
      FROM Case
      WHERE Id = :testCase.Id
    ][0];

    System.assertEquals(testCaseAfterTrigger.Type, 'Channel');
    System.assertEquals(testCaseAfterTrigger.Department__c, 'Group Sales');
    System.assertEquals(testCaseAfterTrigger.Team__c, 'AT');
  }
  @IsTest
  static void enrichMissingPointsCaseDataIfNrOfFltsNaNIgnore() {
    Case testCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    )[0];
    testCase.Subject = 'flight retro';
    testCase.SuppliedEmail = 'noreply@flysas.com';
    testCase.Description = 'number-of-flights: notanumber\n';

    Test.startTest();
    insert testCase;
    Test.stopTest();

    Case testCaseAfterTrigger = [
      SELECT
        Flight_Info_Missing_Points_X1__c,
        Flight_Info_Missing_Points_X2__c,
        Flight_Info_Missing_Points_X3__c,
        Flight_Info_Missing_Points_X4__c
      FROM Case
      WHERE Id = :testCase.Id
    ][0];

    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X1__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X2__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X3__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X4__c,
      null
    );
  }

  @IsTest
  static void enrichMissingPointsCaseDataPopulateNrOfFieldsAccordingToNrOfFlights() {
    Case testCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    )[0];
    testCase.Subject = 'flight retro';
    testCase.SuppliedEmail = 'noreply@flysas.com';
    testCase.Description =
      'number-of-flights: 1\nmember-first-name: John\nmember-last-name: Doe\nmember-email: test@exampl.com\n' +
      +'eurobonus-number: 123456789\neurobonus-level: pandion\nflight-1\nflight-1-airline: OO\nflight-1-description: This is a test by Eurobonus Digital Team.\n' +
      +'flight-1-flight-no: 1235\nflight-1-ticket-no: 6675234252525\nflight-1-departure-date: 2021-11-11\nflight-1-departure: ARN\nflight-1-arrival: CPH\n' +
      +'flight-1-ticket-first-name: Gochujang\nflight-1-ticket-last-name: Prinsesstårta\nflight-1-booking-class: A\nflight-1-boarding-number: 15\nflight-1-seat-number: \n';

    Test.startTest();
    insert testCase;
    Test.stopTest();

    Case testCaseAfterTrigger = [
      SELECT
        Flight_Info_Missing_Points_X1__c,
        Flight_Info_Missing_Points_X2__c,
        Flight_Info_Missing_Points_X3__c,
        Flight_Info_Missing_Points_X4__c
      FROM Case
      WHERE Id = :testCase.Id
    ][0];

    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X1__c,
      '<b>Airline</b> :  OO<br>' +
      '<b>Description</b> :  This is a test by Eurobonus Digital Team.<br>' +
      '<b>Flight Nr</b> :  1235<br>' +
      '<b>Ticket Nr</b> :  6675234252525<br>' +
      '<b>Departure Date</b> :  2021-11-11<br>' +
      '<b>Departure</b> :  ARN<br>' +
      '<b>Arrival</b> :  CPH<br>' +
      '<b>First Name</b> :  Gochujang<br>' +
      '<b>Last Name</b> :  Prinsesstårta<br>' +
      '<b>Booking Class</b> :  A<br>' +
      '<b>Boarding Number</b> :  15<br>' +
      '<b>Seat Number</b> : null<br>'
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X2__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X3__c,
      null
    );
    System.assertEquals(
      testCaseAfterTrigger.Flight_Info_Missing_Points_X4__c,
      null
    );
  }
}
