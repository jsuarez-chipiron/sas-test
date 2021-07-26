public inherited sharing class CasesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Case.Id,
      Case.AccountId,
      Case.CaseNumber,
      Case.CreatedDate,
      Case.FCS_CaseReason__c,
      Case.FCS_EBNumber__c,
      Case.Status
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
  

  public override String getOrderBy() {
    return 'CaseNumber';
  }
}