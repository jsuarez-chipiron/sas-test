/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Controller class for the hidden utility to open a case subtab under a chat transcript tab in the SAS Service-console.  
 */
public class Chat_ConsoleAutomationController {
    
    /**
     * Returns a case Id related to a LiveChatTranscript record to open a new subtab for in a service console.
     * 
     * @param transcriptId 	A LiveChatTranscript record Id to retrieve the related case for. 
     * @return 				The case Id to open a new subtab for.		
     */
    @AuraEnabled
    public static Id retrieveRelatedCaseId(Id transcriptId){
        LiveChatTranscript lct = [SELECT Status, CaseId, OwnerId FROM LiveChatTranscript WHERE Id = :transcriptId];
        System.debug('lct status: ' + lct.Status);
        if(lct.Status == 'InProgress'){
            Case c = new Case();
            c.Id = lct.CaseId;
            c.OwnerId = lct.OwnerId;
            update c;
            return lct.CaseId;
        }else{
            return null;   
        }
    }
    
    

}