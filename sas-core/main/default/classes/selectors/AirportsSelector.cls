public inherited sharing class AirportsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Airport__c.Id,
      Airport__c.Name,
      Airport__c.City__c,
      Airport__c.Country_Code__c,
      Airport__c.Country_Name__c,
      Airport__c.Latitude__c,
      Airport__c.Longitude__c,
      Airport__c.Is_In_European_Union__c,
      Airport__c.TEDS_Identifier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Airport__c.SObjectType;
  }

  public static AirportsSelector newInstance() {
    return (AirportsSelector) SAS_Service_Application.Selector.newInstance(
      Airport__c.SObjectType
    );
  }

  public List<Airport__c> selectById(Set<Id> ids) {
    return (List<Airport__c>) selectSObjectsById(ids);
  }

  public List<Airport__c> selectByTEDSId(Set<String> airportIds) {
    return (List<Airport__c>) Database.query(
      newQueryFactory()
        .setCondition('TEDS_Identifier__c IN :airportIds')
        .toSOQL()
    );
  }

  // Todo:
  // Examine: Should we really fetch these dynamically or could we just have a cronjob running once every week and store all airports in the db (about 3000)?
  public List<Airport__c> selectAndOrFetchByTEDSId(Set<String> airportIds) {
    List<Airport__c> airportsInDb = (List<Airport__c>) Database.query(
      newQueryFactory()
        .setCondition('TEDS_Identifier__c IN :airportIds')
        .toSOQL()
    );

    // If records not in database, fetch them from TEDS
    if (airportsInDb.size() < airportIds.size()) {
      for (Airport__c airportInDb : airportsInDb) {
        airportIds.remove(airportInDb.Id);
      }

      if (Test.isRunningTest()) {
        // Deal with DML + callout issues
        airportsInDb.addAll(
          AirportService.newInstance()
            .fetchAirportsByReference(airportIds, false)
            .instanceRecords
        );
      } else {
        airportsInDb.addAll(
          AirportService.newInstance()
            .fetchAirportsByReference(airportIds, true)
            .instanceRecords
        );
      }
    }

    return airportsInDb;
  }

  public override String getOrderBy() {
    return 'TEDS_Identifier__c';
  }
}
