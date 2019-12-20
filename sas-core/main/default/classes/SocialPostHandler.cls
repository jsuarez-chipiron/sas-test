/**
 * @author Sanna Sörberg
 * @date 2019-12-20
 * @description Handler class for operations performed on social post object.
 */


public class SocialPostHandler extends C_TriggerHandler {

    /**
Static variable for the review status "Reviewed"
*/
    @TestVisible private static final String STATUS_REVIEWED= 'Reviewed';

    /**
Static variable for the review status "Ignored"
*/
    @TestVisible private static final String STATUS_IGNORE= 'Ignore';

    /**
Static variable for the status "HIDDEN"
*/
    @TestVisible private static final String STATUS_NEEDED= 'Needed';

    /**
Static variable for the status "HIDDEN"
*/
    @TestVisible private static final String STATUS_HIDDEN= 'HIDDEN';


    /**
    Trigger variables
    */
    private List<SocialPost> newSocialPostList;
    private List<SocialPost> oldSocialPostList;
    /**
   Set variables
   */
    public SocialPostHandler() {
        this.newSocialPostList = (List <SocialPost>) Trigger.new;
        this.oldSocialPostList = (List <SocialPost>) Trigger.old;

    }

    /**
   Used to call the trigger in the before insert context
   */
    public override void beforeInsert() {
        SetFieldsOnCreate(newSocialPostList);
    }

    /**
   Used to call the trigger in the before insert context
   */
    public override void afterInsert() {
        UpdatePostStatusOnParent(newSocialPostList, oldSocialPostList);
    }

    /**
  Used to call the trigger in the before update context
  */
    public override void beforeUpdate() {
        UpdatePostStatus(newSocialPostList, oldSocialPostList);
    }


    /**
       Method to set default fields on update on Social Post
       @param newSocialPost list of new version of the social post i.e. the Trigger.new variable
       */
    private static void UpdatePostStatus(List<SocialPost> newSocialPostList, List<SocialPost> oldSocialPostList) {
        Integer sz = newSocialPostList.size();
        List<SocialPost> updatedSocialPosts = new List<SocialPost> ();
        for(Integer i=0;i<sz;i++){
            Boolean handled;
            SocialPost newSp = newSocialPostList[i];
            SocialPost oldSp = oldSocialPostList[i];

            //If post is updated to hidden - the status is updated to hidden and marked as reviewed
            if(newSp.Status!=oldSp.Status && newSp.Status==STATUS_HIDDEN){
                newSp.PostHidden__c= true;
                handled= true;
            }

            //If post is updated to unhidden and unmark done if not other action is taken
            if(newSp.Status!=oldSp.Status && oldSp.Status==STATUS_HIDDEN) {
                newSp.PostHidden__c = false;
                if (!newSp.PostIgnored__c && !newSp.CaseCreated__c && !newSp.PostReplied__c && !newSp.PostLiked__c) {
                    handled = false;
                }
            }

            //If post is updated to ignore - the status is ignored and marked as reviewed
            if(newSp.ReviewedStatus!= oldSp.ReviewedStatus && newSp.ReviewedStatus== STATUS_IGNORE){
                newSp.PostIgnored__c= true;
                handled=true;
            }


            //If parent case is deleted - updated checkbox case created and unmark Done if no other action is taken
            if(newSp.ParentId!=oldSp.ParentId && newSp.ParentId==null) {
                newSp.CaseCreated__c = false;
                system.debug('Här i case');
                if (!newSp.PostIgnored__c && !newSp.PostHidden__c && !newSp.PostReplied__c && !newSp.PostLiked__c) {
                    handled = false;
                    system.debug('Här');
                }
            }

            //If post is updated to liked - The status is updated to liked and marked as reviewed

            if(newSp.Recipient == newSp.LikedBy && newSp.LikedBy!=oldSp.LikedBy){
                newSp.PostLiked__c=true;
                handled=true;
            }

            if(handled!=null && handled){
                newSp.ReviewedStatus=STATUS_REVIEWED;
                newSp.Done__c= true;
            }

            if(handled!= null && !handled){
                newSp.ReviewedStatus=STATUS_NEEDED;
                newSp.Done__c= false;
            }


        }

    }

/**
       Method to set default fields on insert on Social Post
       @param newSocialPost list of new version of the social post i.e. the Trigger.new variable
       */
    private static void UpdatePostStatusOnParent(List<SocialPost> newSocialPostList, List<SocialPost> oldSocialPostList) {
        // Generate set of parentIds to use in query
        Set<Id> parentIds = new Set<Id>();
        List<SocialPost> spRecords = newSocialPostList != null ? newSocialPostList : oldSocialPostList;

        if (spRecords != null) {
            for (SocialPost sp : spRecords) {
                if (sp.IsOutbound && sp.ReplyToId != null) {
                    parentIds.add(sp.ReplyToId);
                }
            }
        }
        if (parentIds != null) {
            List<SocialPost> parentPosts = [SELECT Id, Status FROM SocialPost Where Id = :parentIds];
            List<SocialPost> updatedSocialPosts = new List<SocialPost> ();

            for (SocialPost sp : parentPosts) {
                if (oldSocialPostList == null) {
                    sp.PostReplied__c = true;
                    sp.ReviewedStatus = STATUS_REVIEWED;
                    sp.Done__c = true;
                    updatedSocialPosts.add(sp);
                }
                if (newSocialPostList == null) {
                    sp.PostReplied__c = false;
                    if (!sp.PostIgnored__c && !sp.PostHidden__c && !sp.PostLiked__c && !sp.PostReplied__c) {
                        sp.ReviewedStatus = STATUS_NEEDED;
                        updatedSocialPosts.add(sp);
                    }
                }
            }

            update updatedSocialPosts;
        }
    }


