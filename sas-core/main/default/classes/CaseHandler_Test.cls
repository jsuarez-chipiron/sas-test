/**
* @author Sanna Sörberg
* @date 2019-12-01
* @description Test class for case handler case which includes operations performed on a case
*/

@isTest
private class CaseHandler_Test {

    private static final String CASE_STATUS_NEW= 'New';
    /**
   Test method for generation of test data used in more than one method
  */
    @TestSetup static void createTestData(){
        List<User> users = FCS_TestDataFactory.createUsers(2);
        insert users;
        List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(4);
        insert socialPosts;
        List<Case> newCases  = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].FCS_CaseReason__c = 'TestReason 1';
        newCases[0].Subject = 'TestCase 2';
        newCases[0].FCS_CaseSubReason__c = 'TestSubReason 1';
        newCases[0].CaseTags__c = 'CommonTestTag1;CommonTestTag2';
        insert newCases;
    }

    /**
    Test method for generation of case tag records from case
    Test if case tag records is created on insert of new Case
   */
    @isTest
    static void insertCaseTagRecords() {
        List<Case> newCase = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCase[0].FCS_CaseReason__c = 'TestReason 1';
        newCase[0].FCS_CaseSubReason__c = 'TestSubReason 1';
        newCase[0].CaseTags__c = 'TestTag1;TestTag2';
        newCase[0].Subject = 'TestCase';
        insert newCase;
        Case c = [SELECT Id FROM CASE WHERE Subject = 'TestCase'];
        List<CaseTag__c> ctList = [SELECT Id, CaseTag__c, FCS_Type__c FROM CaseTag__c WHERE CaseId__c = :c.Id];
        Map<String, List<CaseTag__c>> typeToTags = new Map<String, List<CaseTag__c>>();
        for (CaseTag__c ct :ctList) {
            if(typeToTags.containsKey(ct.FCS_Type__c)){
                typeToTags.get(ct.FCS_Type__c).add(ct);
            }
            else {
                List<CaseTag__C> ctsTags = new List<CaseTag__c>();
                ctsTags.add(ct);
                typeToTags.put(ct.FCS_Type__c, ctsTags);
            }
            system.debug(typeToTags);
        }
        System.AssertEquals('TestReason 1', typeToTags.get(CaseHandler.MAIN_TAG)[0].CaseTag__c);
        System.AssertEquals('TestSubReason 1', typeToTags.get(CaseHandler.SUB_MAIN_TAG)[0].CaseTag__c);
        System.AssertEquals(2, typeToTags.get(CaseHandler.ADDITIONAL_TAG).size());
        System.AssertEquals(4, ctList.size());
    }

    //Test if case tag records is updated when a case is updated
    @isTest
    static void updateCaseTagRecords() {
        Case c2 = [SELECT Id FROm CASE WHERE Subject = 'TestCase 2'];
        c2.FCS_CaseReason__c = 'UpdatedTestReason 1';
        c2.CaseTags__c = 'TestTag2';
        update c2;
        List<CaseTag__c> ctList = [SELECT Id, CaseTag__c, FCS_Type__c FROM CaseTag__c WHERE CaseId__c = :c2.Id];
        system.debug(ctList);
        Map<String, List<CaseTag__c>> typeToTags = new Map<String, List<CaseTag__c>>();
        for (CaseTag__c ct :ctList) {
            if (typeToTags.containsKey(ct.FCS_Type__c)) {
                typeToTags.get(ct.FCS_Type__c).add(ct);
            }
            else {
                List<CaseTag__C> ctsTags = new List<CaseTag__c>();
                ctsTags.add(ct);
                typeToTags.put(ct.FCS_Type__c, ctsTags);
            }
        }
        System.AssertEquals('UpdatedTestReason 1', typeToTags.get(CaseHandler.MAIN_TAG)[0].CaseTag__c);
        System.AssertEquals('TestSubReason 1', typeToTags.get(CaseHandler.SUB_MAIN_TAG)[0].CaseTag__c);
        System.AssertEquals(1, typeToTags.get(CaseHandler.MAIN_TAG).Size());
        System.AssertEquals(1, typeToTags.get(CaseHandler.SUB_MAIN_TAG).Size());
        System.AssertEquals(1, typeToTags.get(CaseHandler.ADDITIONAL_TAG).Size());
        System.AssertEquals(1, typeToTags.get(CaseHandler.MAIN_TAG).Size());
        System.AssertEquals(1, typeToTags.get(CaseHandler.MAIN_TAG).Size());
        System.AssertEquals(3, ctList.Size());
    }


    //Test if case tag records is deleted if case is deleted
    @isTest
    static void deleteCaseTagRecords() {
        Case c2 = [SELECT Id FROm CASE WHERE Subject = 'TestCase 2'];
        delete c2;
        System.AssertEquals(0, [SELECT Id From CaseTag__c WHERE CaseId__c =: c2.Id].size());
    }

    /**
		Tests that cases (used to save tagging of cases where case is created with status closed) created from social posts is assigned to the owner of the source post if owner is a user
	*/
    @isTest static void addSocialMediaTag(){
        List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
        List<User> users = [SELECT Id From User];
        for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
            socialPosts[i].OwnerId=users[i].Id;
        }
        update socialPosts;
        Case infoTag = new Case (Status='Closed', Origin='Facebook', SourceId=socialPosts[0].Id, RecordTypeId=RecordTypeHelper.CASE_INFORMATION);
        Case supportTag = new Case (Status='Closed', Origin='Twitter', SourceId=socialPosts[1].Id, RecordTypeId=RecordTypeHelper.CASE_FEEDBACK);
        Case feedbackTag = new Case (Status='Closed', Origin='Twitter', SourceId=socialPosts[2].Id, RecordTypeId=RecordTypeHelper.CASE_SUPPORT);
        List<Case> soMeCases = new List<Case>();
        soMeCases.add(infoTag);
        soMeCases.add(supportTag);
        soMeCases.add(feedbackTag);
        insert soMeCases;
        Set<Id>caseIds = new Set<Id>();
        caseIds.add(infoTag.Id);
        caseIds.add(supportTag.Id);
        caseIds.add(feedbackTag.Id);
        List<Case> caseList = [SELECT OwnerId FROM Case WHERE Id =:caseIds];
        System.assertEquals(socialPosts[0].OwnerId, caseList[0].OwnerId);
        System.assertEquals(socialPosts[1].OwnerId, caseList[1].OwnerId);
        System.assertEquals(socialPosts[2].OwnerId, caseList[2].OwnerId);
    }

    /**
      Tests that it is not possible to create a case (as tag eg. in status closed) assigned to the owner of the source post if owner is a user
  */
    @isTest static void errorAddSocialMediaTag(){
        List<SocialPost> socialPosts = [SELECT Id FROM SocialPost LIMIT 1];
        List<User> users = [SELECT Id FROM User LIMIT 1];
        List<Group>groupList=[SELECT Id FROM Group WHERE Type='Queue'AND DeveloperName='GlobalSupportSoMe'];
        for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
            socialPosts[i].OwnerId=groupList[i].Id;
        }
        update socialPosts;
        Case infoTag = new Case (Status=CaseHandler.CASE_STATUS_CLOSED, Origin='Facebook', SourceId=socialPosts[0].Id, RecordTypeId=RecordTypeHelper.CASE_INFORMATION);
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
    @isTest static void testValidateCaseTagsOnInsert() {
        // Test not to be able to create case with case reason and case tag with same value
        List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].FCS_CaseReason__c = 'TestReason 1';
        newCases[0].FCS_CaseSubReason__c = 'TestSubReason 1';
        newCases[0].CaseTags__c = 'TestTag1;TestTag2;TestReason 1';
        newCases[0].Subject = 'ValidateCaseTags';
        Database.SaveResult result = Database.insert(newCases[0], false);
        System.assert(result.isSuccess() == false);
        System.assert(result.getErrors().size() == 1);
        //Test that it is possible to insert with not the same case reason and case tag
        newCases[0].FCS_CaseReason__c ='TestReason 1';
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
        c3.FCS_CaseReason__c = 'TestReason 1';
        c3.CaseTags__c ='CommonTestTag2;TestReason 1';
        Database.SaveResult result3 = Database.update(c3, false);
        System.assert(result3.isSuccess() == false);
        System.assert(result3.getErrors().size() == 1);
        System.AssertEquals(0, [SELECT Id FROM CASE WHERE CaseTags__c INCLUDES ('TestReason1')].size());
        System.AssertEquals(1, [SELECT Id FROM CASE WHERE CaseTags__c INCLUDES ('CommonTestTag2')].size());
    }

    /**
    Test Method to see if social posts are updated correctly if new case is created from there (not closed).
 */
    @isTest
    static void testUpdateSocialPosts() {
        List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
        List<User> users = [SELECT Id FROM User];
        for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
            socialPosts[i].OwnerId=users[i].Id;
        }
        List<Case> newCase = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCase[0].FCS_CaseReason__c = 'TestReason 12';
        newCase[0].FCS_CaseSubReason__c = 'TestSubReason 12';
        newCase[0].CaseTags__c = 'TestTag12;TestTag22';
        newCase[0].Subject = 'TestCase12';
        newCase[0].Status = CASE_STATUS_NEW;
        newCase[0].SourceId = socialPosts[0].Id;
        insert newCase;
        System.AssertEquals(true, [SELECT Id, FCS_CaseCreated__c FROM SocialPost WHERE Id =:newCase[0].SourceId][0].FCS_CaseCreated__c);
    }
}
