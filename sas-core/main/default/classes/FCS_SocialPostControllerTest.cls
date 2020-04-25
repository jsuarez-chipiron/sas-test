/**
 * @author Philip Ossler
 * @date 2020-04-22
 * @description Test class for FCS_SocialPostController class
 */
@isTest
private class FCS_SocialPostControllerTest {
    @testSetup
    static void testSetup(){
        Profile p = [SELECT id FROM Profile WHERE Name = 'Agent'];
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1];

        User u = new User(
            Alias = 'test',
            Email = 'test@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'sv_SE',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            UserName = 'test@test.com.flysas'
        );
        insert u;

        SocialPost sp1 = new SocialPost(
            Name = 'Test1',
            OwnerId = g.Id
        );
        insert sp1;

        SocialPost sp2 = new SocialPost(
            Name = 'Test2',
            OwnerId = g.Id
        );
        insert sp2;
    }

    @isTest
    static void noSelectedRecords() {
        List<SocialPost> spList = null;

        Test.startTest();
        PageReference pref = Page.FCS_SocialPostTakeOwnershipButton;
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(spList);
            setCon.setSelected(spList);
            FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
            ext.takeOwnership();
        Test.stopTest();
    }

    @isTest
    static void takeOwnershipTest() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User u = [SELECT Id FROM User WHERE LastName = 'test'];
        List<SocialPost> spList = [SELECT Id, Name, OwnerId, FCS_PreviousQueue__c FROM SocialPost];

        System.runAs(thisUser) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SocialMediaUser'];

            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = u.id, 
                PermissionSetId = ps.Id
            );
            insert psa;
        }

        System.runAs(u){
            Test.startTest();
            PageReference pref = Page.FCS_SocialPostTakeOwnershipButton;
                ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(spList);
                setCon.setSelected(spList);
                FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
                ext.takeOwnership();
            Test.stopTest();

            System.assertEquals([SELECT Id FROM User WHERE LastName = 'test'].Id, spList[0].OwnerId);
            System.assertEquals([SELECT Id FROM User WHERE LastName = 'test'].Id, spList[1].OwnerId);
            System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1].Id, spList[0].FCS_PreviousQueue__c);
            System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1].Id, spList[1].FCS_PreviousQueue__c);
        }
    }

    @isTest
    static void removeOwnershipTest() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User u = [SELECT Id FROM User WHERE LastName = 'test'];
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1];
        List<SocialPost> spList = [SELECT Id, Name, OwnerId FROM SocialPost];

        for(SocialPost sp : spList) {
            sp.FCS_PreviousQueue__c = g.Id;
        }
        update spList;

        System.runAs(thisUser) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SocialMediaUser'];
            
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = u.id, 
                PermissionSetId = ps.Id
            );
            insert psa;
        }

        System.runAs(u) {
            Test.startTest();
                PageReference pref = Page.FCS_SocialPostRemoveOwnershipButton;
                ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(spList);
                setCon.setSelected(spList);
                FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
                ext.removeOwnership();
            Test.stopTest();

            System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1].Id, spList[0].OwnerId);
            System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1].Id, spList[1].OwnerId);
        }
    }
}
