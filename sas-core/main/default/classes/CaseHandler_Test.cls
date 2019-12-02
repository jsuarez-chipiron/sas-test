/**
* @author Sanna Sörberg
* @date 2019-12-01
* @description Test class for case handler case which includes operations performed on a case
*/

@isTest
private class CaseHandler_Test {
    private static final String MAIN_TAG = 'Main';
    private static final String SUB_MAIN_TAG = 'Sub';
    private static final String ADDITIONAL_TAG = 'Additional';


    @TestSetup static void createTestData(){
        List<SocialPost> socialPosts = TestDataFactory.createSocialPosts(2);
        insert socialPosts;
    }

    /**
    Test method for generation of case tag records from case
   */

    @isTest
    static void manageCaseTagRecords() {
        // Test if case tag records is created on insert of new Case
        List<Case> newCases = TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].CaseReason__c = 'TestReason 1';
        newCases[0].CaseSubReason__c = 'TestSubReason 1';
        newCases[0].CaseTags__c = 'TestTag1;TestTag2';
        newCases[0].Subject = 'TestCase';
        insert newCases;
        Case c = [SELECT Id FROM CASE WHERE Subject = 'TestCase'];
        System.AssertEquals('TestReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals('TestSubReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:SUB_MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals(2, [SELECT Id From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:ADDITIONAL_TAG].Size());
        System.AssertEquals(4, [SELECT Id From CaseTag__c WHERE CaseId__c =: c.Id].size());

        //Test if case tag records is updated when a case is updated
        newCases[0].CaseReason__c ='UpdatedTestReason 1';
        newCases[0].CaseTags__c ='TestTag2';
        update newCases;
        System.AssertEquals('UpdatedTestReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals('TestSubReason 1', [SELECT Id, CaseTag__c From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:SUB_MAIN_TAG Limit 1][0].CaseTag__c);
        System.AssertEquals(1, [SELECT Id From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:MAIN_TAG].Size());
        System.AssertEquals(1, [SELECT Id From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:SUB_MAIN_TAG].Size());
        System.AssertEquals(1, [SELECT Id From CaseTag__c Where CaseId__c =: c.Id AND Type__c=:ADDITIONAL_TAG].Size());
        System.AssertEquals(3, [SELECT Id From CaseTag__c WHERE CaseId__c =: c.Id].size());
        System.AssertEquals(0, [SELECT Id From CaseTag__c WHERE CaseId__c !=: c.Id].size());

        //Test if case tag records is deleted if case is deleted
        delete newCases;
        System.AssertEquals(0, [SELECT Id From CaseTag__c WHERE CaseId__c =: c.Id].size());
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

}
