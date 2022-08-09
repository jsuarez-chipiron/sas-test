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
          Is_EU261_Applicable__c = CountryUtils.isInEUOrNorwaySwitzerlandIceland(
            airport.country.code
          ),
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

  /**
   * Calculates the haversine distance in meters between two airports.
   *
   * @param airport1 a String with the IATA code of the airport e.g. ARN.
   * @param airport2 a String with the IATA code of the airport e.g. ARN.
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    String airport1,
    String airport2
  ) {
    List<Airport__c> airports = AirportsSelector.newInstance()
      .selectByIATACode(new Set<String>{ airport1, airport2 });

    if (airports.size() != 2) {
      throw new AirportsNotDefinedException('Unable to find airports');
    }

    return distanceBetweenAirportsInMeters(airports[0], airports[1]);
  }

  /**
   * Calculates the haversine distance in meters between two airports.
   *
   * @param airport1 an Airport__c.
   * @param airport2 an Airport__c.
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    Airport__c airport1,
    Airport__c airport2
  ) {
    if (airport1 == null || airport2 == null) {
      throw new AirportsNotDefinedException(
        'At least one of the airports equal to null.'
      );
    }

    Double long1 = Double.valueOf(airport1.Longitude__c);
    Double lat1 = Double.valueOf(airport1.Latitude__c);
    Double long2 = Double.valueOf(airport2.Longitude__c);
    Double lat2 = Double.valueOf(airport2.Latitude__c);

    Location loc1 = Location.newInstance(
      airport1.Latitude__c,
      airport1.Longitude__c
    );
    Location loc2 = Location.newInstance(
      airport2.Latitude__c,
      airport2.Longitude__c
    );
    Double dist = Location.getDistance(loc1, loc2, 'km'); // Can only be km or mi

    if (dist == null) {
      throw new AirportException('Airport longitude and/or latitude not set');
    }

    return Integer.valueOf(
      Decimal.valueOf(dist * 1000).round(System.RoundingMode.HALF_UP)
    );
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

  // For manual update
  public void setEU261Applicable() {
    for (Airport__c a : instanceRecords) {
      a.Is_EU261_Applicable__c = CountryUtils.isInEUOrNorwaySwitzerlandIceland(
        a.Country_Code__c
      );
    }
    update instanceRecords;
  }

  public class AirportsNotDefinedException extends Exception {
  }

  public class AirportException extends Exception {
  }
}
