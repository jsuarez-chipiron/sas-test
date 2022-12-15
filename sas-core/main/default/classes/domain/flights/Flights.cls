public without sharing class Flights extends ApplicationDomain {
  public Flights(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Flight__c>) Records;
  }

  public List<Flight__c> instanceRecords;
  @TestVisible
  private FlightIrregularities flightIrregularities;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Flights(records);
    }
  }

  public static Flights newInstance(List<Flight__c> sObjectList) {
    return (Flights) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  /**
   * Parses flight data in TEDSFlight format into Flight__c objects and prepares them for DB insertion.
   *
   * @param flightData List of TEDSFlight objects containing flights to create.
   * @param shouldUpsertToDB Boolean which asserts whether the records should be upserted or not
   *
   * @return The list of created Flight__c objects.
   */
  public static Flights createFromTEDSData(
    List<TEDSFlight> flightData,
    Boolean shouldUpsertToDB
  ) {
    Map<String, Flight__c> flightsProcessed = new Map<String, Flight__c>();
    Map<String, TEDSFlight.Arrival> TEDSIdToTEDSArrival = new Map<String, TEDSFlight.Arrival>{};
    Map<String, TEDSFlight.Departure> TEDSIdToTEDSDeparture = new Map<String, TEDSFlight.Departure>{};

    // Loop through each booking and create all sub objects.
    for (TEDSFlight flight : flightData) {
      // Loop through all segments in the trip and create segment and flight objects as necessary

      // Create flights
      String flightId = flight.id.trim().toUpperCase();

      // Save irregularity data for batch insert
      TEDSIdToTEDSArrival.put(flightId, flight.arrival);
      TEDSIdToTEDSDeparture.put(flightId, flight.departure);

      if (!flightsProcessed.containsKey(flightId)) {
        Datetime scheduledArrivalDate = Datetime.valueOf(
          flight.arrival.scheduledTime?.utc?.replace('T', ' ').replace('Z', '')
        );
        Datetime scheduledDepartureDate = Datetime.valueOf(
          flight.departure.scheduledTime
            ?.utc
            ?.replace('T', ' ')
            .replace('Z', '')
        );
        Datetime actualArrivalDate;
        Datetime actualDepartureDate;
        if (flight.arrival.actualTime != null) {
          actualArrivalDate = Datetime.valueOf(
            flight.arrival.actualTime?.utc?.replace('T', ' ').replace('Z', '')
          );
        }
        if (flight.departure.actualTime != null) {
          actualDepartureDate = Datetime.valueOf(
            flight.departure.actualTime?.utc?.replace('T', ' ').replace('Z', '')
          );
        }
        Datetime estimatedArrivalDate;
        Datetime estimatedDepartureDate;
        if (flight.arrival.estimatedTime != null) {
          estimatedArrivalDate = Datetime.valueOf(
            flight.arrival.estimatedTime
              ?.utc
              ?.replace('T', ' ')
              .replace('Z', '')
          );
        }
        if (flight.departure.estimatedTime != null) {
          estimatedDepartureDate = Datetime.valueOf(
            flight.departure.estimatedTime
              ?.utc
              ?.replace('T', ' ')
              .replace('Z', '')
          );
        }

        String scheduledArrivalDateLocal = flight.arrival.scheduledTime
          ?.local
          ?.replace('Z', '');
        String scheduledDepartureDateLocal = flight.departure.scheduledTime
          ?.local
          ?.replace('Z', '');

        String actualArrivalDateLocal;
        String actualDepartureDateLocal;
        if (flight.arrival.actualTime != null) {
          actualArrivalDateLocal = flight.arrival.actualTime
            ?.local
            ?.replace('Z', '');
        }
        if (flight.departure.actualTime != null) {
          actualDepartureDateLocal = flight.departure.actualTime
            ?.local
            ?.replace('Z', '');
        }
        String estimatedArrivalDateLocal;
        String estimatedDepartureDateLocal;
        if (flight.arrival.estimatedTime != null) {
          estimatedArrivalDateLocal = flight.arrival.estimatedTime
            ?.local
            ?.replace('Z', '');
        }
        if (flight.departure.estimatedTime != null) {
          estimatedDepartureDateLocal = flight.departure.estimatedTime
            ?.local
            ?.replace('Z', '');
        }

        Flight__c newFlight = new Flight__c(
          Name = flightId,
          Actual_Arrival_Time__c = actualArrivalDate,
          Actual_Arrival_Time_Local__c = actualArrivalDateLocal,
          Actual_Departure_Time__c = actualDepartureDate,
          Actual_Departure_Time_Local__c = actualDepartureDateLocal,
          Arrival_Airport__c = flight.arrival.station,
          Arrival_Delayed_Minutes__c = flight.arrival.delayedMinutes,
          Arrival_Gate__c = flight.arrival.gate,
          Arrival_Status__c = flight.arrival.status,
          Arrival_Terminal__c = flight.arrival.terminal?.id,
          Departure_Airport__c = flight.departure.station,
          Departure_Delayed_Minutes__c = flight.departure.delayedMinutes,
          Departure_Gate__c = flight.departure.gate,
          Departure_Status__c = flight.departure.status,
          Departure_Terminal__c = flight.departure.terminal?.id,
          Estimated_Arrival_Time__c = estimatedArrivalDate,
          Estimated_Arrival_Time_Local__c = estimatedArrivalDateLocal,
          Estimated_Departure_Time__c = estimatedDepartureDate,
          Estimated_Departure_Time_Local__c = estimatedDepartureDateLocal,
          Operating_Carrier__c = flight.carrier, // The carrier field from TEDS should always contain the operating carrier
          Scheduled_Arrival_Time__c = scheduledArrivalDate,
          Scheduled_Arrival_Time_Local__c = scheduledArrivalDateLocal,
          Scheduled_Departure_Time__c = scheduledDepartureDate,
          Scheduled_Departure_Time_Local__c = scheduledDepartureDateLocal,
          TEDS_Identifier__c = flightId
        );

        flightsProcessed.put(flightId, newFlight);
      }
    }

    Flights newFlights = Flights.newInstance(flightsProcessed.values());
    List<String> TEDSIds = new List<String>(flightsProcessed.keySet());

    newFlights.flightIrregularities = FlightIrregularities.createFromTEDSData(
      TEDSIds,
      TEDSIdToTEDSArrival,
      TEDSIdToTEDSDeparture
    );

    if (shouldUpsertToDB) {
      newFlights.upsertToDB();
    }

    return newFlights;
  }
  //Flights and Irregularities are stored in the same table in EDW
  public static Flights createFromEDWData(
    List<FetchEDWDataResponse.Irregularity> flightSourceData
  ) {
    Map<String, Flight__c> flightIdToRecord = new Map<String, Flight__c>();
    List<FetchEDWDataResponse.Irregularity> irregularitiesToCreate = new List<FetchEDWDataResponse.Irregularity>();
    for (FetchEDWDataResponse.Irregularity irr : flightSourceData) {
      //The input data contains different data based on if flight belongs to SK or other carrier
      String flightStatus = 'unknown';
      String arrivalStatus = 'unknown';
      String departureStatus = 'unknown';
      switch on irr.status {
        when 'DEPARTURE DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'ontime';
          departureStatus = 'delayed';
        }
        when 'ARRIVAL DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'delayed';
          departureStatus = 'ontime';
        }
        when 'DEPARTUE AND ARRIVAL DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'delayed';
          departureStatus = 'delayed';
        }
        when 'CANCELLED' {
          flightStatus = 'cancelled';
          arrivalStatus = 'cancelled';
          departureStatus = 'cancelled';
        }
        when 'ON TIME' {
          flightStatus = 'ontime';
          arrivalStatus = 'ontime';
          departureStatus = 'ontime';
        }
        when else {
          flightStatus = 'unknown';
          arrivalStatus = 'unknown';
          departureStatus = 'unknown';
        }
      }
      Boolean cancelledOrDelayed =
        flightStatus == 'delayed' ||
        irr.fltStatus == 'X';
      if (cancelledOrDelayed) {
        irregularitiesToCreate.add(irr);
      }
      String irrFlightId = String.format(
        '{0}-{1}-{2}-{3}',
        new List<Object>{
          irr.fltId.deleteWhitespace(),
          Datetime.newInstance(irr.depDte).format('yyyyMMdd'),
          irr.stnFrCd,
          irr.stnToCd
        }
      );
      if (flightIdToRecord.get(irrFlightId) != null) {
        continue;
      }
      Flight f = new Flight(new Flight__c(Name = irrFlightId));
      f.tedsIdentifier = irrFlightId;
      f.aircraftRegistration = irr.aircraftRegistration;
      f.arrivalAirport = irr.stnToCd;
      f.arrivalDelayedMinutes = irr.arrivalDelayMins;
      f.arrivalStatus = Flight.getStatusFromPicklistValue(arrivalStatus);
      f.departureAirport = irr.stnFrCd;
      f.departureDelayedMinutes = irr.depDelayMins;
      f.departureStatus = Flight.getStatusFromPicklistValue(departureStatus);
      f.actualArrivalTime = irr.ataTms == null
        ? null
        : Datetime.newInstance(irr.ataTms);
      f.actualDepartureTime = irr.atdTms == null
        ? null
        : Datetime.newInstance(irr.atdTms);
      f.estimatedArrivalTime = irr.etaTms == null
        ? null
        : Datetime.newInstance(irr.etaTms);
      f.estimatedDepartureTime = irr.etdTms == null
        ? null
        : Datetime.newInstance(irr.etdTms);
      f.scheduledArrivalTime = irr.staTms == null
        ? null
        : Datetime.newInstance(irr.staTms);
      f.scheduledDepartureTime = irr.stdTms == null
        ? null
        : Datetime.newInstance(irr.stdTms);
      f.updateSObjectFields();
      flightIdToRecord.put(irrFlightId, f.underlyingSObject);
    }

    Flights newFlights = Flights.newInstance(flightIdToRecord.values());
    newFlights.flightIrregularities = FlightIrregularities.createFromEDWData(
      irregularitiesToCreate
    );
    return newFlights;
  }

  public Flights upsertToDB() {
    Set<String> flightIds = new Set<String>();

    for (Flight__c f : instanceRecords) {
      flightIds.add(f.TEDS_Identifier__c);
    }

    List<FlightIrregularities__c> irregularitiesToDelete = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(flightIds);

    try {
      delete irregularitiesToDelete; // Delete and re-insert all irregularities
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.ENTITY_IS_DELETED) {
        // A parallel thread may have deleted the entities. Let's just ignore.
      } else {
        throw e;
      }
    }

    // The upsert operation seems to fail due to a race condition between two threads
    // trying to upsert the records simultaneously. One thread succeeds and the other
    // fails with a duplicate value exception.
    try {
      upsert instanceRecords TEDS_Identifier__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert instanceRecords TEDS_Identifier__c;
      }
    }

    if (flightIrregularities != null) {
      if (flightIrregularities.instanceRecords.size() > 0) {
        insert flightIrregularities.addFlightReferences(instanceRecords)
          .instanceRecords;
      }
    }

    return this;
  }
}
