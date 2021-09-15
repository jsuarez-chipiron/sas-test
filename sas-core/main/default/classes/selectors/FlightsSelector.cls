public inherited sharing class FlightsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Flight__c.Id,
      Flight__c.Name,
      Flight__c.Actual_Arrival_Time__c,
      Flight__c.Actual_Arrival_Time_Local__c,
      Flight__c.Actual_Departure_Time__c,
      Flight__c.Actual_Departure_Time_Local__c,
      Flight__c.Arrival_Airport__c,
      Flight__c.Arrival_Delayed_Minutes__c,
      Flight__c.Arrival_Gate__c,
      Flight__c.Arrival_Status__c,
      Flight__c.Arrival_Terminal__c,
      Flight__c.Departure_Airport__c,
      Flight__c.Departure_Delayed_Minutes__c,
      Flight__c.Departure_Gate__c,
      Flight__c.Departure_Status__c,
      Flight__c.Departure_Terminal__c,
      Flight__c.Estimated_Arrival_Time__c,
      Flight__c.Estimated_Arrival_Time_Local__c,
      Flight__c.Estimated_Departure_Time__c,
      Flight__c.Estimated_Departure_Time_Local__c,
      Flight__c.Scheduled_Arrival_Time__c,
      Flight__c.Scheduled_Arrival_Time_Local__c,
      Flight__c.Scheduled_Departure_Time__c,
      Flight__c.Scheduled_Departure_Time_Local__c,
      Flight__c.TEDS_Identifier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Flight__c.SObjectType;
  }

  public List<Flight__c> selectById(Set<Id> ids) {
    return (List<Flight__c>) selectSObjectsById(ids);
  }

  public List<Flight__c> selectByTEDSId(Set<String> flightIds) {
    return (List<Flight__c>) Database.query(
      newQueryFactory().setCondition('TEDS_Identifier__c = :flightIds').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'TEDS_Identifier__c';
  }
}
