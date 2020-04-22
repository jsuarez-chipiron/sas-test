public with sharing class FCS_SocialPostController {
    ApexPages.StandardSetController setCon;

    public FCS_SocialPostController(ApexPages.StandardSetController controller) {
        setCon = controller;
    }

    public PageReference takeOwnership() {
        List<SocialPost> spIds = (List<SocialPost>) setCon.getSelected();
        List<SocialPost> spToUpdate = new List<SocialPost>();
        for(SocialPost sp : [SELECT Id, OwnerId, FCS_PreviousQueue__c FROM SocialPost WHERE Id IN :spIds]) {
            sp.OwnerId = UserInfo.getUserId();
            spToUpdate.add(sp);
        }
        update spToUpdate;
        return setCon.cancel();
    }

    public PageReference removeOwnership() {
        List<SocialPost> spIds = (List<SocialPost>) setCon.getSelected();
        List<SocialPost> spToUpdate = new List<SocialPost>();
        for(SocialPost sp : [SELECT Id, OwnerId, FCS_PreviousQueue__c FROM SocialPost WHERE Id IN :spIds]) {
            sp.OwnerId = sp.FCS_PreviousQueue__c;
            spToUpdate.add(sp);
        }
        update spToUpdate;
        return setCon.cancel();
    }
}
