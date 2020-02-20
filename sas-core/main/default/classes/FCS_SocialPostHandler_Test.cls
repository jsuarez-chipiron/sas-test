/**
* @author Sanna Sörberg
* @date 2019-12-20
* @description Test class for social post handler which includes operations performed on social posts
*/

@isTest
private class FCS_SocialPostHandler_Test {

/**
Test method for generation of test data used in more than one method
*/
    @TestSetup static void createTestData() {
        List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(4);
        insert socialPosts;
        List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCases[0].FCS_CaseReason__c = 'TestReason 1';
        newCases[0].Subject = 'TestCase 2';
        newCases[0].FCS_CaseSubReason__c = 'TestSubReason 1';
        newCases[0].FCS_CaseTags__c = 'CommonTestTag1;CommonTestTag2';
        insert newCases;
    }

    /**
    Test method to test to that status fields and checkboxes are updated when hiding/unhiding an post
     */
    @isTest static void testHideAndUnhidePost() {
        SocialPost sp = [SELECT Id, FCS_PostHidden__c FROM SocialPost LIMIT 1];
        sp.Status= FCS_SocialPostHandler.STATUS_HIDDEN;
        update sp;
        SocialPost hiddenSp = [SELECT Id, FCS_PostHidden__c , ReviewedStatus, FCS_Done__c, FCS_PostReplied__c, FCS_PostIgnored__c, FCS_PostLiked__c, FCS_ClosedDate__c, FCS_Reopened__c FROM SocialPost LIMIT 1];
        system.assertEquals(true, hiddenSp.FCS_PostHidden__c);
        system.assertEquals(FCS_SocialPostHandler.STATUS_REVIEWED, hiddenSp.ReviewedStatus);
        system.assertEquals(true, hiddenSp.FCS_Done__c);
        system.assertEquals(false, hiddenSp.FCS_PostReplied__c);
        system.assertEquals(false, hiddenSp.FCS_PostIgnored__c);
        system.assertEquals(false, hiddenSp.FCS_PostLiked__c);
        system.assertEquals(true, hiddenSp.FCS_ClosedDate__c < system.now().addSeconds(10) && hiddenSp.FCS_ClosedDate__c > system.now().addSeconds(-10));
        system.assertEquals(false, hiddenSp.FCS_Reopened__c);
        hiddenSp.Status=null;
        update hiddenSp;
        SocialPost unhiddenSp = [SELECT Id, FCS_PostHidden__c , ReviewedStatus, FCS_Done__c, FCS_PostReplied__c, FCS_PostIgnored__c, FCS_PostLiked__c, FCS_ClosedDate__c, FCS_Reopened__c FROM SocialPost LIMIT 1];
        system.assertEquals(false, unhiddenSp.FCS_PostHidden__c);
        system.assertEquals(FCS_SocialPostHandler.STATUS_NEEDED, unhiddenSp.ReviewedStatus);
        system.assertEquals(false, unhiddenSp.FCS_Done__c);
        system.assertEquals(false, unhiddenSp.FCS_PostReplied__c);
        system.assertEquals(false, unhiddenSp.FCS_PostIgnored__c);
        system.assertEquals(false, unhiddenSp.FCS_PostLiked__c);
        system.assertEquals(null, unhiddenSp.FCS_ClosedDate__c);
        system.assertEquals(true, unhiddenSp.FCS_Reopened__c);
    }

