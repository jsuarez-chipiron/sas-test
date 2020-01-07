

/**
* @author Sanna Sörberg
* @date 2019-12-20
* @description Test class for social post handler which includes operations performed on social posts
*/

@isTest
private class SocialPostHandler_Test {

/**
Test method for generation of test data used in more than one method
*/
    @TestSetup static void createTestData() {

        List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].CaseReason__c = 'TestReason 1';
        newCases[0].Subject = 'TestCase 2';
        newCases[0].CaseSubReason__c = 'TestSubReason 1';
        newCases[0].CaseTags__c = 'CommonTestTag1;CommonTestTag2';
        insert newCases;
    }
    /**
       Test method for setting field on insert of Social Posts
      */

    @isTest
    static void insertSASPost() {
        List<ManagedSocialAccounts__mdt> socialAccs = [SELECT Id, DeveloperName, Name__c, Provider__c From ManagedSocialAccounts__mdt];
        List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(1);
        socialPosts[0].MessageType = 'Post';
        socialPosts[0].Provider = socialAccs[0].Provider__c;
        socialPosts[0].Handle = socialAccs[0].Name__c;
        insert socialPosts;

        List<SocialPost> updatedSocialPosts = [SELECT Id, IsOutbound, SASPost__c, ReviewedStatus FROM SocialPost];

        system.assertEquals(true, updatedSocialPosts[0].IsOutbound);
        system.assertEquals(true,  updatedSocialPosts[0].SASPost__c);
        system.assertEquals(null, updatedSocialPosts[0].ReviewedStatus);

    }


}