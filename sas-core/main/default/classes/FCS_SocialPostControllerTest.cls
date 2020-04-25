/**
 * @author Philip Ossler
 * @date 2020-04-22
 * @description Test class for FCS_SocialPostController class
 */
@isTest
private class FCS_SocialPostControllerTest {
    @testSetup
    static void testSetup(){
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1];

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
    static void takeOwnershipTest() {
        Profile p = [SELECT id FROM Profile WHERE Name = 'Agent'];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SocialMediaUser'];
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1];
        List<SocialPost> spList = [SELECT Id, Name, OwnerId, FCS_PreviousQueue__c FROM SocialPost];

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

        
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = u.id, 
                PermissionSetId = ps.Id
            );
            insert psa;
        }

        System.runAs(u){
            Test.startTest();
                ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(spList);
                
                try {
                    FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
                    ext.takeOwnership();
                } catch(DmlException e) {
                    System.debug(e);
                }
                
                setCon.setSelected(spList);
                FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
                ext.takeOwnership();
            Test.stopTest();
        }

        System.assertEquals(u.Id, spList[0].OwnerId);
        System.assertEquals(u.Id, spList[1].OwnerId);
        
        //Assert of Social Post Process Builder
        System.assertEquals(g.Id, spList[0].FCS_PreviousQueue__c);
        System.assertEquals(g.Id, spList[1].FCS_PreviousQueue__c);
    }

    @isTest
    static void removeOwnershipTest() {
        Profile p = [SELECT id FROM Profile WHERE Name = 'Agent'];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SocialMediaUser'];
        Group g = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe' LIMIT 1];
        List<SocialPost> spList = [SELECT Id, Name, OwnerId FROM SocialPost];

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

        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = u.id, 
                PermissionSetId = ps.Id
            );
            insert psa;

            for(SocialPost sp : spList) {
                sp.OwnerId = u.Id;
                sp.FCS_PreviousQueue__c = g.Id;
            }
            update spList;
        }

        System.runAs(u) {
            Test.startTest();
                ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(spList);
                    
                try {
                    FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
                    ext.removeOwnership();
                } catch(DmlException e) {
                    System.debug(e);
                }
                
                setCon.setSelected(spList);
                FCS_SocialPostController ext = new FCS_SocialPostController(setCon);
                ext.removeOwnership();
            Test.stopTest();
        }

        System.assertEquals(g.Id, spList[0].OwnerId);
        System.assertEquals(g.Id, spList[1].OwnerId);
    }
}
