/**
 * @author Sanna Sörberg
 * @date 2020-02-16
* @description Class used to override default Social Inbound Social Handler
 */
global class FCS_InboundSocialPostHandlerImpl implements Social.InboundSocialPostHandler {
    //Modifies default Social Inbound Social Post Handler to never associate a post to a case on creation
    global Social.InboundSocialPostResult handleInboundSocialPost(SocialPost post, SocialPersona persona, Map<String,Object> data) {
        post.ParentId=null;
        Social.InboundSocialPostResult result = new Social.InboundSocialPostResult();
        return result;
    }
}
