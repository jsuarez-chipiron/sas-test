/**
    Classs used to delete social post interactions
    @author Peter Södergren
*/
global class GDPR_DeleteSocialPost_Batch extends GDPR_DeleteInteraction_Batch{
    /**
        Deletes social post interactions (No social posts are assumed to have consent)
    */
    global GDPR_DeleteSocialPost_Batch() {
        super(SocialPost.SObjectType,SocialPost.ParentId,null,null,false);
    }
}
