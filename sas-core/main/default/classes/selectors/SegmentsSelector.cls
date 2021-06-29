public inherited sharing class SegmentsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Segment__c.Id,
      Segment__c.Baggage_Quantity__c,
      Segment__c.Booking__c,
      Segment__c.Booking_Class__c,
      Segment__c.Check_In_Status__c,
      Segment__c.Fare_Basis__c,
      Segment__c.Flight__c,
      Segment__c.Identifier__c,
      Segment__c.Is_Boarded__c,
      Segment__c.Seat__c,
      Segment__c.Service_Class__c,
      Segment__c.Special_Service_Requests__c,
      Segment__c.Ticket_Number__c,
      Segment__c.Ticket_Type__c
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
