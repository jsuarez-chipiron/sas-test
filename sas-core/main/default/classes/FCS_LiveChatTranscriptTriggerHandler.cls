/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Handler class for LivechatTranscriptTrigger. Holds automation related to creating a case for every new LiveChatTranscript for example. 
 */
public class FCS_LiveChatTranscriptTriggerHandler extends C_TriggerHandler {
    public override void beforeUpdate(){
        checkIpWhitelist((List<LiveChatTranscript>) Trigger.new);
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
                if(lct.CaseId == null && lct.Status == 'InProgress'){
                    Case c = new Case();
                    c.FCS_EBNumber__c = lct.FCS_EBNumber__c;
                    c.FCS_CODSId__c = lct.FCS_CODSId__c;
                    c.GDPR_Consent__c = lct.GDPR_Consent__c;
                    c.Status = 'In Progress';
                    c.Origin = 'Chat';
                    c.FCS_Language__c = lct.FCS_Language__c;
                    c.FCS_SurveyLanguage__c = sgSurvey.get(lct.FCS_Language__c);
                    if(lct.FCS_CaseRecordTypeName__c == 'Information'){
						c.RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION;
						c.Type = 'Information';
					}
                    if(lct.FCS_CaseRecordTypeName__c == 'Support'){
						c.RecordTypeId = C_RecordTypeHelper.CASE_SUPPORT;
						c.Type = 'Support';
					}
                    if(lct.FCS_CaseRecordTypeName__c == 'Feedback'){
						c.RecordTypeId = C_RecordTypeHelper.CASE_FEEDBACK;
						c.Type = 'Feedback';
					}
                    cFullList[i] = c;
                    cInsList.add(c);
                }
            }
            insert cInsList;

            //Relating Case to LiveChatTranscript
            for(Integer i=0;i<sz;i++) {
                LiveChatTranscript lct = lctList[i];
                if(lct.CaseId == null && lct.Status == 'InProgress'){
                    lct.CaseId = cFullList[i].Id;
                }
            }

        } catch(Exception e) {
            C_Log.logException(e, null, null);    
        }     
      }
    /**
     * Checks the Ip whitelisting of the chats
     * @param lctList The chat transcript to check for whitelisting
     */
      static void checkIpWhitelist(List<LiveChatTranscript> lctList){
        C_Settings.SettingsGroup sgIpRestriction = C_Settings.getSettings('ChatIpWhitelist');
        Set<String> ipWhiteList = new Set<String>();
        for(String k : sgIpRestriction.keySet()){
            ipWhiteList.add(sgIpRestriction.get(k));
        }
          if(!Test.isRunningTest() && ipWhiteList.size()>0){
              for(LiveChatTranscript lct : lctList){
                  if(!ipWhiteList.contains(lct.IpAddress))lct.addError('Ip Address Not Allowed: '+lct.IpAddress);
              }
          }
      }
}