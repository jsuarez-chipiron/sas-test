@IsTest
public with sharing class FlightService_IntegrationTest {
  public static String flightIdFromTEDS = 'SK2569-20210410-ARN-CPH';
  public static String gateInDetailedFlightInfo = 'E135';

  @IsTest
  public static void shouldFetchFlightsByFlightId() {
    // Given
    Set<String> flightIds = new Set<String>();
    flightIds.add(flightIdFromTEDS);
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    FlightService.newInstance().fetchFlightsByReference(flightIds, true);
    Test.stopTest();

    // Then
    Flight__c flightFromDB = FlightsSelector.newInstance()
      .selectByTEDSId(new Set<String>{ flightIdFromTEDS })[0];

    System.assertEquals(
      gateInDetailedFlightInfo,
      flightFromDB.Departure_Gate__c,
      'Flight should exist and have detailed flight info.'
    );
  }
}
