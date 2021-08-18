public inherited sharing class CasesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Case.Id,
      Case.AccountId,
      Case.CaseNumber,
      Case.CreatedDate,
      Case.FCS_CaseReason__c,
      Case.FCS_EBNumber__c,
      Case.FCS_Case_Reason__c,
      case.RecordTypeId,
      Case.Status,
      case.Department__c,
      Case.FCS_CaseType__c,
      Case.FCS_CaseResolution__c,
      Case.FCS_CaseResolutionDetails__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Case.SObjectType;
  }

  public List<Case> selectById(Set<Id> ids) {
    return (List<Case>) selectSObjectsById(ids);
  }

  public List<Case> selectByAccountId(Set<Id> accountIds) {
    fflib_QueryFactory casesQF = newQueryFactory()
      .setCondition('AccountId in :accountIds');
    return (List<Case>) Database.query(casesQF.toSOQL());
  }
  public List<Case> selectByChatId(Set<Id> chatIds) {
    ChatTranscriptsSelector chatTranscripts = (ChatTranscriptsSelector) SAS_Service_Application.Selector.newInstance(
      LiveChatTranscript.SObjectType
    );

    Set<Id> caseIds = new Set<Id>();
    for (LiveChatTranscript ct : chatTranscripts.selectById(chatIds)) {
      caseIds.add(ct.caseId);
    }
    return (List<Case>) this.selectSObjectsById(caseIds);
  }
  public List<Case> selectBySocialPostId(Set<Id> socialPostIds) {
    SocialPostsSelector socialPosts = (SocialPostsSelector) SAS_Service_Application.Selector.newInstance(
      SocialPost.SObjectType
    );
    Set<Id> caseIds = new Set<Id>();
    for (SocialPost sp : socialPosts.selectById(socialPostIds)) {
      caseIds.add(sp.parentId);
    }
    return (List<Case>) this.selectSObjectsById(caseIds);
  }
  public List<Case> selectByMessagingId(Set<Id> messagingsessionsId) {
    MessagingSessionsSelector messagingSessions = (MessagingSessionsSelector) SAS_Service_Application.Selector.newInstance(
      MessagingSession.SObjectType
    );
    Set<Id> caseIds = new Set<Id>();
    for (
      MessagingSession ms : messagingSessions.selectById(messagingsessionsId)
    ) {
      caseIds.add(ms.caseId);
    }
    return (List<Case>) this.selectSObjectsById(caseIds);
  }
  public override String getOrderBy() {
    return 'CaseNumber';
  }
}
