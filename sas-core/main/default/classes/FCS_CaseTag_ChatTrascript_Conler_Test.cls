@isTest
private class FCS_CaseTag_ChatTrascript_Conler_Test {    
    @TestSetup static void testDataSetUP()
{
    List<Case> newCases = FCS_TestDataFactory.createCases(1, null, null, null);    
    newCases[0].Subject = 'TestCase 2';
    insert newCases;
    LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv; 
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        lct.caseId=newcases[0].Id;
        insert lct; 
}

 static testmethod void testChatTranscript(){
    
    Test.startTest();
    LiveChatTranscript lvchattran=[Select Id,caseId from LiveChatTranscript Limit 1];
    Case cse = FCS_CaseTag_ChatTranscript_Controller.findCase(lvchattran.Id);
    Test.stopTest();  
    //System.AssertEquals(cse.Id, LiveChatTranscript.caseId);  
} 
}