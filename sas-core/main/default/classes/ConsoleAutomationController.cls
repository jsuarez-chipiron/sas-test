/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Controller class for the hidden utility to open a case subtab under a chat transcript tab in the SAS Service-console.  
 */
public class ConsoleAutomationController {

    /**
     * Returns a list of object prefixes that are subject to automatically open a tab with a related object. 
     * 
     * @return 			List of object prefixes.		
     */
    @AuraEnabled
    public static List<String> retrievePrefixes(){
        List<String> prefixList = new List<String>();
        prefixList.add(getObjectPrefix('LiveChatTranscript'));
        return prefixList;
    }

    /**
     * Returns and Objects prefix (first three characters).
     * 
     * @param objName 	The API name of the Object
     * @return 			The prefix string of the Object
    */
    private static String getObjectPrefix(String objName){
        Schema.sObjectType sObjType = Schema.getGlobalDescribe().get(objName);
        return sObjType.getDescribe().getKeyPrefix();
    }

    
    /**
     * Returns a list of Object id's to open subtabs for in the Service Cloud console.
     * 
     * @param transcriptId 	An Object Id to open  
     * @return 				The case Id to open a new subtab for.		
     */
    @AuraEnabled
    public static List<Id> retrieveRelated(Id objId){
        List<Id> returnObjIds = new List<Id>();
        String objType = objId.getSObjectType().getDescribe().getName();

        if(objType == 'LiveChatTranscript'){
            LiveChatTranscript lct = [SELECT Status, CaseId, OwnerId FROM LiveChatTranscript WHERE Id = :objId];
            if(lct.Status == 'InProgress'){
                Case c = new Case(id = lct.CaseId);
                c.OwnerId = lct.OwnerId;
                update c;
                returnObjIds.add(c.Id);
            }
        }
        return returnObjIds;        
    }
}