public class MentionHandler extends C_TriggerHandler {
    /**
        Set by tests to ensure that the logic in this handler runs during tests
        (ConnectApi failes when not using SeeAllData=true)
    */
    @TestVisible private static Boolean EXECUTE_IN_TEST = false;

    /**
        Validates @-mentions
    */
    public override void afterInsert() {
        validateFeedElement(Trigger.new);
    }

    /**
        Validates @-mentions
    */
    public override void afterUpdate(){
        validateFeedElement(Trigger.new);
    }

    /**
        Method to handle various FeedElements differently
        Retrieves message segments from feed items and feed comments and checks that vendors 
        do cannot refer too each other using @ mentions.
        @param feedElemList THe list of Feed items or feed comments
    */
    private static void validateFeedElement(SObject[] feedElemList) {
        if(!Test.isRunningTest() || EXECUTE_IN_TEST) {
            SObjectType sot = feedElemList.getSObjectType();
            if(sot == FeedItem.SObjectType){
                for(FeedItem fi : (List<FeedItem>) feedElemList) {
                    ConnectApi.FeedElement feed = ConnectApi.ChatterFeeds.getFeedElement(null, fi.Id);
                    List<ConnectApi.MessageSegment> messageSegments = feed.body.messageSegments;
                    String errorMessage = checkMessageSegments(messageSegments, fi.InsertedById);
                    if(errorMessage != null) fi.addError(errorMessage);
                }
            }
            else if(sot == FeedComment.SObjectType){
                for(FeedComment fc : (List<FeedComment>) feedElemList) {
                    ConnectApi.Comment feed = ConnectApi.ChatterFeeds.getComment(null, fc.Id);
                    List<ConnectApi.MessageSegment> messageSegments = feed.body.messageSegments;
                    String errorMessage = checkMessageSegments(messageSegments, fc.CreatedById);
                    if(errorMessage != null) fc.addError(errorMessage);

                }
            }
        }
    }

    /**
        Method to see if posts/comments contain mentions
        @param messageSegments The message segments wihtin a given message
        @param insertedById The id of the user which created the feed item or comment
        @return The error message if there was an illegal @-mention. If legal, null is returned.
    */
    private static String checkMessageSegments(List<ConnectApi.MessageSegment> messageSegments, Id insertedById){
        for(ConnectApi.MessageSegment messageSegment : messageSegments) {
            //Check if post has @mention.
            if(messageSegment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                
                //Check if postUser and mentionedUser are within the same Vendor.
                if(validateMention(insertedById, mentionSegment.record.id)){
                    return 'You don\'t have the permission to mention ' + mentionSegment.name + '.';
                }
            }
        }
        return null;
    }

    /**
        Validation method for mentions when users aren't within the same Vendor
        @param insertedById The user which created the post
        @param mentionedUserId THe user which was mentioned in the post
        @return Whether the mention is illegal
    */
    public static Boolean validateMention(Id insertedById, Id mentionedUserId) {
        //Only apply logic for mentioning users
        if(mentionedUserId.getSobjectType()!=User.SObjectType)return false;
        //Which Vendor does postUser belong to?
        User postUser = [SELECT Vendor__c FROM User WHERE id =: insertedById];
        
        //Which Vendor does mentionedUser belong to?
        User mentionedUser = [SELECT Vendor__c FROM User WHERE id =: mentionedUserId];

        return postUser.Vendor__c != mentionedUser.Vendor__c;
    }
}
