public inherited sharing class SegmentsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Segment__c.Id,
      Segment__c.Booking__c,
      Segment__c.Flight__c,
      Segment__c.Identifier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Segment__c.SObjectType;
  }

  public List<Segment__c> selectById(Set<Id> ids) {
    return (List<Segment__c>) selectSObjectsById(ids);
  }

  public override String getOrderBy() {
    return 'Booking__c, Identifier__c';
  }
}
