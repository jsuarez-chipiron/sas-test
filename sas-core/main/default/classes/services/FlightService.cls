public without sharing class FlightService {
  public static FlightService newInstance() {
    return (FlightService) SAS_Service_Application.Service.newInstance(
      FlightService.class
    );
  }

  public class IllegalArgumentsException extends Exception {
  }
  public class InvalidDelayException extends Exception {
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
    if (flightReferences == null || flightReferences.size() == 0) {
      throw new IllegalArgumentsException('flightReferences cannot be empty.');
    }

    TEDSIntegrationService.FlightsQuery query = new TEDSIntegrationService.FlightsQuery();
    query.ids = flightReferences;

    List<TEDSFlight> flightData = TEDSIntegrationService.newInstance()
      .fetchFlightsByQuery(query);

    if (flightData.size() == 0) {
      // Not found in TEDS. Booking reference doesn't exist in recent flight data (6 months or so).
      // TODO: Check EDW when an integration exists.
      // TODO: Would it make more sense to return an instance of Flights, but
      // with no instance records?
      return null;
    }

    Flights newFlights = Flights.createFromTEDSData(
      flightData,
      shouldUpsertToDB
    );

    return newFlights;
  }

  /**
   * Calculates the delays for different flights individually.
   *
   * @param flights a Flights object with the flights for which to calculate delays.
   * @param flightIdToIrregularities a Map from Flight Id to all flight irregularities.
   *
   * We currently ignore special cases such as the "deicing 8+ minute"-rule.
   * TODO: Refactor, use this in gatherinformation, batch call (somewhat janky)
   *
   * @return a map from flight Id to the delay in minutes SAS is responsible for.
   *
   * @throws InvalidDelayException If the actual delay cannot be accounted for with irregularities in the db.
   */
  public Map<Id, Integer> getTotalDelayInMinutesWithinSASControl( // TODO: Is this necessary?
    List<Flight> flights,
    Map<Id, List<FlightIrregularity>> flightIdToIrregularities
  ) {
    Map<Id, Integer> flightIdToDelay = new Map<Id, Integer>{};

    for (Flight f : flights) {
      if (f.arrivalDelayedMinutes == null) {
        flightIdToDelay.put(f.id, 0);
        continue;
      }
      List<FlightIrregularity> flightIrregularities = new List<FlightIrregularity>(
        flightIdToIrregularities.get(f.id)
      );
      List<Decimal> delayDivided = FlightIrregularity.getTotalDelayInMinutesDivided(
        flightIrregularities
      );

      Integer departureDelay = Integer.valueOf(delayDivided[0]);
      Integer arrivalDelay = Integer.valueOf(delayDivided[1]);
      Integer departureDelayWithinSASControl = Integer.valueOf(delayDivided[2]);
      Integer arrivalDelayWithinSASControl = Integer.valueOf(delayDivided[3]);
      Integer netDelayOnArrival = Integer.valueOf(f.arrivalDelayedMinutes);
      Integer amountOfDelayEliminated =
        departureDelay +
        arrivalDelay -
        netDelayOnArrival; // Such as time made up for during flight. Todo: extend to count overlays (multiflight, requires refactor). (talk to liability about this)

      // Todo: Create N/A irregularities on irregularity-creation to cover so that this never happens
      if (amountOfDelayEliminated < 0) {
        throw new InvalidDelayException(
          'The actual delay is larger than the delay caused by irregularities.'
        );
      }

      Integer netDelayWithinSASControl =
        departureDelayWithinSASControl +
        arrivalDelayWithinSASControl -
        amountOfDelayEliminated;

      flightIdToDelay.put(f.id, netDelayWithinSASControl);
    }

    return flightIdToDelay;
  }
}
