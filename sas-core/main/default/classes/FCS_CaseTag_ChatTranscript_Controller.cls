public  class FCS_CaseTag_ChatTranscript_Controller {
    public static Case cse{get;set;}
    public FCS_CaseTag_ChatTranscript_Controller() 
    {
    }
    @AuraEnabled(cacheable=true)
    public static Case findCase(string recordId){
        cse = [SELECT
               Id,
               RecordTypeId
               FROM Case
               WHERE
               id In (Select CaseId from LiveChatTranscript where id=:recordId)
               ];
         system.debug('cse@@@@'+cse);      
        return cse;
    }
}
