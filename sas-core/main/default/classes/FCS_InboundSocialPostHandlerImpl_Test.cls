/**
 * @author Sanna Sörberg
 * @date 2020-02-16
 * @description Test class for class FCS_InboundSocialPostHandlerImpl
 */
@IsTest
public class FCS_InboundSocialPostHandlerImpl_Test {
    static Map<String, Object> sampleSocialData;
    static FCS_InboundSocialPostHandlerImpl handler;
    static {
        handler = new FCS_InboundSocialPostHandlerImpl();
    }
    static testMethod void verifyNewRecordCreation() {
        List<SocialPost> post = FCS_TestDataFactory.createSocialPosts(1);
        insert post;
        test.startTest();
        handler.handleInboundSocialPost(post[0], null, null);
        test.stopTest();
        SocialPost createdPost = [SELECT Id, ParentId FROM SocialPost];
        System.assertEquals(createdPost.ParentId, null);
    }
}
