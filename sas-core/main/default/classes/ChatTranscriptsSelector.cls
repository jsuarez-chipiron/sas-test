public inherited sharing class ChatTranscriptsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      LiveChatTranscript.Id,
      LiveChatTranscript.caseId
    };
  }
  public Schema.SObjectType getSObjectType() {
    return LiveChatTranscript.SObjectType;
  }
  public List<LiveChatTranscript> selectById(Set<Id> ids) {
    return (List<LiveChatTranscript>) selectSObjectsById(ids);
  }
}
