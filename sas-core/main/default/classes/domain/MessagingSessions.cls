public without sharing class MessagingSessions extends ApplicationDomain {
  public MessagingSessions(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<MessagingSession>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new MessagingSessions(records);
    }
  }

  private List<MessagingSession> instanceRecords;

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    createCasesForMessagingSessions();
  }

  /**
   * Used to create cases for inbound MessageSessions. Only creates a new case if a case is not supplied in insert.
   */
  private void createCasesForMessagingSessions() {
    DateTime lastRetentionDate = DateTime.newInstance(
      Date.today().addDays(-1),
      Time.newInstance(0, 0, 0, 0)
    );

    List<String> lstChannelEndUserKey = new List<String>();
    List<Case> casesToInsert = new List<Case>();
    Boolean oldCaseClosed = false;
    Set<Id> messagingEndUserIds = new Set<Id>();
    for (MessagingSession s : instanceRecords) {
      messagingEndUserIds.add(s.MessagingEndUserId);
      lstChannelEndUserKey.add(s.ChannelEndUserFormula);
    }
    List<MessagingSession> lstMessingSesions = new List<MessagingSession>(
      [
        SELECT Id, CaseId, Case.status, ChannelEndUserFormula, EndTime
        FROM MessagingSession
        WHERE
          ChannelEndUserFormula = :lstChannelEndUserKey[0]
          AND status != 'Active'
          AND status != 'Waiting'
          AND CaseId != ''
        ORDER BY EndTime DESC
        LIMIT 1
      ]
    );
    Map<Id, MessagingEndUser> meuMap = new Map<Id, MessagingEndUser>(
      [
        SELECT Id, AccountId, ContactId
        FROM MessagingEndUser
        WHERE Id IN :messagingEndUserIds
      ]
    );
    Case cse;
    if (!lstMessingSesions.isEmpty()) {
      cse = [
        SELECT
          FCS_Case_Reason__c,
          FCS_CaseType__c,
          RecordTypeId,
          Type,
          Subject,
          Description,
          AccountId,
          ContactId
        FROM Case
        WHERE Id = :lstMessingSesions[0].CaseId
        LIMIT 1
      ];
    }
    for (MessagingSession session : instanceRecords) {
      if (!lstMessingSesions.isEmpty()) {
        if (
          session.CaseId == null &&
          session.Status == 'Active' &&
          session.Origin == 'InboundInitiated'
        ) {
          if (lstMessingSesions[0].Case.Status != 'Closed') {
            session.CaseId = lstMessingSesions[0].CaseId;
            casesToInsert.add(
              new Case(
                Id = lstMessingSesions[0].CaseId,
                Status = 'New Response'
              )
            );
          } else if (
            lstMessingSesions[0].Case.Status == 'Closed' &&
            lstMessingSesions[0].EndTime > lastRetentionDate
          ) {
            session.CaseId = lstMessingSesions[0].CaseId;
            casesToInsert.add(
              new Case(
                Id = lstMessingSesions[0].CaseId,
                Status = 'New Response'
              )
            );
          } else {
            oldCaseClosed = true;
            Case cCloneCase = cse.clone(false, false, false, false);
            cCloneCase.RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
            cCloneCase.Origin = 'Facebook Messenger';
            casesToInsert.add(cCloneCase);
          }
        }
      } else {
        if (
          session.CaseId == null &&
          session.Status == 'Active' &&
          session.Origin == 'InboundInitiated'
        ) {
          oldCaseClosed = true;
          casesToInsert.add(
            new Case(
              Status = 'New',
              Origin = 'Facebook Messenger',
              RecordTypeId = C_RecordTypeHelper.CASE_CHAT,
              AccountId = meuMap.get(session.MessagingEndUserId).AccountId,
              ContactId = meuMap.get(session.MessagingEndUserId).ContactId
            )
          );
        }
      }
    }
    if (!casesToInsert.IsEmpty()) {
      upsert casesToInsert;
    }
    if (oldCaseClosed)
      for (Integer i = 0; i < instanceRecords.size(); i++) {
        if (
          instanceRecords[i].CaseId == null &&
          instanceRecords[i].Status == 'Active' &&
          instanceRecords[i].Origin == 'InboundInitiated'
        ) {
          instanceRecords[i].CaseId = casesToInsert[i].Id;
        }
      }
  }
}
