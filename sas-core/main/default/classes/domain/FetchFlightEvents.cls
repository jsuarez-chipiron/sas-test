public without sharing class FetchFlightEvents {
  public static void onAfterInsert(List<Fetch_Flight__e> Records) {
    for (Fetch_Flight__e flightEvent : Records) {
      FlightService.fetchFlightsByFlightReference(
        flightEvent.Flight_Identifiers__c
      );
    }
  }
}
