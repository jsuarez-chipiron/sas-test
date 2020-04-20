public with sharing class FCS_SocialPostController {

    private final SocialPost sp;
    
    public FCS_SocialPostController() {
        sp = [SELECT Id, Name, OwnerId FROM SocialPost WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }

    public SocialPost getSocialPost() {
        return sp;
    }

    public PageReference save() {
        if(sp.OwnerId == null) {
            sp.OwnerId = UserInfo.getUserId();
        }
    update sp;
    return null;
    }
}