    /**
       Method to set default fields on insert on Social Post
       @param newSocialPost list of new version of the social post i.e. the Trigger.new variable
       */
    private static void SetFieldsOnCreate(List<SocialPost> newSocialPostList) {
        List<ManagedSocialAccounts__mdt> socialAccs = [SELECT Id, DeveloperName, Name__c, Provider__c From ManagedSocialAccounts__mdt];
        List<Group> soMeQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe'];
        Map<String, String> socialPageByProvider = new Map<String, String> ();

        if(socialAccs.size() > 0) {
            for (ManagedSocialAccounts__mdt msa : socialAccs) {
                socialPageByProvider.put(msa.Provider__c, msa.Name__c);
            }
        }
        List<Id> parentIds = new List<Id> ();
        List<Id> parentIdsNext = new List<Id> ();

        for(SocialPost sp : newSocialPostList){
            parentIds.add(sp.ReplyToId);
            if(socialPageByProvider.containsKey(sp.Provider) &&  sp.Handle == socialPageByProvider.get(sp.Provider)){
                sp.IsOutbound = true;
                sp.SASPost__c = true;
                sp.ReviewedStatus = null;
            }
            sp.OwnerId=soMeQueue[0].Id;
        }
        List<SocialPost> parentPosts = [SELECT Id, ReplyToId, Content, Provider, Handle FROM SocialPost Where Id=: parentIds];

        for(SocialPost sp : parentPosts){
            parentIdsNext.add(sp.ReplyToId);
        }
        List<SocialPost> parentPostsNext = [SELECT Id, ReplyToId, Content, Provider, Handle FROM SocialPost Where Id=: parentIdsNext];

        for(Integer i=0,sz=parentPosts.size();i<sz;i++){
            if(parentIds[i]!=null) {
                if(socialPageByProvider.containsKey(parentPosts[i].Provider) && parentPosts[i].Handle == socialPageByProvider.get(newSocialPostList[i].Provider)){
                    newSocialPostList[i].SASPostComment__c = true;
                }
                // newSocialPostList[i].ParentPost__c = parentIds[i];
                newSocialPostList[i].ParentMessage__c =   parentPosts[i].Content;

            }
            if(parentIdsNext[i] != null){
                if(socialPageByProvider.containsKey(parentPostsNext[i].Provider) && parentPostsNext[i].Handle == socialPageByProvider.get(newSocialPostList[i].Provider)){
                    newSocialPostList[i].SASPostComment__c = true;
                }
                //  newSocialPostList[i].ParentPost__c = parentIdsNext[i];
                newSocialPostList[i].ParentMessage__c =   parentPostsNext[i].Content;
                newSocialPostList[i].ParentCommentMessage__c =   parentPosts[i].Content;
            }
        }
    }

}