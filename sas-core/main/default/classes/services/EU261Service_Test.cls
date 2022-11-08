// TODO: Split this into a few different classes of tests:
// 1. Tests for EU261Claim.evaluate()
// 2. Tests for overall function of the service class:
// 2.1. Create settlements
// 2.2. Send emails
// 2.3. Close cases

@IsTest
private class EU261Service_Test {
  private static String oneWayBookingReference = 'ONTIME';
  private static String dayReturnBookingReference = 'DAYRET';
  private static String multiCityBookingReference = 'MULTIC';
  private static String roundTripBookingReference = 'ROUNDT';
  private static String unknownBookingReference = 'UNKNOW';
  private static String individualPassengerBookingReference = 'INDIVI';
  private static String coupleBookingReference = 'COUPLEB';
  private static String oneWayBookingWithTwoSegmentsReference = 'TWOSEG';
  private static String duplicateBookingReference = 'DUPLIC';
  private static String withFileBookingReference = 'WITHF';
  private static String nonEUBookingReference = 'NONEUB';
  private static String twoIrregularitiesBookingReference = 'TWOIRR';
  private static String tooShortDelayBookingReference = 'TOOSHO';
  private static String tooLongDelayBookingReference = 'TOOLON';
  private static String cancellationBookingWithinSASControlReference = 'CANCEL';
  private static String cancellationBookingOutsideSASControlReference = 'CANCE2';
  private static String cancellationBookingUnsupportedReference = 'CANCE3';
  private static String cancellationBookingTwoCancellationsReference = 'CANCE4';
  private static String cancellationWithRebookingBookingReference = 'CANCE5';
  private static String validBookingReference = 'CANCE6';
  private static String missingClaimedFlightBookingReference = 'MISSIN';
  private static String claimExpensesBookingReference = 'EXPENS';
  private static String notOperatedBySASBookingReference = 'NOTOPE';
  private static String twoClaimsSameBookingReference = 'TWOCLA';
  private static String minimalClaimBookingReference = 'MINIMA';
  private static String rotationBookingReference = 'ROTATI';
  private static String groupBookingReference = 'GROUPB';
  private static String differentLastNamesReference = 'DIFFLA';
  private static String missingTravelersBookingReference = 'MISSTR';
  private static String claimFirmBookingReference = 'CLAIMF';
  private static String careDuplicateBookingReference = 'CAREDU';
  private static String twoFlightsCancelledInTimeBookingReference = 'TWOYES';
  private static String twoFlightsCancelledNotOnTimeBookingReference = 'TWONOT';

  public static Set<String> allTestPnrs = new Set<String>{
    'ONTIME',
    'DAYRET',
    'MULTIC',
    'ROUNDT',
    'UNKNOW',
    'INDIVI',
    'COUPLEB',
    'TWOSEG',
    'DUPLIC',
    'WITHF',
    'NONEUB',
    'TWOIRR',
    'TOOSHO',
    'TOOLON',
    'CANCEL',
    'MISSIN',
    'EXPENS',
    'NOTOPE',
    'TWOCLA',
    'GROUPB',
    'DIFFLA',
    'MISSTR',
    'CLAIMF',
    'MINIMA'
  };

