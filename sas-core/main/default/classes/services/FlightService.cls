/**
 * Service class for managing flights in Salesforce.
 */
public without sharing class FlightService {
  /**
   * Attempts to fetch the given flights from TEDS, and create necessary DB objects.
   * Does nothing if one isn't found.
   *
   * @param flightReferences List of flights to find using the full TEDS flight Id. Maximum of 10 per call.
   *
   * @throws IntegrationError If there is a problem with the integration.
   */
  @future(callout=true)
  public static void fetchFlightsByFlightReference(String flightReferences) {
    TEDSIntegrationService TEDSService = (TEDSIntegrationService) SAS_Service_Application.Service.newInstance(
      TEDSIntegrationService.class
    );

    List<String> individualFlightReferences = flightReferences.split(',');

    List<List<String>> query = new List<List<String>>();

    for (String ref : individualFlightReferences) {
      query.add(new List<String>{ 'ids', ref });
    }

    List<TEDSFlight> flightData = TEDSService.fetchFlightsByQuery(query);

    if (flightData == null) {
      return;
    }

    List<Flight__c> newFlights = constructFlightsForDB(flightData);

    // The upsert operation seems to fail due to a race condition between two threads
    // trying to upsert the records simultaneously. One thread succeeds and the other
    // fails with a duplicate value exception.
    try {
      upsert newFlights TEDS_Identifier__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert newFlights TEDS_Identifier__c;
      }
    }
  }

  /**
   * Parses flight data in TEDSFlight format into Flight__c objects and prepares them for DB insertion.
   *
   * @param flightData List of TEDSFlight objects containing flights to create.
   * @param uow Unit of work transaction in which the booking should be committed. Must be committed by caller.
   *
   * @return The list of created Flight__c objects.
   */
  private static List<Flight__c> constructFlightsForDB(
    List<TEDSFlight> flightData
  ) {
    Map<String, Flight__c> flightsProcessed = new Map<String, Flight__c>();

    // Loop through each booking and create all sub objects.
    for (TEDSFlight flight : flightData) {
      // Loop through all segments in the trip and create segment and flight objects as necessary

      // Create flights
      String flightId = flight.id.trim().toUpperCase();

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
    return flightsProcessed.values();
  }
}
