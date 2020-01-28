/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Handler class for LivechatTranscriptTrigger. Holds automation related to creating a case for every new LiveChatTranscript for example. 
 */
public class FCS_LiveChatTranscriptTriggerHandler extends C_TriggerHandler {
    public override void beforeInsert(){ 
		try{
            LiveChatTranscript[] lctList = (List<LiveChatTranscript>) Trigger.new;
            Integer sz = lctList.size();
            Case[] cFullList = new Case[sz];
            List<Case> cInsList = new List<Case>();
           	

            C_Settings.SettingsGroup sgChat = C_Settings.getSettings('CHAT LANGUAGE');
            C_Settings.SettingsGroup sgSurvey = C_Settings.getSettings('SURVEY LANGUAGE');
            
            List<Id> chatButtonIds = new List<Id>();
            for(LiveChatTranscript lct : lctList) chatButtonIds.add(lct.LiveChatButtonId);
            Map<Id, LiveChatButton> lcbMap = new Map<Id, LiveChatButton>([SELECT Id, toLabel(windowLanguage) FROM LiveChatButton WHERE Id IN :chatButtonIds]);
            
            
            //Creating cases for LiveChatTranscripts
            for(Integer i=0;i<sz;i++) {
                LiveChatTranscript lct = lctList[i];
                if(lct.LiveChatButtonId != null){
                  lct.FCS_Language__c = sgChat.get(lcbMap.get(lct.LiveChatButtonId).windowLanguage);   
                }
                if(lct.CaseId == null){
                    Case c = new Case();
                    c.FCS_EBNumber__c = lct.FCS_EBNumber__c;
                    c.FCS_CODSId__c = lct.FCS_CODSId__c;
                    c.GDPR_Consent__c = lct.GDPR_Consent__c;
                    c.Status = 'In Progress';
                    c.Origin = 'Chat';
                    c.FCS_Language__c = lct.FCS_Language__c;
                    c.FCS_SurveyLanguage__c = sgSurvey.get(lct.FCS_Language__c);
                    if(lct.FCS_CaseRecordTypeName__c == 'Information') c.RecordTypeId = RecordTypeHelper.CASE_INFORMATION;
                    if(lct.FCS_CaseRecordTypeName__c == 'Support') c.RecordTypeId = RecordTypeHelper.CASE_SUPPORT;
                    if(lct.FCS_CaseRecordTypeName__c == 'Feedback') c.RecordTypeId = RecordTypeHelper.CASE_FEEDBACK;
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