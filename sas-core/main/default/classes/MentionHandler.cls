public class MentionHandler extends C_TriggerHandler {
    private Map<Id, sObject> newFeed;
    
    public MentionHandler() {
        this.newFeed = (Map<Id, sObject>) Trigger.newMap;
    }
    
    public override void afterInsert() {
        String sObjType = String.valueOf(newFeed.getsobjecttype());

        //If incoming Trigger is FeedItem
        if(sObjType == 'FeedItem') {
            for(FeedItem fi : (List<FeedItem>) Trigger.new) {
                String communityId = null;
                String feedId = fi.id;
                String insertedById = fi.InsertedById;
                String errorMessage = feedItemMentions(communityId, feedId, insertedById);
                
                //Show error message if returned from method
                System.debug(errorMessage);
                if(errorMessage != null) fi.addError(errorMessage);
            }
        }
        
        //If incoming Trigger is FeedItem
        if(sObjType == 'FeedComment') {
            for(FeedComment fc : (List<FeedComment>) Trigger.new) {
                System.debug(fc);
                String communityId = null;
                String feedId = fc.id;
                String insertedById = fc.CreatedById;
                String errorMessage = feedCommentMentions(communityId, feedId, insertedById);
                
                //Show error message if returned from method
                System.debug(errorMessage);
                if(errorMessage != null) fc.addError(errorMessage);
            }
        }
    }

    public override void afterUpdate(){
        String sObjType = String.valueOf(newFeed.getsobjecttype());

        //If incoming Trigger is FeedItem
        if(sObjType == 'FeedItem') {
            for(FeedItem fi : (List<FeedItem>) Trigger.new) {
                String communityId = null;
                String feedId = fi.id;
                String insertedById = fi.InsertedById;
                String errorMessage = feedItemMentions(communityId, feedId, insertedById);
                
                //Show error message if returned from method
                System.debug(errorMessage);
                if(errorMessage != null) fi.addError(errorMessage);
            }
        }
        
            //If incoming Trigger is FeedItem
            if(sObjType == 'FeedComment') {
            for(FeedComment fc : (List<FeedComment>) Trigger.new) {
                System.debug(fc);
                String communityId = null;
                String feedId = fc.id;
                String insertedById = fc.CreatedById;
                String errorMessage = feedCommentMentions(communityId, feedId, insertedById);
                
                //Show error message if returned from method
                System.debug(errorMessage);
                if(errorMessage != null) fc.addError(errorMessage);
            }
        }
    }

    //Method to check FeedItem mentions
    public static String feedItemMentions(String communityId, String feedId, String insertedById) {
        //System.debug('feedId: ' + feedId);
        //System.debug('postUserId: ' + insertedById);
        
        //Get the FeedElement based on the ID.
        ConnectApi.FeedElement feed = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedId);
        List<ConnectApi.MessageSegment> messageSegments = feed.body.messageSegments;

        //Loop through the various segments.
        for(ConnectApi.MessageSegment messageSegment : messageSegments) {
            
            //Check if post has @mention.
            if(messageSegment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                System.debug('mentionSegment: ' + mentionSegment.name);

                //Which Vendor does postUser belong to?
                List<User> postUser = [SELECT Vendor__c FROM User WHERE id =: insertedById];
                String postVendor = postUser[0].Vendor__c;
                System.debug('Vendor of postUser: ' + postVendor);
                
                //Which Vendor does mentionedUser belong to?
                List<User> mentionedUser = [SELECT Vendor__c FROM User WHERE id =: mentionSegment.record.id];
                String mentionedVendor = mentionedUser[0].Vendor__c;
                System.debug('Vendor of mentionedUser: ' + mentionedVendor);
                
                //Check if postUser and mentionedUser are within the same Vendor.
                if(postVendor != mentionedVendor) {
                    System.debug(mentionSegment.name);
                    return 'You don\'t have the permission to mention ' + mentionSegment.name + '.';
                }
            }
        }
        return null;
    }

        //Method to check FeedComments mentions
        public static String feedCommentMentions(String communityId, String feedId, String insertedById) {
        //System.debug('feedId: ' + feedId);
        //System.debug('postUserId: ' + insertedById);
        
        //Get the Comment based on the ID.
        ConnectApi.Comment feed = ConnectApi.ChatterFeeds.getComment(communityId, feedId);
        List<ConnectApi.MessageSegment> messageSegments = feed.body.messageSegments;

        //Loop through the various segments.
        for(ConnectApi.MessageSegment messageSegment : messageSegments) {
            
            //Check if post has @mention.
            if(messageSegment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                System.debug('mentionSegment: ' + mentionSegment.name);

                //Which Vendor does postUser belong to?
                List<User> postUser = [SELECT Vendor__c FROM User WHERE id =: insertedById];
                String postVendor = postUser[0].Vendor__c;
                System.debug('Vendor of postUser: ' + postVendor);
                
                //Which Vendor does mentionedUser belong to?
                List<User> mentionedUser = [SELECT Vendor__c FROM User WHERE id =: mentionSegment.record.id];
                String mentionedVendor = mentionedUser[0].Vendor__c;
                System.debug('Vendor of mentionedUser: ' + mentionedVendor);
                
                //Check if postUser and mentionedUser are within the same Vendor.
                if(postVendor != mentionedVendor) {
                    System.debug(mentionSegment.name);
                    return 'You don\'t have the permission to mention ' + mentionSegment.name + '.';
                }
            }
        }
        return null;
    }
}
