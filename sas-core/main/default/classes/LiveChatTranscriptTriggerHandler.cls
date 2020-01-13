/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Handler class for LivechatTranscriptTrigger. Holds automation related to creating a case for every new LiveChatTranscript for example. 
 */
public class LiveChatTranscriptTriggerHandler extends C_TriggerHandler {
    public override void beforeInsert(){ 
		try{
            LiveChatTranscript[] lctList = (List<LiveChatTranscript>) Trigger.new;
            Integer sz = lctList.size();
            Case[] cFullList = new Case[sz];
            List<Case> cInsList = new List<Case>();
           
            //Creating cases for LiveChatTranscripts
            for(Integer i=0;i<sz;i++) {
                LiveChatTranscript lct = lctList[i];
                lct.Language__c = lct.LiveChatButton.windowLanguage.toUpperCase();
                if(lct.CaseId == null){
                    Case c = new Case();
                    c.EBNumber__c = lct.EBNumber__c;
                    c.CODSId__c = lct.CODSId__c;
                    c.Status = 'In Progress';
                    c.Origin = 'Chat';
                    c.Language__c = lct.Language__c;
                    if(lct.CaseRecordTypeName__c == 'Information') c.RecordTypeId = RecordTypeHelper.CASE_INFORMATION;
                    if(lct.CaseRecordTypeName__c == 'Support') c.RecordTypeId = RecordTypeHelper.CASE_SUPPORT;
                    if(lct.CaseRecordTypeName__c == 'Feedback') c.RecordTypeId = RecordTypeHelper.CASE_FEEDBACK;
                    cFullList[i] = c;
                    cInsList.add(c);
                }
            }
            insert cInsList;

            //Relating Case to LiveChatTranscript
            for(Integer i=0;i<sz;i++) {
                LiveChatTranscript lct = lctList[i];
                if(lct.CaseId == null){
                    lct.CaseId = cFullList[i].Id;
                }
            }

        } catch(Exception e) {
            C_Log.logException(e, null, null);    
        }     
  	}
}