  @TestSetup
  static void setup() {
    Cases.bypassTrigger = true;
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        EU261Service.AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME,
        EU261Service.AUTOMATION_REJECTED_EMAIL_TEMPLATE_NAME
      }
    );

    Exchange_Rate__c eurSekRate = new Exchange_Rate__c(
      From_Currency__c = 'EUR',
      To_Currency__c = 'SEK',
      Rate__c = 10,
      Date__c = Date.valueOf('2022-10-31'),
      Name = 'EUR-SEK'
    );

    Exchange_Rate__c sekEurRate = new Exchange_Rate__c(
      From_Currency__c = 'SEK',
      To_Currency__c = 'EUR',
      Rate__c = 0.1,
      Date__c = Date.valueOf('2022-10-31'),
      Name = 'EUR-SEK'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'HEL',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0001-20220817',
      Arrival_Delayed_Minutes__c = 190,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 4, 11, 0)
    );
    Flight__c flight2 = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'ARN',
      Operating_Carrier__c = 'SK',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      TEDS_Identifier__c = 'SK0002-20220817'
    );
    Flight__c flight3 = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0003-20220818',
      Arrival_Delayed_Minutes__c = 130,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c nonSASFlight = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'LH',
      TEDS_Identifier__c = 'LH0001-20220818',
      Arrival_Delayed_Minutes__c = 130,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c nonEUFlight = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'JFK',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0004-20220817',
      Arrival_Delayed_Minutes__c = 130,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 4, 11, 0)
    );
    Flight__c flightWithTwoIrregularities = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0005-20220817',
      Arrival_Delayed_Minutes__c = 190,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 4, 51, 0)
    );
    Flight__c flightWithTooShortDelay = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0006-20220817',
      Arrival_Delayed_Minutes__c = 30,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 31, 0)
    );
    Flight__c flightWithTooLongDelay = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0007-20220817',
      Arrival_Delayed_Minutes__c = 400,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 8, 41, 0)
    );
    Flight__c flightWithCancellationWithinSASControl = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0008-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0)
    );
    Flight__c flightForMinimalClaim = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0009-20220817',
      Arrival_Delayed_Minutes__c = 280,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 6, 41, 0)
    );
    Flight__c flightWithRotation = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0010-20220817',
      Arrival_Delayed_Minutes__c = 280,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 6, 41, 0)
    );
    Flight__c flightWithCancellationOutsideSASControl = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0011-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0)
    );
    Flight__c flightWithCancellationUnsupported = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0012-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0)
    );
    Flight__c flightWithTECHCancellation = new Flight__c(
      Arrival_Airport__c = 'CPH',
      Departure_Airport__c = 'HEL',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0013-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 4, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 6, 1, 0)
    );
    Flight__c flightWithTECHCancellationReplacement = new Flight__c(
      Arrival_Airport__c = 'CPH',
      Departure_Airport__c = 'HEL',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0014-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 8, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 11, 1, 0)
    );
    Flight__c flightWithCancellationOutsideSASControlReplacement = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0015-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 8, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 11, 1, 0)
    );
    Flight__c flightAfterFlightWithTECHCancellationNotMissed = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0016-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 12, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 14, 1, 0)
    );
    Flight__c flightAfterFlightWithTECHCancellationMissed = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0017-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 8, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 10, 1, 0)
    );
    Flight__c flightAfterFlightWithTECHCancellationMissedReplacement = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0018-20220817',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 13, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 15, 1, 0)
    );
    Airport__c airportHEL = new Airport__c(
      City__c = 'Helsinki',
      Country_Code__c = 'FI',
      Country_Name__c = 'Finland',
      TEDS_Identifier__c = 'HEL',
      Is_EU261_Applicable__c = true,
      Latitude__c = 60.317199707031,
      Longitude__c = 24.963300704956
    );
    Airport__c airportARN = new Airport__c(
      City__c = 'Stockholm',
      Country_Code__c = 'SE',
      Country_Name__c = 'Sweden',
      TEDS_Identifier__c = 'ARN',
      Is_EU261_Applicable__c = true,
      Latitude__c = 59.651901245117,
      Longitude__c = 17.918600082397
    );
    Airport__c airportCPH = new Airport__c(
      City__c = 'Copenhagen',
      Country_Code__c = 'DK',
      Country_Name__c = 'Denmark',
      TEDS_Identifier__c = 'CPH',
      Is_EU261_Applicable__c = true,
      Latitude__c = 55.617900848389,
      Longitude__c = 12.656000137329
    );
    Airport__c airportJFK = new Airport__c(
      City__c = 'New York',
      Country_Code__c = 'US',
      Country_Name__c = 'United States',
      TEDS_Identifier__c = 'JFK',
      Is_EU261_Applicable__c = false,
      Latitude__c = 40.639801,
      Longitude__c = -73.7789
    );
    Booking__c oneWayBooking = new Booking__c(
      Booking_Reference__c = oneWayBookingReference,
      TEDS_Identifier__c = 'uniqueBooking1',
      Type__c = 'OneWay'
    );
    Booking__c dayReturnBooking = new Booking__c(
      Booking_Reference__c = dayReturnBookingReference,
      TEDS_Identifier__c = 'uniqueBooking2',
      Type__c = 'DayReturn'
    );
    Booking__c multiCityBooking = new Booking__c(
      Booking_Reference__c = multiCityBookingReference,
      TEDS_Identifier__c = 'uniqueBooking3',
      Type__c = 'MultiCity'
    );
    Booking__c roundTripBooking = new Booking__c(
      Booking_Reference__c = roundTripBookingReference,
      TEDS_Identifier__c = 'uniqueBooking4',
      Type__c = 'RoundTrip'
    );
    Booking__c unknownBooking = new Booking__c(
      Booking_Reference__c = unknownBookingReference,
      TEDS_Identifier__c = 'uniqueBooking5',
      Type__c = 'Unknown'
    );
    Booking__c individualPassengerBooking = new Booking__c(
      Booking_Reference__c = individualPassengerBookingReference,
      TEDS_Identifier__c = 'uniqueBooking7',
      Type__c = 'OneWay'
    );
    Booking__c coupleBooking = new Booking__c(
      Booking_Reference__c = coupleBookingReference,
      TEDS_Identifier__c = 'uniqueBooking8',
      Type__c = 'OneWay'
    );
    Booking__c oneWayBookingWithTwoSegments = new Booking__c(
      Booking_Reference__c = oneWayBookingWithTwoSegmentsReference,
      TEDS_Identifier__c = 'uniqueBooking9',
      Type__c = 'OneWay'
    );
    Booking__c duplicateBookingOne = new Booking__c(
      Booking_Reference__c = duplicateBookingReference,
      TEDS_Identifier__c = 'uniqueBooking10',
      Type__c = 'OneWay'
    );
    Booking__c duplicateBookingTwo = new Booking__c(
      Booking_Reference__c = duplicateBookingReference,
      TEDS_Identifier__c = 'uniqueBooking11',
      Type__c = 'OneWay'
    );
    Booking__c withFileBooking = new Booking__c(
      Booking_Reference__c = withFileBookingReference,
      TEDS_Identifier__c = 'uniqueBooking12',
      Type__c = 'OneWay'
    );
    Booking__c nonEUBooking = new Booking__c(
      Booking_Reference__c = nonEUBookingReference,
      TEDS_Identifier__c = 'uniqueBooking13',
      Type__c = 'OneWay'
    );
    Booking__c twoIrregularitiesBooking = new Booking__c(
      Booking_Reference__c = twoIrregularitiesBookingReference,
      TEDS_Identifier__c = 'uniqueBooking14',
      Type__c = 'OneWay'
    );
    Booking__c tooShortDelayBooking = new Booking__c(
      Booking_Reference__c = tooShortDelayBookingReference,
      TEDS_Identifier__c = 'uniqueBooking15',
      Type__c = 'OneWay'
    );
    Booking__c tooLongDelayBooking = new Booking__c(
      Booking_Reference__c = tooLongDelayBookingReference,
      TEDS_Identifier__c = 'uniqueBooking16',
      Type__c = 'OneWay'
    );
    Booking__c cancellationBookingWithinSASControl = new Booking__c(
      Booking_Reference__c = cancellationBookingWithinSASControlReference,
      TEDS_Identifier__c = 'uniqueBooking17',
      Type__c = 'OneWay'
    );
    Booking__c missingClaimedFlightBooking = new Booking__c(
      Booking_Reference__c = missingClaimedFlightBookingReference,
      TEDS_Identifier__c = 'uniqueBooking18',
      Type__c = 'OneWay'
    );
    Booking__c claimExpensesBooking = new Booking__c(
      Booking_Reference__c = claimExpensesBookingReference,
      TEDS_Identifier__c = 'uniqueBooking19',
      Type__c = 'OneWay'
    );
    Booking__c notOperatedBySASBooking = new Booking__c(
      Booking_Reference__c = notOperatedBySASBookingReference,
      TEDS_Identifier__c = 'uniqueBooking20',
      Type__c = 'OneWay'
    );
    Booking__c twoClaimsSameBookingReferenceBooking = new Booking__c(
      Booking_Reference__c = twoClaimsSameBookingReference,
      TEDS_Identifier__c = 'uniqueBooking21',
      Type__c = 'OneWay'
    );
    Booking__c minimalClaimBooking = new Booking__c(
      Booking_Reference__c = minimalClaimBookingReference,
      TEDS_Identifier__c = 'uniqueBooking22',
      Type__c = 'OneWay'
    );
    Booking__c rotationBooking = new Booking__c(
      Booking_Reference__c = rotationBookingReference,
      TEDS_Identifier__c = 'uniqueBooking23',
      Type__c = 'OneWay'
    );
    Booking__c groupBooking = new Booking__c(
      Booking_Reference__c = groupBookingReference,
      TEDS_Identifier__c = 'uniqueBooking24',
      Type__c = 'OneWay'
    );
    Booking__c differentLastNamesBooking = new Booking__c(
      Booking_Reference__c = differentLastNamesReference,
      TEDS_Identifier__c = 'uniqueBooking25',
      Type__c = 'OneWay'
    );
    Booking__c missingTravelersBooking = new Booking__c(
      Booking_Reference__c = missingTravelersBookingReference,
      TEDS_Identifier__c = 'uniqueBooking26',
      Type__c = 'OneWay'
    );
    Booking__c claimFirmBooking = new Booking__c(
      Booking_Reference__c = claimFirmBookingReference,
      TEDS_Identifier__c = 'uniqueBooking27',
      Type__c = 'OneWay'
    );
    Booking__c cancellationBookingOutsideSASControl = new Booking__c(
      Booking_Reference__c = cancellationBookingOutsideSASControlReference,
      TEDS_Identifier__c = 'uniqueBooking28',
      Type__c = 'OneWay'
    );
    Booking__c cancellationBookingUnsupported = new Booking__c(
      Booking_Reference__c = cancellationBookingUnsupportedReference,
      TEDS_Identifier__c = 'uniqueBooking29',
      Type__c = 'OneWay'
    );
    Booking__c cancellationBookingTwoCancellations = new Booking__c(
      Booking_Reference__c = cancellationBookingTwoCancellationsReference,
      TEDS_Identifier__c = 'uniqueBooking30',
      Type__c = 'OneWay'
    );
    Booking__c cancellationBookingWithRebooking = new Booking__c(
      Booking_Reference__c = cancellationWithRebookingBookingReference,
      TEDS_Identifier__c = 'uniqueBooking31',
      Type__c = 'OneWay'
    );
    Booking__c careDuplicateBooking = new Booking__c(
      Booking_Reference__c = careDuplicateBookingReference,
      TEDS_Identifier__c = 'uniqueBooking32',
      Type__c = 'OneWay'
    );
    Booking__c twoFlightsCancelledInTimeBooking = new Booking__c(
      Booking_Reference__c = twoFlightsCancelledInTimeBookingReference,
      TEDS_Identifier__c = 'uniqueBooking33',
      Type__c = 'OneWay'
    );
    Booking__c twoFlightsCancelledNotInTimeBooking = new Booking__c(
      Booking_Reference__c = twoFlightsCancelledNotOnTimeBookingReference,
      TEDS_Identifier__c = 'uniqueBooking34',
      Type__c = 'OneWay'
    );
    Booking__c validBooking = new Booking__c(
      Booking_Reference__c = validBookingReference,
      TEDS_Identifier__c = 'uniqueBooking35',
      Type__c = 'OneWay'
    );

    insert new List<SObject>{
      eurSekRate,
      sekEurRate,
      airportHEL,
      airportARN,
      airportCPH,
      airportJFK,
      flight1,
      flight2,
      flight3,
      nonSASFlight,
      nonEUFlight,
      flightWithTwoIrregularities,
      flightWithTooShortDelay,
      flightWithTooLongDelay,
      flightWithCancellationWithinSASControl,
      flightWithCancellationOutsideSASControl,
      flightWithCancellationUnsupported,
      flightWithTECHCancellation,
      flightWithTECHCancellationReplacement,
      flightWithCancellationOutsideSASControlReplacement,
      flightForMinimalClaim,
      flightWithRotation,
      flightAfterFlightWithTECHCancellationNotMissed,
      flightAfterFlightWithTECHCancellationMissed,
      flightAfterFlightWithTECHCancellationMissedReplacement,
      oneWayBooking,
      dayReturnBooking,
      multiCityBooking,
      roundTripBooking,
      unknownBooking,
      individualPassengerBooking,
      coupleBooking,
      oneWayBookingWithTwoSegments,
      duplicateBookingOne,
      duplicateBookingTwo,
      withFileBooking,
      nonEUBooking,
      twoIrregularitiesBooking,
      tooShortDelayBooking,
      tooLongDelayBooking,
      cancellationBookingWithinSASControl,
      cancellationBookingOutsideSASControl,
      cancellationBookingUnsupported,
      cancellationBookingTwoCancellations,
      cancellationBookingWithRebooking,
      missingClaimedFlightBooking,
      claimExpensesBooking,
      notOperatedBySASBooking,
      twoClaimsSameBookingReferenceBooking,
      minimalClaimBooking,
      rotationBooking,
      groupBooking,
      differentLastNamesBooking,
      missingTravelersBooking,
      claimFirmBooking,
      careDuplicateBooking,
      twoFlightsCancelledInTimeBooking,
      twoFlightsCancelledNotInTimeBooking,
      validBooking
    };
    Segment__c oneWaySegment = new Segment__c(
      Booking__c = oneWayBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c dayReturnSegment1 = new Segment__c(
      Booking__c = dayReturnBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c dayReturnSegment2 = new Segment__c(
      Booking__c = dayReturnBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c roundTripSegment1 = new Segment__c(
      Booking__c = roundTripBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c roundTripSegment2 = new Segment__c(
      Booking__c = roundTripBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c multiCitySegment1 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c multiCitySegment2 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c multiCitySegment3 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight3.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c unknownSegment = new Segment__c(
      Booking__c = unknownBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c individualsSegment = new Segment__c(
      Booking__c = individualPassengerBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c husbandsSegment = new Segment__c(
      Booking__c = coupleBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c wifesSegment = new Segment__c(
      Booking__c = coupleBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1B',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoSegmentsOne = new Segment__c(
      Booking__c = oneWayBookingWithTwoSegments.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoSegmentsTwo = new Segment__c(
      Booking__c = oneWayBookingWithTwoSegments.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c duplicateBookingOneSegment = new Segment__c(
      Booking__c = duplicateBookingOne.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c duplicateBookingTwoSegment = new Segment__c(
      Booking__c = duplicateBookingTwo.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c withFileSegment = new Segment__c(
      Booking__c = withFileBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c nonEUSegment = new Segment__c(
      Booking__c = nonEUBooking.Id,
      Flight__c = nonEUFlight.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoIrregularitiesSegment = new Segment__c(
      Booking__c = twoIrregularitiesBooking.Id,
      Flight__c = flightWithTwoIrregularities.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c tooShortDelaySegment = new Segment__c(
      Booking__c = tooShortDelayBooking.Id,
      Flight__c = flightWithTooShortDelay.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c tooLongDelaySegment = new Segment__c(
      Booking__c = tooLongDelayBooking.Id,
      Flight__c = flightWithTooLongDelay.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c cancellationWithinSASControlSegment = new Segment__c(
      Booking__c = cancellationBookingWithinSASControl.Id,
      Flight__c = flightWithCancellationWithinSASControl.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c cancellationOutsideSASControlSegment1 = new Segment__c(
      Booking__c = cancellationBookingOutsideSASControl.Id,
      Flight__c = flightWithCancellationOutsideSASControl.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c cancellationOutsideSASControlSegment2 = new Segment__c(
      Booking__c = cancellationBookingOutsideSASControl.Id,
      Flight__c = flightWithCancellationOutsideSASControlReplacement.Id,
      Trip_Type__c = 'Outbound',
      Seat__c = '1A'
    );
    Segment__c cancellationUnsupportedSegment = new Segment__c(
      Booking__c = cancellationBookingUnsupported.Id,
      Flight__c = flightWithCancellationUnsupported.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c doubleCancellationSegment1 = new Segment__c(
      Booking__c = cancellationBookingTwoCancellations.Id,
      Flight__c = flightWithCancellationWithinSASControl.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c doubleCancellationSegment2 = new Segment__c(
      Booking__c = cancellationBookingTwoCancellations.Id,
      Flight__c = flightWithTECHCancellation.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c bookingRebookingSegment1 = new Segment__c(
      Booking__c = cancellationBookingWithRebooking.Id,
      Flight__c = flightWithTECHCancellation.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c bookingRebookingSegment2 = new Segment__c(
      Booking__c = cancellationBookingWithRebooking.Id,
      Flight__c = flightWithTECHCancellationReplacement.Id,
      Trip_Type__c = 'Outbound',
      Seat__c = '1A'
    );
    Segment__c missingClaimedFlightSegment = new Segment__c(
      Booking__c = missingClaimedFlightBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c claimExpensesSegment = new Segment__c(
      Booking__c = claimExpensesBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c notOperatedBySASSegment = new Segment__c(
      Booking__c = notOperatedBySASBooking.Id,
      Flight__c = nonSASFlight.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoClaimsSameBookingReferenceSegment = new Segment__c(
      Booking__c = twoClaimsSameBookingReferenceBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c minimalClaimSegment = new Segment__c(
      Booking__c = minimalClaimBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c careDuplicateClaimSegment = new Segment__c(
      Booking__c = careDuplicateBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c rotationSegment = new Segment__c(
      Booking__c = rotationBooking.Id,
      Flight__c = flightWithRotation.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Passenger__c oneWayPassenger = new Passenger__c(
      Booking__c = oneWayBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Segment__c groupBookingSegment1 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c groupBookingSegment2 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '2A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c groupBookingSegment3 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '3A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c groupBookingSegment4 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '4A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c groupBookingSegment5 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '5A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c differentLastNamesSegment1 = new Segment__c(
      Booking__c = differentLastNamesBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c differentLastNamesSegment2 = new Segment__c(
      Booking__c = differentLastNamesBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '2A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c missingTravelersSegment = new Segment__c(
      Booking__c = missingTravelersBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c claimFirmSegment = new Segment__c(
      Booking__c = claimFirmBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoFlightsCancelledInTimeSegment1 = new Segment__c(
      Booking__c = twoFlightsCancelledInTimeBooking.Id,
      Flight__c = flightWithTECHCancellation.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Cancelled'
    );
    Segment__c twoFlightsCancelledInTimeSegment2 = new Segment__c(
      Booking__c = twoFlightsCancelledInTimeBooking.Id,
      Flight__c = flightWithTECHCancellationReplacement.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoFlightsCancelledInTimeSegment3 = new Segment__c(
      Booking__c = twoFlightsCancelledInTimeBooking.Id,
      Flight__c = flightAfterFlightWithTECHCancellationNotMissed.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoFlightsCancelledNotInTimeSegment1 = new Segment__c(
      Booking__c = twoFlightsCancelledNotInTimeBooking.Id,
      Flight__c = flightWithTECHCancellation.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Cancelled'
    );
    Segment__c twoFlightsCancelledNotInTimeSegment2 = new Segment__c(
      Booking__c = twoFlightsCancelledNotInTimeBooking.Id,
      Flight__c = flightWithTECHCancellationReplacement.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c twoFlightsCancelledNotInTimeSegment3 = new Segment__c(
      Booking__c = twoFlightsCancelledNotInTimeBooking.Id,
      Flight__c = flightAfterFlightWithTECHCancellationMissed.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Cancelled'
    );
    Segment__c twoFlightsCancelledNotInTimeSegment4 = new Segment__c(
      Booking__c = twoFlightsCancelledNotInTimeBooking.Id,
      Flight__c = flightAfterFlightWithTECHCancellationMissedReplacement.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Segment__c validSegment = new Segment__c(
      Booking__c = validBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A',
      Trip_Type__c = 'Outbound'
    );
    Passenger__c dayReturnPassenger = new Passenger__c(
      Booking__c = dayReturnBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c roundTripPassenger = new Passenger__c(
      Booking__c = roundTripBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c multiCityPassenger = new Passenger__c(
      Booking__c = multiCityBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c unknownPassenger = new Passenger__c(
      Booking__c = unknownBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c individual = new Passenger__c(
      Booking__c = individualPassengerBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c husband = new Passenger__c(
      Booking__c = coupleBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c wife = new Passenger__c(
      Booking__c = coupleBooking.Id,
      Identifier__c = 'P2',
      First_Name__c = 'Birgit',
      Last_Name__c = 'Svensson'
    );
    Passenger__c twoSegmentsPassenger = new Passenger__c(
      Booking__c = oneWayBookingWithTwoSegments.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c duplicateBookingOnePassenger = new Passenger__c(
      Booking__c = duplicateBookingOne.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c duplicateBookingTwoPassenger = new Passenger__c(
      Booking__c = duplicateBookingTwo.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c withFilePassenger = new Passenger__c(
      Booking__c = withFileBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c nonEUPassenger = new Passenger__c(
      Booking__c = nonEUBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c twoIrregularitiesPassenger = new Passenger__c(
      Booking__c = twoIrregularitiesBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c tooShortDelayPassenger = new Passenger__c(
      Booking__c = tooShortDelayBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c tooLongDelayPassenger = new Passenger__c(
      Booking__c = tooLongDelayBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c cancellationWithinSASControlPassenger = new Passenger__c(
      Booking__c = cancellationBookingWithinSASControl.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c cancellationOutsideSASControlPassenger = new Passenger__c(
      Booking__c = cancellationBookingOutsideSASControl.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c cancellationUnsupportedPassenger = new Passenger__c(
      Booking__c = cancellationBookingUnsupported.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c twoCancellationsPassenger = new Passenger__c(
      Booking__c = cancellationBookingTwoCancellations.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c missingClaimedFlightPassenger = new Passenger__c(
      Booking__c = missingClaimedFlightBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c claimExpensesPassenger = new Passenger__c(
      Booking__c = claimExpensesBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c notOperatedBySASPassenger = new Passenger__c(
      Booking__c = notOperatedBySASBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c twoClaimsSameBookingReferencePassenger = new Passenger__c(
      Booking__c = twoClaimsSameBookingReferenceBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c minimalClaimPassenger = new Passenger__c(
      Booking__c = minimalClaimBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c rotationPassenger = new Passenger__c(
      Booking__c = rotationBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c groupPassenger1 = new Passenger__c(
      Booking__c = groupBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c groupPassenger2 = new Passenger__c(
      Booking__c = groupBooking.Id,
      Identifier__c = 'P2',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c groupPassenger3 = new Passenger__c(
      Booking__c = groupBooking.Id,
      Identifier__c = 'P3',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c groupPassenger4 = new Passenger__c(
      Booking__c = groupBooking.Id,
      Identifier__c = 'P4',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c groupPassenger5 = new Passenger__c(
      Booking__c = groupBooking.Id,
      Identifier__c = 'P5',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c differentLastNamesPassenger1 = new Passenger__c(
      Booking__c = differentLastNamesBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c differentLastNamesPassenger2 = new Passenger__c(
      Booking__c = differentLastNamesBooking.Id,
      Identifier__c = 'P2',
      First_Name__c = 'Sven',
      Last_Name__c = 'Birgitsdottir'
    );
    Passenger__c missingTravelersPassenger = new Passenger__c(
      Booking__c = missingTravelersBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c claimFirmPassenger = new Passenger__c(
      Booking__c = claimFirmBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c rebookedPassenger = new Passenger__c(
      Booking__c = cancellationBookingWithRebooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c careDuplicatePassenger = new Passenger__c(
      Booking__c = careDuplicateBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c twoFlightsCancelledNotInTimePassenger = new Passenger__c(
      Booking__c = twoFlightsCancelledNotInTimeBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c twoFlightsCancelledInTimePassenger = new Passenger__c(
      Booking__c = twoFlightsCancelledInTimeBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );
    Passenger__c validPassenger = new Passenger__c(
      Booking__c = validBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
    );

    FlightIrregularities__c flight1Delay = new FlightIrregularities__c(
      Flight__c = flight1.Id,
      Duration_minutes__c = 190,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c flight3Delay = new FlightIrregularities__c(
      Flight__c = flight3.Id,
      Duration_minutes__c = 130,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c nonEUFlightDelay = new FlightIrregularities__c(
      Flight__c = nonEUFlight.Id,
      Duration_minutes__c = 130,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c tooShortFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTooShortDelay.Id,
      Duration_minutes__c = 30,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c tooLongFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTooLongDelay.Id,
      Duration_minutes__c = 400,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c twoDelaysFirstFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTwoIrregularities.Id,
      Duration_minutes__c = 120,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c twoDelaysSecondFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTwoIrregularities.Id,
      Duration_minutes__c = 70,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c flightCancellationWithinSASControl = new FlightIrregularities__c(
      Flight__c = flightWithCancellationWithinSASControl.Id,
      Code__c = 'TECH',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = DateTime.newInstance(2022, 8, 10, 0, 1, 0)
    );
    FlightIrregularities__c flightCancellationOutsideSASControl = new FlightIrregularities__c(
      Flight__c = flightWithCancellationOutsideSASControl.Id,
      Code__c = 'WEAT',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = DateTime.newInstance(2022, 8, 10, 0, 1, 0)
    );
    FlightIrregularities__c flightCancellationUnsupported = new FlightIrregularities__c(
      Flight__c = flightWithCancellationUnsupported.Id,
      Code__c = 'AIRS',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = DateTime.newInstance(2022, 8, 10, 0, 1, 0)
    );
    FlightIrregularities__c flightCancellationTECH = new FlightIrregularities__c(
      Flight__c = flightWithTECHCancellation.Id,
      Code__c = 'TECH',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = DateTime.newInstance(2022, 8, 10, 0, 1, 0)
    );
    FlightIrregularities__c nonSASDelay = new FlightIrregularities__c(
      Flight__c = nonSASFlight.Id,
      Duration_minutes__c = 130,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c minimalClaimDelay = new FlightIrregularities__c(
      Flight__c = flightForMinimalClaim.Id,
      Duration_minutes__c = 280,
      Code__c = 'FA',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c rotationDelay = new FlightIrregularities__c(
      Flight__c = flightWithRotation.Id,
      Duration_minutes__c = 280,
      Code__c = 'RA',
      Type__c = 'Delay (arrival)'
    );

    insert new List<SObject>{
      oneWaySegment,
      dayReturnSegment1,
      dayReturnSegment2,
      roundTripSegment1,
      roundTripSegment2,
      multiCitySegment1,
      multiCitySegment2,
      multiCitySegment3,
      unknownSegment,
      individualsSegment,
      husbandsSegment,
      wifesSegment,
      twoSegmentsOne,
      twoSegmentsTwo,
      duplicateBookingOneSegment,
      duplicateBookingTwoSegment,
      withFileSegment,
      nonEUSegment,
      twoIrregularitiesSegment,
      tooShortDelaySegment,
      tooLongDelaySegment,
      cancellationWithinSASControlSegment,
      cancellationOutsideSASControlSegment1,
      cancellationOutsideSASControlSegment2,
      cancellationUnsupportedSegment,
      doubleCancellationSegment1,
      doubleCancellationSegment2,
      missingClaimedFlightSegment,
      claimExpensesSegment,
      notOperatedBySASSegment,
      twoClaimsSameBookingReferenceSegment,
      minimalClaimSegment,
      rotationSegment,
      bookingRebookingSegment1,
      bookingRebookingSegment2,
      groupBookingSegment1,
      groupBookingSegment2,
      groupBookingSegment3,
      groupBookingSegment4,
      groupBookingSegment5,
      differentLastNamesSegment1,
      differentLastNamesSegment2,
      missingTravelersSegment,
      claimFirmSegment,
      careDuplicateClaimSegment,
      validSegment,
      oneWayPassenger,
      dayReturnPassenger,
      roundTripPassenger,
      multiCityPassenger,
      unknownPassenger,
      twoSegmentsPassenger,
      individual,
      husband,
      wife,
      duplicateBookingOnePassenger,
      duplicateBookingTwoPassenger,
      withFilePassenger,
      nonEUPassenger,
      twoIrregularitiesPassenger,
      tooShortDelayPassenger,
      tooLongDelayPassenger,
      cancellationWithinSASControlPassenger,
      cancellationOutsideSASControlPassenger,
      cancellationUnsupportedPassenger,
      twoCancellationsPassenger,
      missingClaimedFlightPassenger,
      claimExpensesPassenger,
      notOperatedBySASPassenger,
      twoClaimsSameBookingReferencePassenger,
      minimalClaimPassenger,
      rotationPassenger,
      rebookedPassenger,
      groupPassenger1,
      groupPassenger2,
      groupPassenger3,
      groupPassenger4,
      groupPassenger5,
      differentLastNamesPassenger1,
      differentLastNamesPassenger2,
      missingTravelersPassenger,
      claimFirmPassenger,
      careDuplicatePassenger,
      validPassenger,
      flight1Delay,
      flight3Delay,
      nonEUFlightDelay,
      tooShortFlightDelay,
      tooLongFlightDelay,
      twoDelaysFirstFlightDelay,
      twoDelaysSecondFlightDelay,
      flightCancellationWithinSASControl,
      flightCancellationOutsideSASControl,
      flightCancellationUnsupported,
      flightCancellationTECH,
      nonSASDelay,
      minimalClaimDelay,
      rotationDelay,
      twoFlightsCancelledNotInTimePassenger,
      twoFlightsCancelledInTimePassenger,
      twoFlightsCancelledInTimeSegment1,
      twoFlightsCancelledInTimeSegment2,
      twoFlightsCancelledInTimeSegment3,
      twoFlightsCancelledNotInTimeSegment1,
      twoFlightsCancelledNotInTimeSegment2,
      twoFlightsCancelledNotInTimeSegment3,
      twoFlightsCancelledNotInTimeSegment4
    };

    TestDataFactories.CasesClaims individualClaim = createDefaultTestClaim(
      individualPassengerBookingReference,
      null
    );
    TestDataFactories.CasesClaims coupleClaim = createDefaultTestClaim(
      coupleBookingReference,
      null
    );
    TestDataFactories.CasesClaims duplicatePNRClaim = createDefaultTestClaim(
      duplicateBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims nonEUClaim = createDefaultTestClaim(
      nonEUBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0004'
      }
    );
    TestDataFactories.CasesClaims expenseClaim = createDefaultTestClaim(
      claimExpensesBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims claimWithTooShortDelay = createDefaultTestClaim(
      tooShortDelayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0006'
      }
    );
    TestDataFactories.CasesClaims claimWithTooLongDelay = createDefaultTestClaim(
      tooLongDelayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0007'
      }
    );
    TestDataFactories.CasesClaims claimWithMissingFlightFromBooking = createDefaultTestClaim(
      missingClaimedFlightBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0006'
      }
    );
    TestDataFactories.CasesClaims claimWithTwoIrregularities = createDefaultTestClaim(
      twoIrregularitiesBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0005'
      }
    );
    TestDataFactories.CasesClaims claimWithRotationIrregularity = createDefaultTestClaim(
      rotationBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0010'
      }
    );
    TestDataFactories.CasesClaims claimNotOperatedBySAS = createDefaultTestClaim(
      notOperatedBySASBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'LH0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-18')
      }
    );
    TestDataFactories.CasesClaims existingDuplicateClaim = createDefaultTestClaim(
      twoClaimsSameBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims newDuplicateClaim = createDefaultTestClaim(
      twoClaimsSameBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims minimalClaim = createDefaultTestClaim(
      minimalClaimBookingReference,
      null
    );
    TestDataFactories.CasesClaims claimCancellationWithinSASControl = createDefaultTestClaim(
      cancellationBookingWithinSASControlReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0008',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );
    TestDataFactories.CasesClaims claimCancellationOutsideSASControl = createDefaultTestClaim(
      cancellationBookingOutsideSASControlReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0011',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );
    TestDataFactories.CasesClaims claimUnsupportCancellation = createDefaultTestClaim(
      cancellationBookingUnsupportedReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0012',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );
    TestDataFactories.CasesClaims claimTwoCancellations = createDefaultTestClaim(
      cancellationBookingTwoCancellationsReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0013',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );
    TestDataFactories.CasesClaims claimWithValidRebooking = createDefaultTestClaim(
      cancellationWithRebookingBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0013',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );
    TestDataFactories.CasesClaims groupClaim = createDefaultTestClaim(
      groupBookingReference,
      null
    );
    TestDataFactories.CasesClaims differentLastNamesClaim = createDefaultTestClaim(
      differentLastNamesReference,
      null
    );
    TestDataFactories.CasesClaims missingTravelersFromBookingClaim = createDefaultTestClaim(
      missingTravelersBookingReference,
      null
    );
    TestDataFactories.CasesClaims claimFirmClaim = createDefaultTestClaim(
      claimFirmBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Type_of_Customer__c => 'Claim firm'
      }
    );
    TestDataFactories.CasesClaims oneWayClaim = createDefaultTestClaim(
      oneWayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims dayReturnClaim = createDefaultTestClaim(
      dayReturnBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims multiCityClaim = createDefaultTestClaim(
      multiCityBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims roundTripClaim = createDefaultTestClaim(
      roundTripBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims unknownClaim = createDefaultTestClaim(
      unknownBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001'
      }
    );
    TestDataFactories.CasesClaims careDuplicateClaim = createDefaultTestClaim(
      careDuplicateBookingReference,
      null
    );
    TestDataFactories.CasesClaims twoFlightsCancelledNotInTimeClaim = createDefaultTestClaim(
      twoFlightsCancelledNotOnTimeBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0013',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight Cancellation'
      }
    );
    TestDataFactories.CasesClaims twoFlightsCancelledInTimeClaim = createDefaultTestClaim(
      twoFlightsCancelledInTimeBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0013',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight Cancellation'
      }
    );
    TestDataFactories.CasesClaims validClaim = createDefaultTestClaim(
      validBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Preferred_Reimbursement_Method__c => 'EuroBonus Points'
      }
    );

    createCaseToBookings(
      new List<TestDataFactories.CasesClaims>{
        individualClaim,
        coupleClaim,
        duplicatePNRClaim,
        nonEUClaim,
        expenseClaim,
        claimWithTooShortDelay,
        claimWithTooLongDelay,
        claimWithMissingFlightFromBooking,
        claimWithTwoIrregularities,
        claimWithRotationIrregularity,
        claimNotOperatedBySAS,
        existingDuplicateClaim,
        newDuplicateClaim,
        minimalClaim,
        claimCancellationWithinSASControl,
        claimCancellationOutsideSASControl,
        claimUnsupportCancellation,
        claimTwoCancellations,
        claimWithValidRebooking,
        groupClaim,
        differentLastNamesClaim,
        missingTravelersFromBookingClaim,
        claimFirmClaim,
        oneWayClaim,
        dayReturnClaim,
        multiCityClaim,
        roundTripClaim,
        unknownClaim,
        careDuplicateClaim,
        twoFlightsCancelledNotInTimeClaim,
        twoFlightsCancelledInTimeClaim,
        validClaim
      }
    );

    insert new List<SObject>{
      new Customer__c(
        First_Name__c = 'Birgit',
        Last_Name__c = 'Svensson',
        Claim__c = coupleClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Sven',
        Last_Name__c = 'Svensson',
        Claim__c = groupClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Sven',
        Last_Name__c = 'Svensson',
        Claim__c = groupClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Sven',
        Last_Name__c = 'Svensson',
        Claim__c = groupClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Sven',
        Last_Name__c = 'Svensson',
        Claim__c = groupClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Sven',
        Last_Name__c = 'Svensson',
        Claim__c = groupClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Sven',
        Last_Name__c = 'Birgitsdottir',
        Claim__c = differentLastNamesClaim.claims[0].Id
      ),
      new Customer__c(
        First_Name__c = 'Birgit',
        Last_Name__c = 'Svensson',
        Claim__c = missingTravelersFromBookingClaim.claims[0].Id
      ),
      new Claim_Expense__c(
        Amount__c = 10,
        Currency__c = 'SEK',
        Type__c = 'Food',
        Claim__c = expenseClaim.claims[0].Id
      ),
      new Claim_Expense__c(
        Amount__c = 10,
        Currency__c = 'SEK',
        Type__c = 'Food',
        Claim__c = validClaim.claims[0].Id
      )
    };

    Cases.bypassTrigger = false;
  }

  private static void createCaseToBookings(
    List<TestDataFactories.CasesClaims> casesClaims
  ) {
    List<String> pnrs = new List<String>();

    for (TestDataFactories.CasesClaims c : casesClaims) {
      pnrs.add(c.cases[0].Initially_Provided_PNR__c);
    }

    List<Booking__c> bookings = [
      SELECT Id, Booking_Reference__c
      FROM Booking__c
      WHERE Booking_Reference__c IN :pnrs
    ];

    List<SObject> toInsert = new List<SObject>();

    for (Booking__c b : bookings) {
      for (TestDataFactories.CasesClaims c : casesClaims) {
        if (c.cases[0].Initially_Provided_PNR__c == b.Booking_Reference__c) {
          toInsert.add(
            new CaseToBooking__c(Booking__c = b.Id, Case__c = c.cases[0].Id)
          );
        }
      }
    }

    insert toInsert;
  }

  private static TestDataFactories.CasesClaims createDefaultTestClaim(
    String bookingReference,
    Map<Schema.SObjectField, Object> extraClaimFields
  ) {
    Map<Schema.SObjectField, Object> claimFields = new Map<Schema.SObjectField, Object>{
      LIA_Claim__c.Address_line_1__c => 'Frösundaviks allé 1',
      LIA_Claim__c.Bank_Account_Holder_Name__c => 'Test testsson',
      LIA_Claim__c.Bank_Account_Number__c => 'SE7280000810340009783242',
      LIA_Claim__c.Bank_Country__c => 'Sweden',
      LIA_Claim__c.BIC_Swift__c => 'CITIUS33',
      LIA_Claim__c.City__c => 'Solna',
      LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
      LIA_Claim__c.Country__c => 'Sweden',
      LIA_Claim__c.Currency__c => 'SEK',
      LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
      LIA_Claim__c.Customer_Claim_Type__c => 'Flight delay',
      LIA_Claim__c.EuroBonus_Number__c => '123456789',
      LIA_Claim__c.Flight_Number__c => 'SK0009',
      LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
      LIA_Claim__c.Liability_PNR__c => bookingReference,
      LIA_Claim__c.Postal_Code__c => '11200',
      LIA_Claim__c.Preferred_Compensation_Method__c => 'Monetary',
      LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
        Claim.RecordType.CustomerClaim
      ),
      LIA_Claim__c.Type_of_Customer__c => 'Private customer'
    };
    if (extraClaimFields != null) {
      claimFields.putAll(extraClaimFields);
    }

    TestDataFactories.CasesClaims toReturn = TestDataFactories.createCasesWithClaims(
      1,
      new Map<Schema.SObjectField, Object>{
        Case.Initially_Provided_PNR__c => bookingReference
      },
      claimFields
    );

    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = toReturn.claims[0].Contact_Last_Name__c,
      Claim__c = toReturn.claims[0].Id
    );

    return toReturn;
  }

  private static Set<Id> getClaimIds(
    List<TestDataFactories.CasesClaims> casesClaims
  ) {
    Set<Id> claimIds = new Set<Id>();
    for (TestDataFactories.CasesClaims c : casesClaims) {
      for (LIA_Claim__c claim : c.claims) {
        claimIds.add(claim.Id);
      }
    }

    return claimIds;
  }

  @IsTest
  static void onlyOneWayAndRoundTripTicketsCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE
            Liability_PNR__c = :oneWayBookingReference
            OR Liability_PNR__c = :dayReturnBookingReference
            OR Liability_PNR__c = :multiCityBookingReference
            OR Liability_PNR__c = :roundTripBookingReference
            OR Liability_PNR__c = :unknownBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.claimedBooking.type == Booking.Type.OneWay) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'One way claim should be possible to evaluate.'
        );
      } else if (c.claimedBooking.type == Booking.Type.RoundTrip) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'Round trip claim should be possible to evaluate.'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'Other booking types should not be available for evaluation.'
        );
        System.assertEquals(
          'can handle only one way or round trips',
          c.decision.reasoning,
          'Rejection reason should be "can handle only one way or round trips"'
        );
      }
    }

    LIA_Claim__c settledClaimAfterEvaluation = [
      SELECT EU261_Handling_Status__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c = :oneWayBookingReference
    ];

    System.assertEquals(
      'Eligible for compensation',
      settledClaimAfterEvaluation.EU261_Handling_Status__c,
      'Claims should have been updated in DB.'
    );
  }

  @IsTest
  static void onlyClaimsWhichDoNotRequirePOACanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE
            Liability_PNR__c = :groupBookingReference
            OR Liability_PNR__c = :differentLastNamesReference
            OR Liability_PNR__c = :missingTravelersBookingReference
            OR Liability_PNR__c = :claimFirmBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assert(
      claimsWithEvaluationDetails.size() == 4,
      'Should have evaluated four claims.'
    );
    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.claimObj.bookingReference == groupBookingReference) {
        System.assertEquals(
          Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
          c.decision.verdict,
          'It should not be possible to automatically evaluate a claim with more than four travelers.'
        );
        System.assertEquals(
          'caveats: requires a power of attorney',
          c.decision.reasoning,
          'Reasoning should include caveat on power of attorney'
        );
      } else if (c.claimObj.bookingReference == differentLastNamesReference) {
        System.assertEquals(
          Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
          c.decision.verdict,
          'It should not be possible to automatically evaluate a claim with different last names.'
        );
        System.assertEquals(
          'caveats: requires a power of attorney',
          c.decision.reasoning,
          'Reasoning should include caveat on power of attorney'
        );
      } else if (
        c.claimObj.bookingReference == missingTravelersBookingReference
      ) {
        System.assertEquals(
          Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
          c.decision.verdict,
          'It should not be possible to automatically evaluate a claim when claimed travelers are not included in the booking.'
        );
        System.assertEquals(
          'caveats: requires a power of attorney',
          c.decision.reasoning,
          'Reasoning should include caveat on power of attorney'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
          c.decision.verdict,
          'It should not be possible to evaluate a claim submitted by a claim firm.'
        );
        System.assertEquals(
          'caveats: requires a power of attorney',
          c.decision.reasoning,
          'Reasoning should include caveat on power of attorney'
        );
      }
    }
  }

  @IsTest
  static void claimsWithAnyNumberOfPassengersCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE
            Liability_PNR__c = :individualPassengerBookingReference
            OR Liability_PNR__c = :coupleBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    EU261Service es = EU261Service.newInstance();
    es.config.enabledSettlements = true;
    es.config.enabledRejections = true;
    es.config.percentageRequiringManualApproval = 0;
    List<EU261Claim> claimsWithEvaluationDetails = es.automateEU261Claims(
      claimIds,
      uow
    );
    uow.commitWork();
    Test.stopTest();

    List<Settlement__c> settlementsForClaim = [
      SELECT Id, Amount__c, Claim__c, Currency__c
      FROM Settlement__c
      WHERE Claim__c IN :claimIds
    ];

    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.claimObj.customers.size() == 1) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'It should be possible to evaluate a claim with a single passenger.'
        );
        System.assertEquals(
          new Money(250, Money.CurrencyCode.EUR),
          c.decision.compensationPerCustomerInEUR.get(c.claimObj.customers[0]),
          'Compensation amount should be 250 €'
        );
        Settlement__c settlementForClaim;

        for (Settlement__c s : settlementsForClaim) {
          if (s.Claim__c == c.claimObj.id) {
            settlementForClaim = s;
          }
        }

        System.assertEquals(
          2500.00,
          settlementForClaim.Amount__c,
          'Settlement total should be smaller for one passenger.'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'It should be possible to evaluate a claim with two passengers.'
        );
        System.assertEquals(
          new Money(250, Money.CurrencyCode.EUR),
          c.decision.compensationPerCustomerInEUR.get(c.claimObj.customers[0]),
          'Compensation should be 250€ for first customer'
        );
        System.assertEquals(
          new Money(250, Money.CurrencyCode.EUR),
          c.decision.compensationPerCustomerInEUR.get(c.claimObj.customers[1]),
          'Compensation should be 250€ for second customer'
        );

        Settlement__c settlementForClaim;
        for (Settlement__c s : settlementsForClaim) {
          if (s.Claim__c == c.claimObj.id) {
            settlementForClaim = s;
          }
        }

        System.assertEquals(
          'SEK',
          settlementForClaim.Currency__c,
          'Currency should be set based on preferred currency.'
        );

        System.assertEquals(
          5000.00,
          settlementForClaim.Amount__c,
          'Settlement total should be higher for two passengers.'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWithOneBookingCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :duplicateBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'Claim with more than one booking cannot be evaluated.'
    );
    System.assertEquals(
      'can handle only one booking per claim',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should be "can handle only one booking per claim"'
    );
  }

  @IsTest
  static void onlyClaimsWithAirportsinEUCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :nonEUBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (claimIds.contains(c.claimObj.id)) {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'It should not be possible to evaluate claims with files.'
        );
        System.assertEquals(
          'can only handle claims with origin and destination airports in EU',
          c.decision.reasoning,
          'Rejection reason should be "can only handle claims with origin and destination airports in EU"'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWithoutExpensesCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :claimExpensesBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to automatically evaluate claims with expenses.'
    );
    System.assertEquals(
      'caveats: has high claim expenses',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should include caveat about expenses'
    );
  }

  @IsTest
  static void onlyClaimsWithin2to5HoursDelayCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE
            Liability_PNR__c = :tooShortDelayBookingReference
            OR Liability_PNR__c = :tooLongDelayBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    for (EU261Claim c : claimsWithEvaluationDetails) {
      System.assertEquals(
        Claim.EU261HandlingStatus.UnableToHandle,
        c.decision.verdict,
        'It should not be possible to evaluate claims with too long or too short delay.'
      );
      System.assertEquals(
        'can handle only delays between 2 and 5 hours',
        c.decision.reasoning,
        'Rejection reason should be "can handle only delays between 2 and 5 hours"'
      );
    }
  }

  @IsTest
  static void onlyClaimsWithClaimedFlightInBookingCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :missingClaimedFlightBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with flight missing from booking.'
    );
    System.assertEquals(
      'cannot find claimed flight from booking',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should be "cannot find claimed flight from booking"'
    );
  }

  @IsTest
  static void claimsWithMoreThanOneIrregularityCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :twoIrregularitiesBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should be possible to evaluate claims with more than one irregularity.'
    );
  }

  @IsTest
  static void claimsWithRotationIrregularitiesCannotBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :rotationBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with rotation delays.'
    );
    System.assertEquals(
      'cannot handle flights with irregularities caused by rotations',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should be "cannot handle flights with irregularities caused by rotations"'
    );
  }

  @IsTest
  static void onlyClaimsWithFlightsOperatedBySASCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :notOperatedBySASBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with flights not operated by SAS.'
    );
    System.assertEquals(
      'cannot handle claims where SAS is not the only operating carrier',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should be "cannot handle claims where SAS is not the only operating carrier"'
    );
  }

  @IsTest
  static void onlyClaimsWithoutDuplicatesCanBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :twoClaimsSameBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to automatically evaluate claims with possible duplicates.'
    );
    System.assertEquals(
      'caveats: has potential duplicates',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should include caveat about duplicates'
    );
  }

  @IsTest
  static void onlyClaimsWithoutCAREDuplicatesCanBeEvaluated() {
    insert new CARE_Claim__c(
      Booking_Reference__c = careDuplicateBookingReference,
      Flight_Number__c = 'SK0009' // This is the default flight number for claims in these tests
    );
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :careDuplicateBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to automatically evaluate claims with possible CARE duplicates.'
    );
    System.assertEquals(
      'caveats: has potential duplicates',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should include caveat about duplicates'
    );
  }

  @IsTest
  static void minimalClaimShouldBeEvaluatedCorrectly() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :minimalClaimBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      claimsWithEvaluationDetails[0]
        .decision.compensationPerCustomerInEUR.get(
          claimsWithEvaluationDetails[0].claimObj.customers[0]
        ),
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      claimsWithEvaluationDetails[0].decision.reimbursementAmountInSEK,
      'Reimbursement should be 0 SEK.'
    );
  }

  @IsTest
  static void minimalCancellationClaimWithoutRebookingCannotBeEvaluated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :cancellationBookingWithinSASControlReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'No rebooking cannot be automated.'
    );
    System.assertEquals(
      'this trip type is not yet supported for automated cancellation handling',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'This trip type should not be supported.'
    );
  }

  @IsTest
  static void minimalCancellationClaimsWithCancellationsOutsideSASControlShouldBeDenied() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE
            Liability_PNR__c = :cancellationBookingOutsideSASControlReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should be possible to evaluate minimal claims with cancellations outside SAS control and they should not receive any compensation.'
    );
  }

  @IsTest
  static void claimsWithUnsupportedCancellationCodesShouldNotBeAutomated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :cancellationBookingUnsupportedReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with unsupported cancellation codes.'
    );
    System.assertEquals(
      'cannot determine wether SAS is responsible or not for the cancellation',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Unhandled reason should be "cannot determine wether SAS is responsible or not for the cancellation"'
    );
  }

  @IsTest
  static void claimsWithTwoCancellationsShouldNotBeAutomated() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :cancellationBookingTwoCancellationsReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    uow.commitWork();
    Test.stopTest();

    // TODO: Fixme
    /*System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with unsupported cancellation codes.'
    );
    System.assertEquals(
      'there are more than one cancellation connected to this claim',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Unhandled reason should be "there are more than one cancellation connected to this claim"'
    );*/
  }

  @IsTest
  static void minimalCancellationClaimShouldBeAutomatedCorrectly() {
    // A rebooked flight which arrives 3h later than the original flight.
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :cancellationWithRebookingBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    EU261Service es = EU261Service.newInstance();
    es.config.enabledSettlements = true;
    es.config.enabledRejections = true;
    es.config.percentageRequiringManualApproval = 0;
    List<EU261Claim> claimsWithEvaluationDetails = es.automateEU261Claims(
      claimIds,
      uow
    );
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      claimsWithEvaluationDetails[0]
        .decision.compensationPerCustomerInEUR.get(
          claimsWithEvaluationDetails[0].claimObj.customers[0]
        ),
      'We should pay out €250 for the minimal cancellation claim'
    );

    Settlement__c settlementForClaim = [
      SELECT Id, Amount__c
      FROM Settlement__c
      WHERE Claim__c = :claimsWithEvaluationDetails[0].claimObj.id
    ][0];

    System.assertEquals(
      2500.0,
      settlementForClaim.Amount__c,
      'Settlement amount should be multiplied by the exchange rate.'
    );

    Case caseForClaim = [
      SELECT Id, Status
      FROM Case
      WHERE
        Initially_Provided_PNR__c = :cancellationWithRebookingBookingReference
    ][0];

    System.assertEquals(
      'Closed',
      caseForClaim.Status,
      'Parent case should be closed after handling.'
    );
  }

  @IsTest
  static void claimWithAllowedExpensesShouldBeAutomatedCorrectly() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :validBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    EU261Service es = EU261Service.newInstance();
    es.config.enabledSettlements = true;
    es.config.enabledRejections = true;
    es.config.percentageRequiringManualApproval = 0;
    es.config.expenseLimitFood = new Money(100, Money.CurrencyCode.SEK);
    es.config.expenseLimitTotal = new Money(1000, Money.CurrencyCode.SEK);
    List<EU261Claim> claimsWithEvaluationDetails = es.automateEU261Claims(
      claimIds,
      uow
    );
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      claimsWithEvaluationDetails[0]
        .decision.compensationPerCustomerInEUR.get(
          claimsWithEvaluationDetails[0].claimObj.customers[0]
        ),
      'We should pay out €250 for the minimal cancellation claim'
    );
    System.assertEquals(
      new Money(10, Money.CurrencyCode.SEK),
      claimsWithEvaluationDetails[0].decision.reimbursementAmountInSEK,
      'We should pay out 10 SEK for reimbursement'
    );

    List<Settlement__c> settlementsForClaim = [
      SELECT Id, Amount__c, EuroBonus_Points__c, RecordTypeId
      FROM Settlement__c
      WHERE Claim__c = :claimsWithEvaluationDetails[0].claimObj.id
    ];

    System.assertEquals(
      2,
      settlementsForClaim.size(),
      'Separate compensation and reimbursement settlements should have been created'
    );

    System.assertEquals(
      2500.0,
      settlementsForClaim[0].Amount__c,
      'Settlement amount should be multiplied by the exchange rate.'
    );

    System.assertEquals(
      Settlements.getRecordTypeId(Settlements.RecordType.EBPoints),
      settlementsForClaim[1].RecordTypeId,
      'Reimbursement settlement should be in eb points'
    );
    System.assertEquals(
      null,
      settlementsForClaim[1].Amount__c,
      'Points settlement for reimbursement should have amount as null'
    );
    System.assertEquals(
      100,
      settlementsForClaim[1].EuroBonus_Points__c,
      'Points settlement for reimbursement should have 10 SEK worth of points'
    );

    Case caseForClaim = [
      SELECT Id, Status
      FROM Case
      WHERE Initially_Provided_PNR__c = :validBookingReference
    ][0];

    System.assertEquals(
      'Closed',
      caseForClaim.Status,
      'Parent case should be closed after handling.'
    );
  }

  @IsTest
  static void claimsWithTwoFlightsAndOneCancellationNotOnTimeShouldBeApproved() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :twoFlightsCancelledNotOnTimeBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    EU261Claim twoFlightsClaim = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow)[0];
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      twoFlightsClaim.decision.verdict,
      'If a cancelled flight leads to a missed connection and a delay of +3 hours the customer should be eligble for compensation (two flights).'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      twoFlightsClaim.decision.compensationPerCustomerInEUR.values()[0],
      'The customer should be awarded 250 eur (two flights)'
    );
  }

  @IsTest
  static void claimsWithTwoFlightsANDOneCancellationButOnTimeShouldBeDenied() {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c = :twoFlightsCancelledInTimeBookingReference
        ]
      ))
      .keySet();

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    EU261Claim twoFlightsClaim = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow)[0];
    uow.commitWork();
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      twoFlightsClaim.decision.verdict,
      'If a cancelled flight does not affect the final arrival time the customer should not be compensated (two flights).'
    );
    System.assertEquals(
      'the offered rebooking is not outside the timeframe allowed by EU261',
      twoFlightsClaim.decision.reasoning,
      'If a cancelled flight does not affect the final arrival time the customer should not be compensated (two flights).'
    );
  }

  @IsTest
  static void simpleEvaluation() {
    Datetime departure = DateTime.newInstance(2020, 10, 10, 1, 1, 1);
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0013', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0014', newDeparture, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    fis[0].cancellationTime = departure.addDays(-1);
    f1.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer(new Customer__c());
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0013';
    c.departureDate = departure.date();
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.recordType = Claim.RecordType.CustomerClaim;

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.RoundTrip;

    Passenger extraPassenger = TestPassengerFactory.create(b);
    b.passengers.add(extraPassenger); // Total 2 passengers

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      result.verdict,
      Claim.EU261HandlingStatus.EligibleForCompensation,
      'Simple one way claim should be eligible for compensation.'
    );
    System.assertEquals(
      result.compensationPerCustomer.values()[0],
      250,
      'Simple one way claim should be eligible for compensation.'
    );
  }
}
