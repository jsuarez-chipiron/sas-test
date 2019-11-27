/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Test class for the LiveChatTranscriptTriggerHandler 
 * tested through this class.
 */
@IsTest
public with sharing class LiveChatTranscriptTriggerHandler_Test {
    
    //Testing LiveChatTranscriptTriggerHandler that will create a new Case for all Live Chat Transcripts with no attached Case.
    @IsTest
    static void testCaseCreatedSuccess(){
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv; 
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        insert lct; 
        Id expCaseId = [SELECT CaseId FROM LiveChatTranscript WHERE Id = :lct.Id].CaseId;
        System.assertNotEquals(expCaseId, null);
    }
    
    //Testing Chat_ConsoleAutomationController that will find and return the CaseId to a LiveChatTranscript record
    @IsTest
    static void testRetrieveRelatedCaseIdStatusInProgress(){
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv; 
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        lct.Status = 'InProgress';
        insert lct; 
        
        Id caseId = Chat_ConsoleAutomationController.retrieveRelatedCaseId(lct.Id);
        Id expCaseId = [SELECT CaseId FROM LiveChatTranscript WHERE Id = :lct.Id].CaseId;
        System.assertEquals(expCaseId, caseId);
    }
    
    //Testing Chat_ConsoleAutomationController exception that will return null if the LiveChatTranscript status isn't InProgress
    @IsTest
    static void testRetrieveRelatedCaseIdStatusNew(){
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv; 
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        insert lct; 
        
        Id caseId = Chat_ConsoleAutomationController.retrieveRelatedCaseId(lct.Id);
        
        System.assertEquals(null, caseId);
    }
    

}