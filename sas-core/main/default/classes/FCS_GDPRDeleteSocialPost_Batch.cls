/**
    Classs used to delete social post interactions
    @author Peter Södergren
*/
global class FCS_GDPRDeleteSocialPost_Batch extends FCS_GDPRDeleteInteraction_Batch{
    /**
        Deletes social post interactions (No social posts are assumed to have consent)
    */
    global FCS_GDPRDeleteSocialPost_Batch() {
        super(SocialPost.SObjectType,SocialPost.ParentId,null,null,false);
    }
}
