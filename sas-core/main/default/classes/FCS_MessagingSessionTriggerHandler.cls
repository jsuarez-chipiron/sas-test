/**
 * Created by anorell on 2020-01-24.
 */

public with sharing class FCS_MessagingSessionTriggerHandler extends C_TriggerHandler{
    /**
     * Method running before insert for object
     */
    public override void beforeUpdate(){
        createCasesForMessagingSessions();
    }

    /**
     * Used to create cases for inbound MessageSessions. Only creates a new case if a case is not supplied in insert.
     */
    private static void createCasesForMessagingSessions() {
        Integer sessionCount = Trigger.new.size();
        MessagingSession[] sessions = (MessagingSession[])Trigger.new;
        Case[] newCases = new Case[]{};
        Set<Id> messagingEndUserIds = new Set<Id>();
        for(MessagingSession s : sessions){messagingEndUserIds.add(s.MessagingEndUserId);}
        Map<Id, MessagingEndUser> meuMap = new Map<Id, MessagingEndUser>([SELECT Id, AccountId, ContactId FROM MessagingEndUser WHERE Id IN :messagingEndUserIds]);
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            if (sessions[i].CaseId == null && sessions[i].Status == 'Active' && sessions[i].Origin == 'InboundInitiated') {
                newCases.add(new Case(
                        Status = 'In Progress',
                        Origin = 'Facebook Messenger',
                        RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION,
                    	AccountId = meuMap.get(sessions[i].MessagingEndUserId).AccountId,
                    	ContactId = meuMap.get(sessions[i].MessagingEndUserId).ContactId 	
                ));
            }
        }
        insert newCases;

        for (Integer i = 0; i < sessionCount; i++) {
            if(sessions[i].CaseId == null && sessions[i].Status == 'Active' && sessions[i].Origin == 'InboundInitiated'){
                sessions[i].CaseId = newCases[i].Id;
            }
        }
    }
}