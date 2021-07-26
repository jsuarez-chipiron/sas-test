@isTest
public class FCS_CaseTag_Controller_Test {
  @TestSetup
  static void testDataSetUP() {
    List<Case> newCases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    );
    newCases[0].Subject = 'TestCase 2';
    newCases[0].RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
    insert newCases;
    LiveChatVisitor lcv = new LiveChatVisitor();
    insert lcv;
    LiveChatTranscript lct = new LiveChatTranscript();
    lct.LiveChatVisitorId = lcv.Id;
    lct.caseId = newcases[0].Id;
    insert lct;
  }

  static testMethod void testCaseTag() {
    List<Case> lstnewCases = [
      SELECT Id, FCS_Case_Reason__c, Department__c, FCS_CaseType__c
      FROM Case
    ];
    Case cse = new Case(
      Id = lstnewCases[0].Id,
      Department__c = 'Fraud',
      FCS_CaseType__c = 'Fraud',
      FCS_Case_Reason__c = 'CAR',
      FCS_CaseResolution__c = 'Completed'
    );
    update cse;

    LiveChatTranscript chatTrans = [
      SELECT Id, caseId
      FROM LiveChatTranscript
      LIMIT 1
    ];
    Test.startTest();
    FCS_CaseTag__c caseTag = FCS_CaseTag_Controller.findCaseTag(cse.Id);
    System.AssertEquals(caseTag.FCS_CaseId__c, cse.Id);

    FCS_CaseTag__c chatTransCaseTag = FCS_CaseTag_Controller.findCaseTag(
      chatTrans.Id
    );
    System.AssertEquals(chatTransCaseTag.FCS_CaseId__c, chatTrans.CaseId);

    Test.stopTest();
  }
  static testMethod void testfindcase() {
    LiveChatTranscript chatTrans = [
      SELECT Id, caseId
      FROM LiveChatTranscript
      LIMIT 1
    ];
    Test.startTest();

    Case cse = FCS_CaseTag_Controller.findCase(chatTrans.Id);
    System.AssertEquals(cse.Id, chatTrans.CaseId);

    Test.stopTest();
  }
}
