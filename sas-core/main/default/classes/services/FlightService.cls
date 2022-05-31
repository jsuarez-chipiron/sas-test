/**
 * Service class for managing flights in Salesforce.
 */
public without sharing class FlightService {
  public static FlightService newInstance() {
    return (FlightService) SAS_Service_Application.Service.newInstance(
      FlightService.class
    );
  }

  /**
   * Attempts to fetch the given flights from TEDS, and create necessary DB objects.
   * Does nothing if one isn't found.
   *
   * @param flightReferences Set of flights to find using the full TEDS flight Id. Maximum of 10 per call.
   *
   * @throws IntegrationError If there is a problem with the integration.
   */
  public Flights fetchFlightsByReference(
    Set<String> flightReferences,
    Boolean shouldUpsertToDB
  ) {
    TEDSIntegrationService.FlightsQuery query = new TEDSIntegrationService.FlightsQuery();
    query.ids = flightReferences;

    List<TEDSFlight> flightData = TEDSIntegrationService.newInstance()
      .fetchFlightsByQuery(query);

    if (flightData.size() == 0) {
      // Not found in TEDS. Booking reference doesn't exist in recent flight data (6 months or so).
      // TODO: Check EDW when an integration exists.
      return null;
    }

    Flights newFlights = Flights.createFromTEDSData(flightData);

    if (shouldUpsertToDB) {
      newFlights.upsertToDB();
    }

    return newFlights;
  }
}
