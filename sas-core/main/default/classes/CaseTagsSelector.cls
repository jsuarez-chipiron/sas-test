public inherited sharing class CaseTagsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      FCS_CaseTag__c.Id,
      FCS_CaseTag__c.Name,
      FCS_CaseTag__c.FCS_CaseId__c,
      FCS_CaseTag__c.FCS_CaseTag__c,
      FCS_CaseTag__c.FCS_Type__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return FCS_CaseTag__c.SObjectType;
  }

  public List<FCS_CaseTag__c> selectById(Set<Id> ids) {
    return (List<FCS_CaseTag__c>) selectSObjectsById(ids);
  }
  public List<FCS_CaseTag__c> selectByCaseId(Set<Id> caseIds) {
     fflib_QueryFactory caseTagsQF = newQueryFactory()
      .setCondition('FCS_CaseId__c in :caseIds');
      return (List<FCS_CaseTag__c>) Database.query(caseTagsQF.toSOQL());
  }
   public List<FCS_CaseTag__c> selectByChatId(Set<Id> chatIds) {
    ChatTranscriptsSelector chatTranscripts = (ChatTranscriptsSelector) SAS_Service_Application.Selector.newInstance(
      LiveChatTranscript.SObjectType
    );

    Set<Id> caseIds = new Set<Id>();
    for (LiveChatTranscript ct : chatTranscripts.selectById(chatIds)) {
      caseIds.add(ct.caseId);
    }
      return (List<FCS_CaseTag__c>) this.selectByCaseId(caseIds);
  }
}