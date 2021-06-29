public inherited sharing class CaseToBookingsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      CaseToBooking__c.Id,
      CaseToBooking__c.Booking__c,
      CaseToBooking__c.Case__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return CaseToBooking__c.SObjectType;
  }

  public List<CaseToBooking__c> selectById(Set<Id> ids) {
    return (List<CaseToBooking__c>) selectSObjectsById(ids);
  }

  public List<CaseToBooking__c> selectByCaseId(Set<Id> caseIds) {
    return (List<CaseToBooking__c>) Database.query(
      newQueryFactory().setCondition('Case__c = :caseIds').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
