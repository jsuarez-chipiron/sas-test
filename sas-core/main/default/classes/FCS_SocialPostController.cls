/**
 * @author Philip Ossler
 * @date 2020-04-22
 * @description Class for Take Ownership and Remove Ownership buttons in Social Post List Views
 */
public with sharing class FCS_SocialPostController {
    ApexPages.StandardSetController setCon;
    String retUrl;

    public FCS_SocialPostController(ApexPages.StandardSetController controller) {
        retUrl = ApexPages.currentPage().getParameters().get('vfRetURLInSFX');
        System.debug('URL to redirect: ' + retUrl);
        setCon = controller;
    }

    public PageReference takeOwnership() {
        System.debug('Action Take Ownership executing');
        List<SocialPost> spIds = (List<SocialPost>) setCon.getSelected();

        if(spIds.isEmpty()) {
            //add error message
            return null;
        } else {
            List<SocialPost> spToUpdate = new List<SocialPost>();

            for(SocialPost sp : [SELECT Id, OwnerId, FCS_PreviousQueue__c FROM SocialPost WHERE Id IN :spIds]) {
                sp.OwnerId = UserInfo.getUserId();
                spToUpdate.add(sp);
            }
    
            try {
                update spToUpdate;
            } catch (DmlException dmx) {
                //add error handling
                ApexPages.addMessages(dmx);
                return null;
            }
    
            //Redirect user to listview
            if(String.isNotBlank(retUrl)) {
                System.debug('Redirecting to listview');
                PageReference pageRef = new PageReference(retUrl);
                return pageRef;            
            } else {
                System.debug('retUrl is null');
                return setCon.cancel();
            }
        }
    }

    public PageReference removeOwnership() {
        System.debug('Action Remove Ownership executing');
        List<SocialPost> spIds = (List<SocialPost>) setCon.getSelected();
        
        if(spIds.isEmpty()) {
            //add error message
            return null;
        } else {
            List<SocialPost> spToUpdate = new List<SocialPost>();

            for(SocialPost sp : [SELECT Id, OwnerId, FCS_PreviousQueue__c FROM SocialPost WHERE Id IN :spIds]) {
                if(sp.FCS_PreviousQueue__c != null) {
                    sp.OwnerId = sp.FCS_PreviousQueue__c;
                    spToUpdate.add(sp);
                }
            }
    
            try {
                update spToUpdate;
            } catch (DmlException dmx) {
                //add error handling
                ApexPages.addMessages(dmx);
                return null;
            }
    
            //Redirect user to listview
            if(String.isNotBlank(retUrl)) {
                System.debug('Redirecting to listview');
                PageReference pageRef = new PageReference(retUrl);
                return pageRef;            
            } else {
                System.debug('retUrl is null');
                return setCon.cancel();
            }
        }
    }
}
