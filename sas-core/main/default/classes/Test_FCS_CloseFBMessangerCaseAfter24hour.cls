@isTest
public class Test_FCS_CloseFBMessangerCaseAfter24hour
{
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
        insert new MessagingChannel(
                DeveloperName = 'FacebookChannel2',
                MasterLabel = 'Facebook2',
                MessagingPlatformKey = '123',
                MessageType = 'Facebook'
        );
    }
    /*
       scenario : If the customer contacts after 24 hours once the chat ended, Old Case will be closed  
    */
  public static testMethod void testAutoCloseCaseFbMessanger()
  {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1,null,null,null,null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].FCS_CaseReason__c = 'Baggage';
    lstCases[0].Type = 'Information';
    lstCases[0].RecordTypeId= C_RecordTypeHelper.CASE_INFORMATION;
    insert lstCases;
    
    MessagingChannel[] messagingChannel = [SELECT Id FROM MessagingChannel];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
            MessagingChannelId = messagingChannel[0].Id,
            Name = 'User1',
            MessageType = 'Facebook',
            MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(Date.today().addDays(-2),Time.newInstance(0,0,0,0));
   MessagingSession[] sessions = new MessagingSession[]{};
        sessions.add(new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Ended',
                caseid = lstCases[0].Id,
                MessagingChannelId = messagingChannel[0].Id,
                EndTime = lastRetentionDate
        ));
        
     insert sessions;
     Test.StartTest();     
     Database.executeBatch(new FCS_CloseFBMessangerCaseAfter24hour());
     Test.StopTest();
     Case cse = [Select Id,Status from Case where Id =: lstCases[0].Id];
     System.assertEquals('Closed', cse.Status);
     
  }
  /**
    If the customer contacts with in 24 hours then case will not be in closed
  */
   public static testMethod void testFBMessangerWithin24hours()
  {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1,null,null,null,null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].FCS_CaseReason__c = 'Baggage';
    lstCases[0].Type = 'Information';
    lstCases[0].RecordTypeId= C_RecordTypeHelper.CASE_INFORMATION;
    insert lstCases;
    
    MessagingChannel[] messagingChannel = [SELECT Id FROM MessagingChannel];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
            MessagingChannelId = messagingChannel[0].Id,
            Name = 'User1',
            MessageType = 'Facebook',
            MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(Date.today(),Time.newInstance(0,0,0,0));
   MessagingSession[] sessions = new MessagingSession[]{};
        sessions.add(new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Ended',
                caseid = lstCases[0].Id,
                MessagingChannelId = messagingChannel[0].Id,
                EndTime = lastRetentionDate
        ));
        
     insert sessions;
     Test.StartTest();     
     Database.executeBatch(new FCS_CloseFBMessangerCaseAfter24hour());
     Test.StopTest();
     Case cse = [Select Id,Status from Case where Id =: lstCases[0].Id];
     System.assertEquals('New', cse.Status);
     
  }
  /**
    If the Agent not able to reply due to problem in Chat 
    then case will close after 24 hours
  */
   public static testMethod void testChatEndedDueToError()
  {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1,null,null,null,null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].FCS_CaseReason__c = 'Baggage';
    lstCases[0].Type = 'Information';
    lstCases[0].RecordTypeId= C_RecordTypeHelper.CASE_INFORMATION;
    insert lstCases;
    
    MessagingChannel[] messagingChannel = [SELECT Id FROM MessagingChannel];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
            MessagingChannelId = messagingChannel[0].Id,
            Name = 'User1',
            MessageType = 'Facebook',
            MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(Date.today().addDays(-2),Time.newInstance(0,0,0,0));
   MessagingSession[] sessions = new MessagingSession[]{};
        sessions.add(new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Active',
                caseid = lstCases[0].Id,
                MessagingChannelId = messagingChannel[0].Id,
                AcceptTime = lastRetentionDate
        ));
        
     insert sessions;
     Test.StartTest();     
     Database.executeBatch(new FCS_CloseFBMessangerCaseAfter24hour());
     Test.StopTest();
     Case cse = [Select Id,Status from Case where Id =: lstCases[0].Id];
     System.assertEquals('Closed', cse.Status);
     
  }
   /**
    If the Agent contact with in 24 hours then case will not be closed
  */
   public static testMethod void testFBMessangerActive()
  {
    List<Case> lstCases = FCS_TestDataFactory.createCases(1,null,null,null,null);
    lstCases[0].Origin = 'Facebook Messenger';
    lstCases[0].status = 'New';
    lstCases[0].FCS_CaseReason__c = 'Baggage';
    lstCases[0].Type = 'Information';
    lstCases[0].RecordTypeId= C_RecordTypeHelper.CASE_INFORMATION;
    insert lstCases;
    
    MessagingChannel[] messagingChannel = [SELECT Id FROM MessagingChannel];
    MessagingEndUser messagingEndUser1 = new MessagingEndUser(
            MessagingChannelId = messagingChannel[0].Id,
            Name = 'User1',
            MessageType = 'Facebook',
            MessagingPlatformKey = '123'
    );
    insert messagingEndUser1;
    Datetime lastRetentionDate = DateTime.newInstance(Date.today(),Time.newInstance(0,0,0,0));
   MessagingSession[] sessions = new MessagingSession[]{};
        sessions.add(new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'Active',
                caseid = lstCases[0].Id,
                MessagingChannelId = messagingChannel[0].Id,
                AcceptTime = lastRetentionDate
        ));
        
     insert sessions;
     Test.StartTest();     
     Database.executeBatch(new FCS_CloseFBMessangerCaseAfter24hour());
     Test.StopTest();
     Case cse = [Select Id,Status from Case where Id =: lstCases[0].Id];
     System.assertEquals('New', cse.Status);
     
  }
}