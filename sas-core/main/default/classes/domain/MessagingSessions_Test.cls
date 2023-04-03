/**
 * @author Anton Norell
 * @date 2020-01-24
 * @description Test class for MessagingSessions
 */
@IsTest
private class MessagingSessions_Test {
  /**
   * Setting up setup objects in setup method
   */
  @TestSetup
  static void createTestData() {
    insert new MessagingChannel(
      DeveloperName = 'FacebookChannel167',
      MasterLabel = 'Facebook1789',
      MessagingPlatformKey = '32167',
      MessageType = 'Facebook'
    );
  }

  /**
   * Asserts that an updated, inbound MessageSessions created cases with the correct values
   */
  @IsTest
  static void shouldCreateNewCasesBasesOnUpdatedMessagingSessions() {
    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel167'
    ];

    MessagingEndUser messagingEndUser = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser;

    MessagingSession[] sessions = new List<MessagingSession>{};
    sessions.add(
      new MessagingSession(
        Origin = 'InboundInitiated',
        MessagingEndUserId = messagingEndUser.Id,
        Status = 'Active',
        MessagingChannelId = messagingChannel[0].Id
      )
    );

    insert sessions;
    //Perform update to trigger creation of case. This is done as the status field on MassagingSession cannot be updated.
    update sessions;

    Case[] cases = [SELECT Id FROM Case];
    sessions = [
      SELECT Id, CaseId, Case.Origin, Case.RecordType.DeveloperName
      FROM MessagingSession
    ];
    System.assertEquals(1, cases.size());
    System.assertNotEquals(null, sessions[0].CaseId);
    System.assertEquals('Facebook Messenger', sessions[0].Case.Origin);
    System.assertEquals('Chat', sessions[0].Case.RecordType.DeveloperName);
  }

  /**
   * Asserts that cases are not created for MessageSessions that are of outbound origin
   */

  @IsTest
  static void shouldNotCreateCaseForOutboundChat() {
    MessagingChannel[] messagingChannel = [
      SELECT Id
      FROM MessagingChannel
      WHERE DeveloperName = 'FacebookChannel167'
    ];
    MessagingEndUser messagingEndUser = new MessagingEndUser(
      MessagingChannelId = messagingChannel[0].Id,
      Name = 'User1',
      MessageType = 'Facebook',
      MessagingPlatformKey = '123'
    );
    insert messagingEndUser;

    insert new MessagingSession(
      Origin = 'AgentInitiated',
      MessagingEndUserId = messagingEndUser.Id,
      Status = 'Active',
      MessagingChannelId = messagingChannel[0].Id
    );

    Case[] cases = [SELECT Id FROM Case];
    System.assertEquals(0, cases.size());
  }
}
