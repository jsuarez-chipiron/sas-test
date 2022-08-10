@IsTest
public with sharing class FlightService_IntegrationTest {
  public static String flightIdFromTEDS = 'SK2569-20210410-ARN-CPH';
  public static String gateInDetailedFlightInfo = 'E135';
  public static String delayedFlightIdFromTEDS = 'WF0075-20220531-TRD-OSL';
  public static String cancelledFlightIdFromTEDS = 'LH2434-20220531-MUC-BLL';
  public static String delayReason = 'CABIN CREW ROTATION';
  public static String cancellationReason = 'CNL MAY D/T TRAVEL RESTRICTIONS BRGDS MUC LNR GP SENT MUCOALH';

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

  @IsTest
  public static void shouldInsertDelayedFlightIrregularitiesByFlightId() {
    // Given
    Set<String> flightIds = new Set<String>();
    flightIds.add(delayedFlightIdFromTEDS);
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    FlightService.newInstance().fetchFlightsByReference(flightIds, true);
    Test.stopTest();

    // Then
    List<FlightIrregularities__c> irregularitiesListDelayed = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(new Set<String>{ delayedFlightIdFromTEDS });

    FlightIrregularities__c sampleIrregularity = new FlightIrregularities__c();
    for (FlightIrregularities__c fi : irregularitiesListDelayed) {
      if (fi.Reason__c == delayReason) {
        sampleIrregularity = fi;
      }
    }

    System.assertEquals(
      delayReason,
      sampleIrregularity.Reason__c,
      'Flightirregularity with delay not correctly inserted.'
    );
    System.assertEquals(
      'RS',
      sampleIrregularity.Code__c,
      'Flightirregularity with delay not correctly inserted.'
    );
  }
  @IsTest
  public static void shouldInsertCancelledFlightIrregularitiesByFlightId() {
    // Given
    Set<String> flightIds = new Set<String>();
    flightIds.add(cancelledFlightIdFromTEDS);
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    FlightService.newInstance().fetchFlightsByReference(flightIds, true);
    Test.stopTest();

    // Then
    List<FlightIrregularities__c> irregularitiesListCancelled = FlightIrregularitiesSelector.newInstance()
      .selectByTEDSFlightId(new Set<String>{ cancelledFlightIdFromTEDS });

    FlightIrregularities__c sampleIrregularity = new FlightIrregularities__c();
    for (FlightIrregularities__c fi : irregularitiesListCancelled) {
      if (fi.Reason__c == cancellationReason) {
        sampleIrregularity = fi;
      }
    }

    System.assertEquals(
      cancellationReason,
      sampleIrregularity.Reason__c,
      'Flightirregularity with cancellation not correctly inserted.'
    );
    System.assertEquals(
      'AIRS',
      sampleIrregularity.Code__c,
      'Flightirregularity with cancellation not correctly inserted.'
    );
  }
}