    /**
   Test method to test to that status fields and checkboxes are updated when ignoring a post
    */
    @isTest static void testIgnorePost() {
        SocialPost sp = [SELECT Id, FCS_PostIgnored__c FROM SocialPost LIMIT 1];
        sp.ReviewedStatus= FCS_SocialPostHandler.STATUS_IGNORE;
        update sp;
        SocialPost ignoredSp = [SELECT Id, FCS_PostHidden__c , ReviewedStatus, FCS_Done__c, FCS_PostReplied__c, FCS_PostIgnored__c, FCS_PostLiked__c, FCS_ClosedDate__c, FCS_Reopened__c FROM SocialPost LIMIT 1];
        system.assertEquals(false, ignoredSp.FCS_PostHidden__c);
        system.assertEquals(FCS_SocialPostHandler.STATUS_REVIEWED, ignoredSp.ReviewedStatus);
        system.assertEquals(true, ignoredSp.FCS_Done__c);
        system.assertEquals(false, ignoredSp.FCS_PostReplied__c);
        system.assertEquals(true, ignoredSp.FCS_PostIgnored__c);
        system.assertEquals(false, ignoredSp.FCS_PostLiked__c);
        system.assertEquals(true, ignoredSp.FCS_ClosedDate__c < system.now().addSeconds(10) && ignoredSp.FCS_ClosedDate__c > system.now().addSeconds(-10));
        system.assertEquals(false, ignoredSp.FCS_Reopened__c);
    }



    /**
   Test method to test to that status fields and checkboxes are updated when liking a post
    */
    @isTest static void testLikePost() {
        SocialPost sp = [SELECT Id FROM SocialPost LIMIT 1];
        sp.Recipient='Test1';
        sp.LikedBy='Test1';
        update sp;
        SocialPost likedSp = [SELECT Id, FCS_PostHidden__c , ReviewedStatus, FCS_Done__c, FCS_PostReplied__c, FCS_PostIgnored__c, FCS_PostLiked__c, FCS_ClosedDate__c, FCS_Reopened__c FROM SocialPost LIMIT 1];
        system.assertEquals(false, likedSp.FCS_PostHidden__c);
        system.assertEquals(FCS_SocialPostHandler.STATUS_REVIEWED, likedSp.ReviewedStatus);
        system.assertEquals(true, likedSp.FCS_Done__c);
        system.assertEquals(false, likedSp.FCS_PostReplied__c);
        system.assertEquals(false, likedSp.FCS_PostIgnored__c);
        system.assertEquals(true, likedSp.FCS_PostLiked__c);
        system.assertEquals(true, likedSp.FCS_ClosedDate__c < system.now().addSeconds(10) && likedSp.FCS_ClosedDate__c > system.now().addSeconds(-10));
        system.assertEquals(false, likedSp.FCS_Reopened__c);
    }

    /**
   Test method to test to that parent post is updated with correct status when replying
    */
    @isTest static void replyToPost() {
        SocialPost replyToSp = [SELECT Id FROM SocialPost LIMIT 1];
        List<SocialPost> spList = FCS_TestDataFactory.createSocialPosts(1);
        spList[0].ReplyToId=replyToSp.Id;
        spList[0].IsOutbound=true;
        insert spList;
        SocialPost repliedSp = [SELECT Id, FCS_PostHidden__c , ReviewedStatus, FCS_Done__c, FCS_PostReplied__c, FCS_PostIgnored__c, FCS_PostLiked__c, FCS_ClosedDate__c FROM SocialPost WHERE Id=:replyToSp.Id LIMIT 1];
        system.assertEquals(false, repliedSp.FCS_PostHidden__c);
        system.assertEquals(FCS_SocialPostHandler.STATUS_REVIEWED, repliedSp.ReviewedStatus);
        system.assertEquals(true, repliedSp.FCS_Done__c);
        system.assertEquals(true, repliedSp.FCS_PostReplied__c);
        system.assertEquals(false, repliedSp.FCS_PostIgnored__c);
        system.assertEquals(false, repliedSp.FCS_PostLiked__c);
        system.assertEquals(true, repliedSp.FCS_ClosedDate__c < system.now().addSeconds(10) && repliedSp.FCS_ClosedDate__c > system.now().addSeconds(-10));
    }

