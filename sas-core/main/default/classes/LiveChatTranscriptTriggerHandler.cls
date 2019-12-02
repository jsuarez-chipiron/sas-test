/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Handler class for LivechatTranscriptTrigger. Holds automation related to creating a case for every new LiveChatTranscript for example. 
 */
public class LiveChatTranscriptTriggerHandler extends C_TriggerHandler {
    public override void beforeInsert(){ 
		try{
            //Map to hold LiveChatTranscript and Case object.
            Map<Integer, Case> lct_case_map = new Map<Integer, Case>();
           
            //Creating cases for LiveChatTranscripts
            Integer lctId = 0;
            for(LiveChatTranscript lct : (List<LiveChatTranscript>) Trigger.new) {
                if(lct.CaseId == null){
                    Case c = new Case();
                    c.EBNumber__c = lct.EBNumber__c;
                    c.CODSId__c = lct.CODSId__c;
                    c.Status = 'In Progress';
                    c.Origin = 'Chat';
                    if(lct.CaseRecordTypeName__c == 'Information') c.RecordTypeId = RecordTypeHelper.CASE_INFORMATION;
                    if(lct.CaseRecordTypeName__c == 'Support') c.RecordTypeId = RecordTypeHelper.CASE_SUPPORT;
                    if(lct.CaseRecordTypeName__c == 'Feedback') c.RecordTypeId = RecordTypeHelper.CASE_FEEDBACK;
                    lct_case_map.put(lctId, c); 
                    lctId++;
                }
            }
            insert lct_case_map.values();

            //Relating Case to LiveChatTranscript
            Integer lctPos = 0;
            for(LiveChatTranscript lct : (List<LiveChatTranscript>) Trigger.new) {
                lct.CaseId = lct_case_map.get(lctPos).Id;
                lctPos++;
            }

        }catch(Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
            C_log.logexception(e, null, null);    
        }     
  	}
}