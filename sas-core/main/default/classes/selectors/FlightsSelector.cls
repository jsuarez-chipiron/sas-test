public inherited sharing class FlightsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Flight__c.Id,
      Flight__c.Name,
      Flight__c.Arrival_Airport__c,
      Flight__c.Departure_Airport__c,
      Flight__c.Scheduled_Arrival_Time__c,
      Flight__c.Scheduled_Departure_Time__c,
      Flight__c.TEDS_Identifier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Flight__c.SObjectType;
  }

  public List<Flight__c> selectById(Set<Id> ids) {
    return (List<Flight__c>) selectSObjectsById(ids);
  }

  public List<Flight__c> selectByFlightId(Set<String> flightIds) {
    return (List<Flight__c>) Database.query(
      newQueryFactory().setCondition('Name = :flightIds').toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
