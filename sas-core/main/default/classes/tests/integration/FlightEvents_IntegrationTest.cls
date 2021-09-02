@IsTest
public with sharing class FlightEvents_IntegrationTest {
  public static String flightIdFromTEDS = 'SK2569-20210410-ARN-CPH';
  public static String gateInDetailedFlightInfo = 'E135';

  public static FlightsSelector flights = (FlightsSelector) SAS_Service_Application.Selector.newInstance(
    Flight__c.SObjectType
  );

  @IsTest
  public static void publishingAFlightEventShouldFetchDataFromTEDS() {
    // Given
    Test.startTest();
    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );

    List<String> flightIds = new List<String>();
    flightIds.add(flightIdFromTEDS);

    List<Fetch_Flight__e> flightEvents = new List<Fetch_Flight__e>();
    flightEvents.add(
      new Fetch_Flight__e(Flight_Identifiers__c = String.join(flightIds, ','))
    );

    // When
    EventBus.publish(flightEvents);
    Test.getEventBus().deliver();
    Test.stopTest();

    // Then
    Flight__c flightFromDB = flights.selectByTEDSId(
      new Set<String>{ flightIdFromTEDS }
    )[0];

    System.assertEquals(
      gateInDetailedFlightInfo,
      flightFromDB.Departure_Gate__c,
      'Flight should exist and have detailed flight info.'
    );
  }
}
