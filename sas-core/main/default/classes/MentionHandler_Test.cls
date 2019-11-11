@isTest (SeeAllData=true)
private class MentionHandler_Test {
    static void testSetup() {
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
            Vendor__c = 'Vendor'
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
            Vendor__c = 'Vendor'
        );
        users.add(u2);
        insert(users);

        //Create a Case
        List<Case> cases = new List<Case>();
        Case c = new Case(Status = 'New');
        cases.add(c);
        insert(cases);
    }

    @isTest static void feedItemMentionUserWithSameVendor() {
        //Run setup to add users and case
        testSetup();
        String sObjType = 'FeedItem';
        List<User> testUsers = [SELECT id FROM User WHERE Vendor__c = 'Vendor'];
        List<Case> testCase = [SELECT id FROM Case];

        //Run as one of the created users to see if they can mention each other
        System.runAs(testUsers[0]) {
            //Create a FeedItem
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            //Create the text of the post
            textSegmentInput.text = 'TestPost';
            messageBodyInput.messageSegments.add(textSegmentInput);

            //Mention a User.
            mentionSegmentInput.id = testUsers[1].id;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;

            //Use a record ID for the subject ID.
            feedItemInput.subjectId = testCase[0].id;

            Test.startTest();
            //Post the FeedItem
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput);
            System.debug('FeedItems' + [SELECT id, body FROM FeedItem WHERE id =: feedElement.id]);
            System.assertEquals(1, [SELECT id FROM FeedItem WHERE id =: feedElement.id].size());
            Test.stopTest();
        }
    }

    @isTest static void feedItemMentionUserWithOtherVendor() {
        //Run setup to add users and case
        testSetup();
        String sObjType = 'FeedItem';
        List<User> testUsers = [SELECT id, Vendor__c FROM User WHERE Vendor__c = 'Vendor'];
        List<Case> testCase = [SELECT id FROM Case];

        //Create a FeedItem
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        //Create the text of the post
        textSegmentInput.text = 'TestPost';
        messageBodyInput.messageSegments.add(textSegmentInput);

        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;

        //Use a record ID for the subject ID.
        feedItemInput.subjectId = testCase[0].id;

        //Post the FeedItem
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput);
        
        //Prepare a new FeedItem to replace the old
        ConnectApi.FeedItemInput feedItemInputEdit = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInputEdit = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInputEdit = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInputEdit = new ConnectApi.TextSegmentInput();

        messageBodyInputEdit.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        //Mention a User with a Vendor
        mentionSegmentInputEdit.id = testUsers[1].id;
        messageBodyInputEdit.messageSegments.add(mentionSegmentInputEdit);

        feedItemInputEdit.body = messageBodyInputEdit;
        
        Test.startTest();
        Boolean expectedError = false;
        try{
            //Update the FeedItem
            ConnectApi.FeedElement editedFeedElement = ConnectApi.ChatterFeeds.updateFeedElement(null, feedElement.id, feedItemInputEdit);
        }
        //Catch the expected error
        catch (Exception e) {
            expectedError = true;
            Boolean expectedErrorMessage = (e.getMessage().contains('You don\'t have the permission to mention ')) ? true : false;
            System.assertEquals(true, expectedErrorMessage, e.getMessage());
        }

        System.assertEquals(true, expectedError, 'No error');
        Test.stopTest();
    }    

    @isTest static void feedCommentMentionUserWithSameVendor() {
        //Run setup to add users and case
        testSetup();
        String sObjType = 'FeedComment';
        List<User> testUsers = [SELECT id, Vendor__c FROM User WHERE Vendor__c = 'Vendor'];
        List<Case> testCase = [SELECT id FROM Case];

        //Create a FeedItem to be able to comment
        FeedItem f = new FeedItem();
        f.ParentId = UserInfo.getUserId();
        f.body = 'test';
        insert f;

        String feedElementId = f.id;

        //Run as one of the created users to see if they can mention each other
        System.runAs(testUsers[0]) {
            //Create a FeedComment
            ConnectApi.CommentInput commentInput = new ConnectApi.CommentInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            //Create the text of the post
            textSegmentInput.text = 'TestComment';
            messageBodyInput.messageSegments.add(textSegmentInput);

            //Mention a User with a Vendor
            mentionSegmentInput.id = testUsers[1].id;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            commentInput.body = messageBodyInput;

            Test.startTest();
            //Post the FeedComment
            ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(null, feedElementId, commentInput, null);
            System.assertEquals(1, [SELECT id FROM FeedComment WHERE FeedItemId =: feedElementId].size());
            System.debug([SELECT id FROM FeedComment WHERE FeedItemId =: feedElementId]);
            Test.stopTest();        
        }
    }

    @isTest static void feedCommentMentionUserWithOtherVendor() {
        //Run setup to add users and case
        testSetup();
        List<User> testUsers = [SELECT id, Vendor__c FROM User WHERE Vendor__c = 'Vendor'];
        List<Case> testCase = [SELECT id FROM Case];

        //Create a FeedItem to be able to comment
        FeedItem f = new FeedItem();
        f.ParentId = UserInfo.getUserId();
        f.body = 'test';
        insert f;

        String feedElementId = f.id;

        //Create a FeedComment
        ConnectApi.CommentInput commentInput = new ConnectApi.CommentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        //Create the text of the post
        textSegmentInput.text = 'TestComment';
        messageBodyInput.messageSegments.add(textSegmentInput);

        commentInput.body = messageBodyInput;

        //Post the FeedComment
        ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(null, feedElementId, commentInput, null);

        //Prepare a new FeedComment to replace the old
        ConnectApi.CommentInput commentInputEdit = new ConnectApi.CommentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInputEdit = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInputEdit = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInputEdit = new ConnectApi.TextSegmentInput();

        messageBodyInputEdit.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        //Mention a User with a Vendor
        mentionSegmentInputEdit.id = testUsers[1].id;
        messageBodyInputEdit.messageSegments.add(mentionSegmentInputEdit);

        commentInputEdit.body = messageBodyInputEdit;

        Test.startTest();
        Boolean expectedError = false;
        try{
            //Update the FeedComment
            ConnectApi.Comment editedComment = ConnectApi.ChatterFeeds.updateComment(null, commentRep.id, commentInputEdit);
        }
        //Catch the expected error
        catch (Exception e) {
            expectedError = true;
            Boolean expectedErrorMessage = (e.getMessage().contains('You don\'t have the permission to mention ')) ? true : false;
            System.assertEquals(true, expectedErrorMessage, e.getMessage());
        }

        System.assertEquals(true, expectedError, 'No error');
        Test.stopTest();
    }
}
