/**
 * @author Anton Norell
 * @date 2020-02-18
 * @description Test class for FCS_DisplayAccountDataController
 */
@IsTest
private class FCS_DisplayAccountDataController_Test {
    /**
     * Setting up setup objects in setup method
     */
    @TestSetup
    static void createTestData(){
        insert new MessagingChannel(
                DeveloperName = 'FacebookChannel1',
                MasterLabel = 'Facebook1',
                MessagingPlatformKey = '321',
                MessageType = 'Facebook'
        );
    }

    /**
     * Asserts that the correct account id is retrieved from a case record
     */
    @IsTest
    static void shouldReturnAccountIdForCase() {
        Account account = new Account(Name = 'Name');
        insert account;
        Case c = new Case(AccountId = account.Id);
        insert c;

        Id retrievedId = FCS_DisplayAccountDataController.getAccountId(c.Id);

        System.assertEquals(account.Id, retrievedId);
    }

    /**
     * Asserts that the correct account id is retrieved from a chat transcript record
     */
    @IsTest
    static void shouldReturnAccountIdForChatTranscript() {
        Account account = new Account(Name = 'Name');
        insert account;
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        LiveChatTranscript transcript = new LiveChatTranscript(AccountId = account.Id, LiveChatVisitorId = visitor.Id);
        insert transcript;

        Id retrievedId = FCS_DisplayAccountDataController.getAccountId(transcript.Id);

        System.assertEquals(account.Id, retrievedId);
    }

    /**
 * Asserts that the correct account id is retrieved from a messaging session record
 */
    @IsTest
    static void shouldReturnAccountIdForMessagingSession() {
        Account account = new Account(Name = 'Name');
        insert account;
        MessagingChannel messagingChannel = [SELECT Id FROM MessagingChannel LIMIT 1];
        MessagingEndUser messagingEndUser1 = new MessagingEndUser(
                MessagingChannelId = messagingChannel.Id,
                Name = 'User1',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123',
                AccountId = account.Id
        );
        insert messagingEndUser1;
        MessagingSession messagingSession = new MessagingSession(
                Origin = 'AgentInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'New',
                MessagingChannelId = messagingChannel.Id
        );
        insert messagingSession;

        Id retrievedId = FCS_DisplayAccountDataController.getAccountId(messagingSession.Id);

        System.assertEquals(account.Id, retrievedId);
    }
}