    /**
  Test method to test to that status fields and checkboxes are updated when deleting the parent case
   */
    @isTest static void testDeleteParentCase() {
        List<SocialPost> socialPosts = [SELECT Id FROM SocialPost];
        List<User> users = [SELECT Id FROM User];
        for (Integer i = 0, sz = socialPosts.size(); i < sz; i++) {
            socialPosts[i].OwnerId=users[i].Id;
        }
        List<Case> newCase = FCS_TestDataFactory.createCases(1, null, null, null, null);
        newCase[0].FCS_CaseReason__c = 'TestReason 12';
        newCase[0].FCS_CaseSubReason__c = 'TestSubReason 12';
        newCase[0].FCS_CaseTags__c = 'TestTag12;TestTag22';
        newCase[0].Subject = 'TestCase12';
        newCase[0].Status = 'New';
        newCase[0].SourceId = socialPosts[0].Id;
        insert newCase;
        System.AssertEquals(true, [SELECT Id, FCS_CaseCreated__c FROM SocialPost WHERE Id =:newCase[0].SourceId][0].FCS_CaseCreated__c);
        SocialPost sp = [SELECT Id, FCS_CaseCreated__c, ParentId FROM SocialPost LIMIT 1];
        sp.ParentId=null;
        update sp;
        SocialPost parentDeletedSp = [SELECT Id, FCS_PostHidden__c , ReviewedStatus, FCS_Done__c, FCS_PostReplied__c, FCS_PostIgnored__c, FCS_PostLiked__c, FCS_CaseCreated__c, FCS_ClosedDate__c, FCS_Reopened__c FROM SocialPost LIMIT 1];
        system.assertEquals(false, parentDeletedSp.FCS_PostHidden__c);
        system.assertEquals(false, parentDeletedSp.FCS_CaseCreated__c);
        system.assertEquals(FCS_SocialPostHandler.STATUS_NEEDED, parentDeletedSp.ReviewedStatus);
        system.assertEquals(false, parentDeletedSp.FCS_Done__c);
        system.assertEquals(false, parentDeletedSp.FCS_PostReplied__c);
        system.assertEquals(false, parentDeletedSp.FCS_PostIgnored__c);
        system.assertEquals(false, parentDeletedSp.FCS_PostLiked__c);
        system.assertEquals(null, parentDeletedSp.FCS_ClosedDate__c);
        system.assertEquals(true, parentDeletedSp.FCS_Reopened__c);
    }


    /**
    Test method to test to that posts posted from SAS-own site is set with the correct statuses
    */
    @isTest static void insertSASPost() {
        List<ManagedSocialAccounts__mdt> socialAccs = [SELECT Id, DeveloperName, Name__c, Provider__c From ManagedSocialAccounts__mdt];
        List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(1);
        socialPosts[0].MessageType = 'Post';
        socialPosts[0].Provider = socialAccs[0].Provider__c;
        socialPosts[0].Handle = socialAccs[0].Name__c;
        insert socialPosts;
        List<SocialPost> updatedSocialPosts = [SELECT Id, IsOutbound, FCS_SASPost__c, ReviewedStatus FROM SocialPost WHERE Provider=:socialAccs[0].Provider__c AND Handle=: socialPosts[0].Handle];
        system.assertEquals(true, updatedSocialPosts[0].IsOutbound);
        system.assertEquals(true,  updatedSocialPosts[0].FCS_SASPost__c);
        system.assertEquals(null, updatedSocialPosts[0].ReviewedStatus);
    }

/**
   Test method to test to that post inserted never gets attached to a case
   */
    @isTest static void insertCustomerPost() {
        List<SocialPost> socialPosts = FCS_TestDataFactory.createSocialPosts(1);
        socialPosts[0].MessageType = 'Post';
        socialPosts[0].Headline = 'TestPost1';
        socialPosts[0].ParentId = [SELECT Id From Case Limit 1].Id;
        insert socialPosts;
        List<SocialPost> updatedSocialPosts = [SELECT Id, ParentId, ReviewedStatus FROM SocialPost WHERE Headline = 'TestPost1'];
        system.assertEquals(null, updatedSocialPosts[0].ParentId);
        system.assertEquals(FCS_SocialPostHandler.STATUS_NEEDED,  updatedSocialPosts[0].ReviewedStatus);
    }
}