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

  public override String getOrderBy() {
    return 'CaseNumber';
  }
}
