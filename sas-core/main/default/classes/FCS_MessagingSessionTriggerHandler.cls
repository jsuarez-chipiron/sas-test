/**
 * Created by anorell on 2020-01-24.
 */

public with sharing class FCS_MessagingSessionTriggerHandler extends C_TriggerHandler{
    /**
     * Method running before insert for object
     */
    public override void beforeInsert(){
        createCasesForMessagingSessions();
    }

    /**
     * Used to create cases for inbound MessageSessions. Only creates a new case if a case is not supplied in insert.
     */
    private static void createCasesForMessagingSessions() {
        Integer sessionCount = Trigger.new.size();
        MessagingSession[] sessions = (MessagingSession[])Trigger.new;
        Case[] newCases = new Case[]{};
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            if (sessions[i].CaseId == null && sessions[i].Origin == 'InboundInitiated') {
                newCases.add(new Case(
                        Status = 'In Progress',
                        Origin = 'Facebook Messenger',
                        RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION,
                        AccountId = sessions[i].EndUserAccountId,
                        ContactId = sessions[i].EndUserContactId
                ));
            }
        }
        insert newCases;

        for (Integer i = 0; i < sessionCount; i++) {
            if(sessions[i].CaseId == null && sessions[i].Origin == 'InboundInitiated'){
                sessions[i].CaseId = newCases[i].Id;
            }
        }
    }
}