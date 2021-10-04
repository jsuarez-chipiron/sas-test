/**
  Purpose : Used to close the case when customer not contacted in last 24 hours
            Also close the cases which are created due to chat error
         @author Thippeswamy A
*/

public with sharing class FCS_CloseFBMessgerCaseAfter24hr_Batch extends SBS_ScheduledBatch {
  /**
    dateTime is used to find the messagingsession ended in last 24 hours. 
  */
  DateTime lastRetentionDate;
  public FCS_CloseFBMessgerCaseAfter24hr_Batch() {

  }
  public Database.QueryLocator start(Database.BatchableContext bc) {
    lastRetentionDate = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(0, 0, 0, 0));
    String caseOrigin = 'Facebook Messenger';
    List < String > lstStatus = new List < String > {
      'New',
      'In Progress',
      'New Response'
    };
    String closeStatus = 'Closed';

    return Database.getQueryLocator('Select Id, status from Case where Origin =: caseOrigin AND Status IN:lstStatus AND Status !=: closeStatus');
  }
  public override void executeScope(Database.BatchableContext bc, SObject[] sObjScope) {
    List < Case > lstCases = (List < Case > ) sObjScope;
    Set < Id > setCaseIds = new Set < Id > ();
    Set < Id > setUpdateCaseIds = new Set < Id > ();
    List < Case > lstUpdatecases = new List < Case > ();
    Map < Id, Case > mapRetaincases = new Map < Id, Case > ();
    for (Case cse: lstCases) {
      setCaseIds.add(cse.Id);
    }
    List < MessagingSession > lstMessagingsessions = [Select Id, Status, CaseId, EndTime, AcceptTime, AgentMessageCount from MessagingSession where CaseId =: setCaseIds order by CreatedDate];
    if (!lstMessagingsessions.isEmpty()) {
      for (MessagingSession messgSession: lstMessagingsessions) {
        if (messgSession.Status == 'Active' && messgSession.AcceptTime <= lastRetentionDate && messgSession.AgentMessageCount == 0) {
          setUpdateCaseIds.add(messgSession.caseId);
        } else if ((messgSession.Status == 'Active' && messgSession.AcceptTime > lastRetentionDate)) {
          mapRetaincases.put(messgSession.caseId, new Case(Id = messgSession.caseId));
        } else If(messgSession.Status == 'Ended' && messgSession.EndTime > lastRetentionDate) {
          mapRetaincases.put(messgSession.caseId, new Case(Id = messgSession.caseId));
        }
        else if (messgSession.Status == 'Ended' && messgSession.EndTime <= lastRetentionDate && !mapRetaincases.containsKey(messgSession.CaseId)) {
          setUpdateCaseIds.add(messgSession.caseId);
        }

      }
    }
    if (setUpdateCaseIds.size() > 0) {
      List < Case > lstCses = [SELECT
                              Id,
                              Type,
                              FCS_CaseReason__c
                              FROM
                              Case
                              WHERE
                              Id IN: setUpdateCaseIds
                              ];
      List < Case > tagCases = new List < Case > ();
      for (Case cse: lstCses) {
        if (cse.FCS_CaseReason__c == null || cse.FCS_CaseReason__c == '') {
          cse.FCS_CaseType__c = 'Error';
          cse.FCS_Case_Reason__c = 'Disconnected customer';
          tagCases.add(cse);
        }
      }
      if (!tagCases.isEmpty()) {
        Update tagCases;
      }
      for (Id cseId: setUpdateCaseIds) {
        lstUpdatecases.add(new
          case (Id = cseId, Status = 'Closed'));
      }
    }

    if (!lstUpdatecases.isEmpty()) {
      Update lstUpdatecases;
    }


  }
  public override void finishOverridable(Database.BatchableContext bc) {}

}