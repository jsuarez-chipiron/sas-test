/**
* @author Sanna Sörberg
* @date 2019-12-01
* @description Test class for case handler case which includes operations performed on a case
*/

@isTest
private class CaseHandler_Test {

    /**
   Test method for generation of test data used in more than one method
  */
    @TestSetup static void createTestData(){
        List<SocialPost> socialPosts = TestDataFactory.createSocialPosts(2);
        insert socialPosts;
        List<Case> newCases  = TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].CaseReason__c = 'TestReason 1';
        newCases[0].Subject = 'TestCase 2';
        newCases[0].CaseSubReason__c = 'TestSubReason 1';
        newCases[0].CaseTags__c = 'CommonTestTag1;CommonTestTag2';
        insert newCases;
    }

    /**
    Test method for generation of case tag records from case
    Test if case tag records is created on insert of new Case
   */

    @isTest
    static void insertCaseTagRecords() {
        List<Case> newCase  = TestDataFactory.createCases(1, null, null, null, null);
        newCase[0].CaseReason__c = 'TestReason 1';
        newCase[0].CaseSubReason__c = 'TestSubReason 1';
        newCase[0].CaseTags__c = 'TestTag1;TestTag2';
        newCase[0].Subject = 'TestCase';
        insert newCase;
        Case c = [SELECT Id FROM CASE WHERE Subject = 'TestCase'];
        System.AssertEquals('TestReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c = :c.Id AND Type__c = :CaseHandler.MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals('TestSubReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c = :c.Id AND Type__c = :CaseHandler.SUB_MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals(2, [SELECT Id From CaseTag__c Where CaseId__c = :c.Id AND Type__c = :CaseHandler.ADDITIONAL_TAG].Size());
        System.AssertEquals(4, [SELECT Id From CaseTag__c WHERE CaseId__c = :c.Id].size());
    }

    //Test if case tag records is updated when a case is updated
    @isTest
    static void updateCaseTagRecords() {
        Case c2 = [SELECT Id FROm CASE WHERE Subject = 'TestCase 2'];
        c2.CaseReason__c = 'UpdatedTestReason 1';
        c2.CaseTags__c = 'TestTag2';
        update c2;
        System.AssertEquals('UpdatedTestReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c = :c2.Id AND Type__c = :CaseHandler.MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals('TestSubReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c = :c2.Id AND Type__c = :CaseHandler.SUB_MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals(1, [SELECT Id From CaseTag__c Where CaseId__c = :c2.Id AND Type__c = :CaseHandler.MAIN_TAG].Size());
        System.AssertEquals(1, [SELECT Id From CaseTag__c Where CaseId__c = :c2.Id AND Type__c = :CaseHandler.SUB_MAIN_TAG].Size());
        System.AssertEquals(1, [SELECT Id From CaseTag__c Where CaseId__c = :c2.Id AND Type__c = :CaseHandler.ADDITIONAL_TAG].Size());
        System.AssertEquals(3, [SELECT Id From CaseTag__c WHERE CaseId__c = :c2.Id].size());
        System.AssertEquals(0, [SELECT Id From CaseTag__c WHERE CaseId__c != :c2.Id].size());
    }

    //Test if case tag records is deleted if case is deleted
    @isTest
    static void deleteCaseTagRecords() {
        Case c2 = [SELECT Id FROm CASE WHERE Subject = 'TestCase 2'];
        delete c2;
        System.AssertEquals(0, [SELECT Id From CaseTag__c WHERE CaseId__c =: c2.Id].size());
    }

    /**
        Test methods for AssignOwnerFromSoMe-Post
    */
    @isTest
    static void newSocialMediaCases(){
        List<SocialPost> socialPosts = [Select Id FROM SocialPost LIMIT 2];
        Case c1 = new Case (Status='New', Origin='Facebook', SourceId=socialPosts[0].Id);
        Case c2 = new Case (Status='New', Origin='Twitter', SourceId=socialPosts[1].Id);
        List<Case> SoMeCases = new List<Case>();
        SoMeCases.add(c1);
        SoMeCases.add(c2);
        insert SoMeCases;
        System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe'].Id, [SELECT OwnerId FROM Case WHERE Id = :c1.Id].OwnerId);
        System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe'].Id, [SELECT OwnerId FROM Case WHERE Id = :c2.Id].OwnerId);

    }

    /**
       Test method for ValidateCaseTags - method check that you can not add a case tag with the same value as the case reason
       Test not to be able to create case with case reason and case tag with same value
    */
    @isTest
    static void testValidateCaseTagsOnInsert() {
       // Test not to be able to create case with case reason and case tag with same value
        List<Case> newCases = TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].CaseReason__c = 'TestReason 1';
        newCases[0].CaseSubReason__c = 'TestSubReason 1';
        newCases[0].CaseTags__c = 'TestTag1;TestTag2;TestReason 1';
        newCases[0].Subject = 'ValidateCaseTags';
        Database.SaveResult result = Database.insert(newCases[0], false);
        System.assert(result.isSuccess() == false);
        System.assert(result.getErrors().size() == 1);
        //Test that it is possible to insert with not the same case reason and case tag
        newCases[0].CaseReason__c ='TestReason 1';
        newCases[0].CaseTags__c ='TestTag2';
        Database.SaveResult result2 = Database.insert(newCases[0], false);
        System.assert(result2.isSuccess() == true);
        System.assert(result2.getErrors().size() == 0);

    }

    /**
     Test method for ValidateCaseTags - method check that you can not add a case tag with the same value as the case reason on update
  */

    @isTest
    static void testValidateCaseTagsOnUpdate() {
        Case c3 = [SELECT Id FROm CASE WHERE Subject = 'TestCase 2'];
        c3.CaseReason__c = 'TestReason 1';
        c3.CaseTags__c ='CommonTestTag2;TestReason 1';
        Database.SaveResult result3 = Database.update(c3, false);
        System.assert(result3.isSuccess() == false);
        System.assert(result3.getErrors().size() == 1);
        System.AssertEquals(0, [SELECT Id FROM CASE WHERE CaseTags__c INCLUDES ('TestReason1')].size());
        System.AssertEquals(1, [SELECT Id FROM CASE WHERE CaseTags__c INCLUDES ('CommonTestTag2')].size());
    }
}
