public without sharing class Flights extends fflib_SObjectDomain {
  public Flights(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Flight__c>) Records;
  }

  public List<Flight__c> instanceRecords;
  private FlightIrregularities flightIrregularities;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Flights(records);
    }
  }

  public static Flights newInstance(List<Flight__c> sObjectList) {
    return (Flights) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public static final String SAS_AIRLINE_IATA_DESIGNATOR = 'SK';

  public static final Set<String> STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS = new Set<String>{
    'A3',
    'AC',
    'AI',
    'AV',
    'BR',
    'CA',
    'CM',
    'ET',
    'LH',
    'LO',
    'LX',
    'MS',
    'NH',
    'NZ',
    'OS',
    'OU',
    'OZ',
    'SA',
    'SK',
    'SN',
    'SQ',
    'TG',
    'TK',
    'TP',
    'UA',
    'ZH'
  };

  /**
   * Whether the flights are operated by carriers which are not a part of Star
   * Alliance.
   *
   * @return A map from flight id to whether that flight is operated by carrier
   * which belongs to Star Alliance.
   */
  public Map<Id, Boolean> operatedByStarAlliance() {
    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Flight__c flight : instanceRecords) {
      toReturn.put(
        flight.Id,
        STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS.contains(
          flight.Operating_Carrier__c
        )
      );
    }
    return toReturn;
  }

  public Map<Id, Boolean> operatedBySAS() {
    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Flight__c flight : instanceRecords) {
      toReturn.put(
        flight.Id,
        flight.Operating_Carrier__c == SAS_AIRLINE_IATA_DESIGNATOR
      );
    }
    return toReturn;
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

  /* Determine whether the flights are delayed/cancelled or not
   *
   * @return A map from flight id to whether that flight is delayed/cancelled or not
   */
  public Map<Id, Boolean> isDelayedOrCancelled() {
    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Flight__c flight : instanceRecords) {
      Boolean isIrregularity =
        flight.Arrival_Status__c == 'delayed' ||
        (flight.Arrival_Status__c == 'cancelled' &&
        flight.Departure_Status__c == 'cancelled');
      toReturn.put(flight.Id, isIrregularity);
    }
    return toReturn;
  }

  /*
   * Returns variations of the flight id written in plain text
   * Format: BT0151-20220713-RIX-OSL
   *
   * @return A list with ids with the following formats: BT0151-20220713, BT0151-2022-07-13
   */
  public static List<String> TEDSIdToSimpleFlightIds(String TEDSId) {
    String flightNumber = TEDSId.substringBefore('-'); // Should be normalized
    String flightDateConcat = TEDSId.substringAfter('-').substringBefore('-');
    String flightDateSeparated =
      flightDateConcat.substring(0, 4) +
      '-' +
      flightDateConcat.substring(4, 6) +
      '-' +
      flightDateConcat.substring(6, 8);

    String format1 = flightNumber + '-' + flightDateConcat;
    String format2 = flightNumber + '-' + flightDateSeparated;

    return new List<String>{ format1, format2 };
  }

  /**
   * Constructs a flightNumber + date combination like the one used in TEDS
   *
   * @param flightNumber E.g. SK1234
   * @param flightDate
   * @return a string like: SK1234-20220101
   */
  public static String constructTEDSFlightNumberDate(
    String flightNumber,
    Date flightDate
  ) {
    return normalizeFlightNumber(flightNumber) +
      '-' +
      String.valueOf(flightDate).remove('-');
  }

  /**
   * Method to normalize a valid IATA flight number
   * to the format used by TEDS.
   * TEDS format is valid IATA format with trailing numbers leftpadded with 0
   * Returns a normalized flight number.
   *
   *  @param enteredFlightNumber The flight number as entered by manual input (forms etc.)
   */
  public static String normalizeFlightNumber(String enteredFlightNumber) {
    String toNormalize = enteredFlightNumber.toUpperCase();
    String toReturn = '';
    Pattern validTEDSFormat = Pattern.compile('^([A-Z]\\w|\\w[A-Z])(\\d{4})$');
    Pattern validFlightNumberFormat = Pattern.compile(
      '^([A-Z]\\w|\\w[A-Z])(\\d{1,4})$'
    );
    Boolean validIATAFlightNumber = isValidIATAFlightNumber(toNormalize);
    if (validIATAFlightNumber) {
      String airlineCode = toNormalize.substring(0, 2);
      String flightNumber = toNormalize.substring(2, toNormalize.length());
      toReturn = airlineCode + flightNumber.leftPad(4, '0');
    }
    if (validTEDSFormat.matcher(toReturn).matches()) {
      return toReturn;
    } else {
      throw new FlightException('Unable to normalize Flight Number');
    }
  }

  /* Method to validate if an entered flight number is a valid IATA flight number
   * Valid formats are:
   * [LETTER][NUMBER] followed by 1-4 numbers
   * [NUMBER][LETTER] followed by 1-4 numbers
   * [LETTER][LETTER] followed by 1-4 numbers
   */
  public static Boolean isValidIATAFlightNumber(String toCheck) {
    Pattern validFlightNumberFormat = Pattern.compile(
      '^([A-Z]\\w|\\w[A-Z])(\\d{1,4})$'
    );
    Matcher matcher = validFlightNumberFormat.matcher(toCheck);
    return matcher.matches();
  }

  public Map<Id, Integer> getFlightDistancesInMeters() {
    Map<Id, Integer> toReturn = new Map<Id, Integer>();
    for (Flight__c f : instanceRecords) {
      toReturn.put(
        f.Id,
        Airports.distanceBetweenAirportsInMeters(
          f.Departure_Airport__c,
          f.Arrival_Airport__c
        )
      );
    }
    return toReturn;
  }

  public class FlightException extends Exception {
  }
}
