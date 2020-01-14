/**
    Classs used to delete social post interactions
    @author Peter Södergren
*/
global class GDPR_DeleteSocialPost_Batch extends GDPR_DeleteInteraction_Batch{
    /**
        Deletes social post interactions (Social Posts retain consent through their parent case)
    */
    global GDPR_DeleteSocialPost_Batch() {
        super(SocialPost.SObjectType,'DeletePeriodSocialPost','DeletePeriodSocialPostConsent',SocialPost.ParentId,null,null);
    }
}
