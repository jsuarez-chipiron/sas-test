public without sharing class Airports extends fflib_SObjectDomain {
  public Airports(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Airport__c>) Records;
  }

  public List<Airport__c> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Airports(records);
    }
  }

  public static Airports newInstance(List<Airport__c> sObjectList) {
    return (Airports) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  /**
   * Parses airport data in TEDSAirport format into Airport__c objects and prepares them for DB insertion.
   *
   * @param airportData List of TEDSAirport objects containing Airports to create.
   * @param shouldUpsertToDB Boolean which asserts whether the records should be upserted or not
   *
   * @return The list of created Airport__c objects.
   */
  public static Airports createFromTEDSData(
    List<TEDSAirport> airportData,
    Boolean shouldUpsertToDB
  ) {
    Map<String, Airport__c> airportsProcessed = new Map<String, Airport__c>();

    for (TEDSAirport airport : airportData) {
      String airportId = airport.id.trim().toUpperCase();

      // TODO: Examine if we can manually set the id some way (Id = airportId)
      if (!airportsProcessed.containsKey(airportId)) {
        Airport__c newairport = new Airport__c(
          Name = airport.name,
          City__c = airport.city,
          Country_Code__c = airport.country.code,
          Country_Name__c = airport.country.name,
          Latitude__c = Decimal.valueOf(airport.coordinates.latitude)
            .setScale(12),
          Longitude__c = Decimal.valueOf(airport.coordinates.longitude)
            .setScale(12),
          Is_In_European_Union__c = CountryUtils.isInEU(airport.country.code),
          TEDS_Identifier__c = airportId
        );

        airportsProcessed.put(airportId, newairport);
      }
    }

    Airports newAirports = Airports.newInstance(airportsProcessed.values());
    List<String> TEDSIds = new List<String>(airportsProcessed.keySet());

    if (shouldUpsertToDB) {
      newAirports.upsertToDB();
    }

    return newAirports;
  }

  public Airports upsertToDB() {
    try {
      upsert instanceRecords TEDS_Identifier__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert instanceRecords TEDS_Identifier__c;
      }
    }

    return this;
  }

  public class AirportException extends Exception {
  }
}
