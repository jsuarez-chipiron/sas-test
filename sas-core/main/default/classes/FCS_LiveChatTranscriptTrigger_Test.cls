/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Test class for the LiveChatTranscriptTriggerHandler and ConsoleAutomationController
 * tested through this class.
 */
@IsTest
public with sharing class FCS_LiveChatTranscriptTrigger_Test {
    
    
    /**
     * Testing LiveChatTranscriptTriggerHandler that will create 
     * a new Case for all LiveChatTranscripts with no attached Case.
     */
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
    
}