public class MentionHandler extends C_TriggerHandler {
    private Map<Id, sObject> newFeed;
    
    public MentionHandler() {
        this.newFeed = (Map<Id, sObject>) Trigger.newMap;
    }

    public MentionHandler(Map<Id, sObject> newFeed) {
		this.newFeed = newFeed;
    }

    public override void afterInsert() {
        validateFeedElement(newFeed);
    }

    public override void afterUpdate(){
        validateFeedElement(newFeed);
    }

    /**
        Method to handle various FeedElements differently
    */
    public static void validateFeedElement(Map<Id, sObject> newFeed) {
        String sObjType = String.valueOf(newFeed.getsobjecttype());

        //If incoming Trigger is FeedItem
        if(sObjType == 'FeedItem') {
            for(FeedItem fi : (List<FeedItem>) newFeed.values()) {
                String communityId = null;
                String feedId = fi.id;
                String insertedById = fi.InsertedById;

                //Get the FeedElement based on the ID.
                if(!Test.isRunningTest()) {
                    ConnectApi.FeedElement feed = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedId);
                    List<ConnectApi.MessageSegment> messageSegments = feed.body.messageSegments;
                    String errorMessage = checkMessageSegments(messageSegments, insertedById);

                    //Show error message if returned from method
                    System.debug(errorMessage);
                    if(errorMessage != null) fi.addError(errorMessage);
                }
            }
        }
        
        //If incoming Trigger is FeedComment
        if(sObjType == 'FeedComment') {
            for(FeedComment fc : (List<FeedComment>) newFeed.values()) {
                String communityId = null;
                String feedId = fc.id;
                String insertedById = fc.CreatedById;

                //Get the Comment based on the ID.
                if(!Test.isRunningTest()) {
                    ConnectApi.FeedElement feed = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedId);
                    List<ConnectApi.MessageSegment> messageSegments = feed.body.messageSegments;
                    String errorMessage = checkMessageSegments(messageSegments, insertedById);

                    //Show error message if returned from method
                    System.debug(errorMessage);
                    if(errorMessage != null) fc.addError(errorMessage);
                }
            }
        }
    }

    /**
        Method to see if posts/comments contain mentions
    */
    private static String checkMessageSegments(List<ConnectApi.MessageSegment> messageSegments, String insertedById){
        //Loop through the various segments.
        for(ConnectApi.MessageSegment messageSegment : messageSegments) {
            //Check if post has @mention.
            if(messageSegment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                System.debug('mentionSegment: ' + mentionSegment.name);
                
                //Check if postUser and mentionedUser are within the same Vendor.
                if(validateMention(insertedById, mentionSegment.record.id)) {
                    System.debug(mentionSegment.name);
                    return 'You don\'t have the permission to mention ' + mentionSegment.name + '.';
                }
            }
        }
        return null;
    }

    /**
        Validation method for mentions when users aren't within the same Vendor
    */
    public static Boolean validateMention(String insertedById, String mentionedUserId) {
        Boolean badMention = false;
        
        //Which Vendor does postUser belong to?
        List<User> postUser = [SELECT Vendor__c FROM User WHERE id =: insertedById];
        String postVendor = postUser[0].Vendor__c;
        System.debug('Vendor of postUser: ' + postVendor);
        
        //Which Vendor does mentionedUser belong to?
        List<User> mentionedUser = [SELECT Vendor__c FROM User WHERE id =: mentionedUserId];
        String mentionedVendor = mentionedUser[0].Vendor__c;
        System.debug('Vendor of mentionedUser: ' + mentionedVendor);
                        
        if(postVendor != mentionedVendor) {
            badMention = true;
        }
        return badMention;
    }
}
