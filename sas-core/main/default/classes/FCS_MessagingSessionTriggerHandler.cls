/**
 * Created by anorell on 2020-01-24.
 */

public with sharing class FCS_MessagingSessionTriggerHandler extends C_TriggerHandler {
    /**
     * Method running before insert for object
     */
    public override void beforeUpdate() {
        createCasesForMessagingSessions();
    }

    /**
     * Used to create cases for inbound MessageSessions. Only creates a new case if a case is not supplied in insert.
     */
    private static void createCasesForMessagingSessions() {
        Integer sessionCount = Trigger.new.size();
        MessagingSession[] sessions = (MessagingSession[]) Trigger.new;
        List < String > lstChannelEndUserKey = new List < String > ();
        Case[] newCases = new Case[] {};
        boolean OldCaseClosed = false;
        Set < Id > messagingEndUserIds = new Set < Id > ();
        for (MessagingSession s: sessions) {
            messagingEndUserIds.add(s.MessagingEndUserId);
            lstChannelEndUserKey.add(s.ChannelEndUserFormula);
        }
        List < MessagingSession > lstMessingSesions = new List < MessagingSession > ([SELECT
                                                                                    Id,
                                                                                    CaseId,
                                                                                    Case.status,
                                                                                    ChannelEndUserFormula
                                                                                    FROM
                                                                                    MessagingSession
                                                                                    Where
                                                                                    ChannelEndUserFormula =: lstChannelEndUserKey[0]
                                                                                    AND
                                                                                    status != 'Active'
                                                                                    AND
                                                                                    status != 'Waiting'
                                                                                    AND
                                                                                    CaseId != ''
                                                                                    order by
                                                                                    EndTime
                                                                                    Desc
                                                                                    Limit 1
                                                                                    ]);
        Map < Id, MessagingEndUser > meuMap = new Map < Id, MessagingEndUser > ([SELECT
                                                                                Id,
                                                                                AccountId,
                                                                                ContactId
                                                                                FROM
                                                                                MessagingEndUser
                                                                                WHERE
                                                                                Id IN: messagingEndUserIds
                                                                                ]);
        Case cse;
        if (!lstMessingSesions.isEmpty()) {
            cse = [Select
                    FCS_CaseReason__c,
                    FCS_CaseSubReason__c,
                    RecordTypeId,
                    Type,
                    Subject,
                    Description,
                    AccountId,
                    ContactId
                    FROM
                    Case
                    WHERE
                    Id =: lstMessingSesions[0].CaseId
                    LIMIT 1
                  ];
        }      
        for (MessagingSession mesgSesion: sessions) {
            if (!lstMessingSesions.isEmpty()) {
                System.debug('inside 1');
                if (mesgSesion.CaseId == null && mesgSesion.Status == 'Active' && mesgSesion.Origin == 'InboundInitiated') {
                    If(lstMessingSesions[0].Case.Status != 'Closed') {
                        mesgSesion.CaseId = lstMessingSesions[0].CaseId;
                        newCases.add(new Case(Id = lstMessingSesions[0].CaseId, Status = 'New Response'));
                    }
                    else {
                        OldCaseClosed = true;
                        Case cCloneCase = cse.clone(false, false, false, false);
                        cCloneCase.RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION;
                        cCloneCase.Origin = 'Facebook Messenger';
                        newCases.add(cCloneCase);
                    }
                }

            } else {
                if (mesgSesion.CaseId == null && mesgSesion.Status == 'Active' && mesgSesion.Origin == 'InboundInitiated') {
                    OldCaseClosed = true;
                    newCases.add(new Case(Status = 'New',
                        Origin = 'Facebook Messenger',
                        RecordTypeId = C_RecordTypeHelper.CASE_INFORMATION,
                        AccountId = meuMap.get(mesgSesion.MessagingEndUserId).AccountId,
                        ContactId = meuMap.get(mesgSesion.MessagingEndUserId).ContactId
                    ));
                }
            }
        }
        if(!newCases.IsEmpty())
         {
           Upsert newCases;
         } 
        if (OldCaseClosed)
            for (Integer i = 0; i < sessionCount; i++) {
                if (sessions[i].CaseId == null && sessions[i].Status == 'Active' && sessions[i].Origin == 'InboundInitiated') {
                    sessions[i].CaseId = newCases[i].Id;
                }
            }
           
    }
}