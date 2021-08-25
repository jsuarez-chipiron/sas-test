public inherited sharing class MessagingSessionsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      MessagingSession.Id,
      MessagingSession.caseId
    };
  }
  public Schema.SObjectType getSObjectType() {
    return MessagingSession.SObjectType;
  }
  public List<MessagingSession> selectById(Set<Id> ids) {
    return (List<MessagingSession>) selectSObjectsById(ids);
  }
}
