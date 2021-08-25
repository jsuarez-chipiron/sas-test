/**
 * @author Anton Norell
 * @date 2020-01-24
 * @description Test class for FCS_MessagingSessionTriggerHandler
 */
@IsTest
private class FCS_MessagingSessionTriggerHandler_Test {

    /**
     * Setting up setup objects in setup method
     */
    @TestSetup
    static void createTestData(){
        insert new MessagingChannel(
                DeveloperName = 'FacebookChannel167',
                MasterLabel = 'Facebook1789',
                MessagingPlatformKey = '32167',
                MessageType = 'Facebook'
        );
        insert new MessagingChannel(
                DeveloperName = 'FacebookChannel278',
                MasterLabel = 'Facebook2ty',
                MessagingPlatformKey = '12378',
                MessageType = 'Facebook'
        );
    }

    /**
     * Asserts that an updated, inbound MessageSessions created cases with the correct values
     */
    @IsTest
    static void shouldCreateNewCasesBasesOnUpdatedMessagingSessions() {
        MessagingChannel[] messagingChannel = [SELECT Id FROM MessagingChannel];
        MessagingEndUser messagingEndUser1 = new MessagingEndUser(
                MessagingChannelId = messagingChannel[0].Id,
                Name = 'User1',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123'
        );
        insert messagingEndUser1;
        MessagingEndUser messagingEndUser2 = new MessagingEndUser(
                MessagingChannelId = messagingChannel[1].Id,
                Name = 'User2',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123'
        );
        insert messagingEndUser2;

        MessagingSession[] sessions = new MessagingSession[]{};
        sessions.add(new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Active',
                MessagingChannelId = messagingChannel[0].Id
        ));
        sessions.add(new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser2.Id,
                Status = 'Active',
                MessagingChannelId = messagingChannel[1].Id
        ));
        insert sessions;

        //Perform update to trigger creation of case. This is done as the status field on MassagingSession cannot be updated.
        update sessions;

        Case[] cases = [SELECT Id FROM Case];
        sessions = [SELECT Id, CaseId, Case.Origin, Case.RecordType.DeveloperName FROM MessagingSession];
        System.assertEquals(2, cases.size());
        System.assertNotEquals(null, sessions[0].CaseId);
        System.assertEquals('Facebook Messenger', sessions[0].Case.Origin);
        System.assertEquals('Chat', sessions[0].Case.RecordType.DeveloperName);
    }


    /**
     * Asserts that cases are not created for MessageSessions that are of outbound origin
     */
     
    @IsTest
    static void shouldNotCreateCaseForOutboundChat() {
        MessagingChannel messagingChannel = [SELECT Id FROM MessagingChannel LIMIT 1];
        MessagingEndUser messagingEndUser1 = new MessagingEndUser(
                MessagingChannelId = messagingChannel.Id,
                Name = 'User1',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123'
        );
        insert messagingEndUser1;

         insert new MessagingSession(
                Origin = 'AgentInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Active',
                MessagingChannelId = messagingChannel.Id
        );
         
        Case[] cases = [SELECT Id FROM Case];
        System.assertEquals(0, cases.size());
    }
    /**
     * Asserts that cases are not created for MessageSessions that are not active
     */
    
    @IsTest
    static void shouldCreateNewCasesBasesOnNewMessagingSessions() {
        MessagingChannel[] messagingChannel = [SELECT Id FROM MessagingChannel];
        MessagingEndUser messagingEndUser1 = new MessagingEndUser(
                MessagingChannelId = messagingChannel[0].Id,
                Name = 'User1',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123'
        );
        insert messagingEndUser1;
       
        MessagingSession session = new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Ended',
                MessagingChannelId = messagingChannel[0].Id
        );
        
         insert session;        
        //Perform update to trigger creation of case. This is done as the status field on MassagingSession cannot be updated.
         update session;
     
         Update Session;
       
      //  System.assertEquals('New Response',cse.Status);
    }  
    }