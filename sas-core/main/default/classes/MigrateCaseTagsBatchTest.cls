@isTest
private class MigrateCaseTagsBatchTest
{
   @TestSetup 
   static void createTestData()
   {
   
   OldCaseTagtoNewCaseTags__c customsetting = new OldCaseTagtoNewCaseTags__c();
     customsetting.Old_Case_Reason__c = 'COVID-19 Testing';
     customsetting.New_Case_Type__c = 'Travel Information';
     customsetting.New_Case_Reason__c = 'Other';
     customsetting.Name = 'test12';
     
     insert customsetting;
     List<Case> newCases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    );
     newCases[0].Origin = 'Chat';
     newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
     newCases[0].Department__c = 'SoMe Support';
     newCases[0].FCS_CaseReason__c = 'COVID-19 Testing';
     newCases[0].Type = 'Information';
     
     insert newCases;   
   }
   
   @isTest
   static void testChangeCaseRecordforChat()
   {
     Test.startTest();
     Database.executebatch(new MigrateCaseTagsBatch('Chat','SoMe Support','Chat'));
     Test.StopTest();
   }
}