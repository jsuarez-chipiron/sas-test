/**
    Test class for MentionHandler class
*/
@isTest
private class MentionHandler_Test {
    /**
        Initial setup of users and case
    */
    @testSetup static void testSetup() {
        Profile p = [SELECT id FROM Profile WHERE Name = 'System Administrator'];
        List<User> users = new List<User>();
        
        //Create users
        User u1 = new User(
            Alias = 'user1',
            Email = 'testUser1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'user1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'sv_SE',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            UserName = 'testUser1@test.com.flysas',
            FCS_Vendor__c = 'Sutherland'
        );
        users.add(u1);
        
        User u2 = new User(
            Alias = 'user2',
            Email = 'testUser2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'user2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'sv_SE',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            UserName = 'testUser2@test.com.flysas',
            FCS_Vendor__c = 'Sykes'
        );
        users.add(u2);

            User u3 = new User(
            Alias = 'user3',
            Email = 'testUser3@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'user3',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'sv_SE',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            UserName = 'testUser3@test.com.flysas',
            FCS_Vendor__c = 'Sykes'
        );
        users.add(u3);
        insert(users);

        //Create a Case
        List<Case> cases = new List<Case>();
        Case c = new Case(Status = 'New');
        cases.add(c);
        insert(cases);
    }

    /**
        Tests insert and update of sObjectType FeedItem
    */
    @isTest static void validateFeedItems() {        

        //Create a FeedItem
        Map<Id, FeedItem> feedItems = new Map<Id, FeedItem>();
        FeedItem fi = new FeedItem();
        fi.ParentId = [SELECT id FROM Case].id;
        fi.body = 'TestFeedItem';
        feedItems.put('0D53O000000d8AwSAI', fi);
    }

    /**
        Tests insert and update of sObjectType FeedComment
    */
    @isTest static void validateFeedComments() {  
        //Create a FeedItem
        Map<Id, FeedItem> feedItems = new Map<Id, FeedItem>();
        FeedItem fi = new FeedItem();
        fi.ParentId = [SELECT id FROM Case].id;
        fi.body = 'TestFeedItem';
        feedItems.put('0D53O000000d8AwSAI', fi);
        
        //Create a FeedComment
        Map<Id, FeedComment> feedComments = new Map<Id, FeedComment>();
        FeedComment fc = new FeedComment();
        fc.FeedItemId = fi.id;
        fc.CommentBody = 'TestFeedComment';
        feedComments.put('0D53O000000d8AwSAI', fc);
    }

    /**
        Tests the validation method of Mentions 
    */
    @isTest static void validateUsers() {
        //Retrieval of Users
        List<User> sasUsers = [SELECT id FROM User WHERE FCS_Vendor__c = 'Sutherland'];
        List<User> vendorUsers = [SELECT id FROM User WHERE FCS_Vendor__c = 'Sykes'];
        String User1 = sasUsers[0].id;
        String User2 = vendorUsers[0].id;
        String User3 = vendorUsers[1].id;

        //Users with different Vendors
        System.assertEquals(true,MentionHandler.validateMention(User1, User2));
        //Users with same Vendor
        System.assertEquals(false,MentionHandler.validateMention(User2, User3));
    }
}
