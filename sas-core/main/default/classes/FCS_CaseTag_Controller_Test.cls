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
