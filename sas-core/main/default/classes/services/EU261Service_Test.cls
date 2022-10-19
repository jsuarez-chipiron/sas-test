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

    insert new List<SObject>{
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
      claimFirmBooking
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
      Seat__c = '1A'
    );
    Segment__c groupBookingSegment2 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '2A'
    );
    Segment__c groupBookingSegment3 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '3A'
    );
    Segment__c groupBookingSegment4 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '4A'
    );
    Segment__c groupBookingSegment5 = new Segment__c(
      Booking__c = groupBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '5A'
    );
    Segment__c differentLastNamesSegment1 = new Segment__c(
      Booking__c = differentLastNamesBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A'
    );
    Segment__c differentLastNamesSegment2 = new Segment__c(
      Booking__c = differentLastNamesBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '2A'
    );
    Segment__c missingTravelersSegment = new Segment__c(
      Booking__c = missingTravelersBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A'
    );
    Segment__c claimFirmSegment = new Segment__c(
      Booking__c = claimFirmBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A'
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
      rotationDelay
    };
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
      LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
      LIA_Claim__c.Customer_Claim_Type__c => 'Flight delay',
      LIA_Claim__c.Type_of_Customer__c => 'Private customer',
      LIA_Claim__c.Country__c => 'Sweden',
      LIA_Claim__c.Liability_PNR__c => bookingReference,
      LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
        Claim.RecordType.CustomerClaim
      )
    };
    claimFields.putAll(extraClaimFields);

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
  static void onlyOneWayTicketsCanBeEvaluated() {
    TestDataFactories.CasesClaims oneWayClaim = createDefaultTestClaim(
      oneWayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims dayReturnClaim = createDefaultTestClaim(
      dayReturnBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims multiCityClaim = createDefaultTestClaim(
      multiCityBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims roundTripClaim = createDefaultTestClaim(
      roundTripBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims unknownClaim = createDefaultTestClaim(
      unknownBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      oneWayClaim,
      dayReturnClaim,
      multiCityClaim,
      roundTripClaim,
      unknownClaim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.bookingType == Booking.Type.OneWay) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'One way claim should be possible to evaluate.'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'Other booking types should not be available for evaluation.'
        );
        System.assertEquals(
          'can handle only one way trips',
          c.decision.reasoning,
          'Rejection reason should be "can handle only one way trips"'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWhichDoNotRequirePOACanBeEvaluated() {
    TestDataFactories.CasesClaims groupClaim = createDefaultTestClaim(
      groupBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK9',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims differentLastNamesClaim = createDefaultTestClaim(
      differentLastNamesReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK9',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims missingTravelersFromBookingClaim = createDefaultTestClaim(
      missingTravelersBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK9',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims claimFirmClaim = createDefaultTestClaim(
      claimFirmBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Type_of_Customer__c => 'Claim firm',
        LIA_Claim__c.Flight_Number__c => 'SK9',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson',
      Claim__c = groupClaim.claims[0].Id
    );
    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson',
      Claim__c = groupClaim.claims[0].Id
    );
    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson',
      Claim__c = groupClaim.claims[0].Id
    );
    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson',
      Claim__c = groupClaim.claims[0].Id
    );
    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson',
      Claim__c = groupClaim.claims[0].Id
    );

    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = 'Birgitsdottir',
      Claim__c = differentLastNamesClaim.claims[0].Id
    );

    insert new Customer__c(
      First_Name__c = 'Birgit',
      Last_Name__c = 'Svensson',
      Claim__c = missingTravelersFromBookingClaim.claims[0].Id
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      groupClaim,
      differentLastNamesClaim,
      missingTravelersFromBookingClaim,
      claimFirmClaim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assert(
      claimsWithEvaluationDetails.size() == 4,
      'Should have evaluated four claims.'
    );
    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.claimObj.id == groupClaim.claims[0].Id) {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'It should not be possible to evaluate a claim with more than four travelers.'
        );
        System.assertEquals(
          'can handle only claims which do not require power of attorney',
          c.decision.reasoning,
          'Rejection reason should be "can handle only claims which do not require power of attorney"'
        );
      } else if (c.claimObj.id == differentLastNamesClaim.claims[0].Id) {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'It should not be possible to evaluate a claim with different last names.'
        );
        System.assertEquals(
          'can handle only claims which do not require power of attorney',
          c.decision.reasoning,
          'Rejection reason should be "can handle only claims which do not require power of attorney"'
        );
      } else if (
        c.claimObj.id == missingTravelersFromBookingClaim.claims[0].Id
      ) {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'It should not be possible to evaluate a claim when claimed travelers are not included in the booking.'
        );
        System.assertEquals(
          'can handle only claims which do not require power of attorney',
          c.decision.reasoning,
          'Rejection reason should be "can handle only claims which do not require power of attorney"'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'It should not be possible to evaluate a claim submitted by a claim firm.'
        );
        System.assertEquals(
          'can handle only claims which do not require power of attorney',
          c.decision.reasoning,
          'Rejection reason should be "can handle only claims which do not require power of attorney"'
        );
      }
    }
  }

  @IsTest
  static void claimsWithAnyNumberOfPassengersCanBeEvaluated() {
    TestDataFactories.CasesClaims individualClaim = createDefaultTestClaim(
      individualPassengerBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0009',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims coupleClaim = createDefaultTestClaim(
      coupleBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0009',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    insert new Customer__c(
      First_Name__c = 'Birgit',
      Last_Name__c = 'Svensson',
      Claim__c = coupleClaim.claims[0].Id
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      individualClaim,
      coupleClaim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.claimObj.id == individualClaim.claims[0].Id) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'It should be possible to evaluate a claim with a single passenger.'
        );
        System.assertEquals(
          250,
          c.decision.compensationAmount,
          'Compensation should be 250€'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'It should be possible to evaluate a claim with two passengers.'
        );
        System.assertEquals(
          500,
          c.decision.compensationAmount,
          'Compensation should be 800€'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWithOneBookingCanBeEvaluated() {
    TestDataFactories.CasesClaims claims = createDefaultTestClaim(
      duplicateBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claims
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (EU261Claim c : claimsWithEvaluationDetails) {
      if (c.claimedBooking.bookingReference == oneWayBookingReference) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.decision.verdict,
          'Claim with a single booking should be possible to evaluate.'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.UnableToHandle,
          c.decision.verdict,
          'Claim with more than one booking cannot be evaluated.'
        );
        System.assertEquals(
          'can handle only one booking per claim',
          c.decision.reasoning,
          'Rejection reason should be "can handle only one booking per claim"'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWithAirportsinEUCanBeEvaluated() {
    TestDataFactories.CasesClaims nonEUClaim = createDefaultTestClaim(
      nonEUBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0004',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      nonEUClaim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims claims = createDefaultTestClaim(
      claimExpensesBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claims
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    insert new Claim_Expense__c(
      Amount__c = 10,
      Currency__c = 'SEK',
      Type__c = 'Food',
      Claim__c = claims.claims[0].Id
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with expenses.'
    );
    System.assertEquals(
      'cannot handle claim expenses',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should be "cannot handle claim expenses"'
    );
  }

  @IsTest
  static void onlyClaimsWithin2to5HoursDelayCanBeEvaluated() {
    TestDataFactories.CasesClaims claimWithTooShortDelay = createDefaultTestClaim(
      tooShortDelayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0006',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims claimWithTooLongDelay = createDefaultTestClaim(
      tooLongDelayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0007',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claimWithTooShortDelay,
      claimWithTooLongDelay
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims claimWithMissingFlightFromBooking = createDefaultTestClaim(
      missingClaimedFlightBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0006',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claimWithMissingFlightFromBooking
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      twoIrregularitiesBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0005',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.debug(claimsWithEvaluationDetails[0].decision.reasoning);

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should be possible to evaluate claims with more than one irregularity.'
    );
  }

  @IsTest
  static void claimsWithRotationIrregularitiesCannotBeEvaluated() {
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      rotationBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0010',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      notOperatedBySASBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'LH0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-18')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // fflib_ApexMocks mocks = new fflib_ApexMocks();
    // BookingService mockList = (BookingService) mocks.mock(BookingService.class);
    // Test.setMock(BookingService.class, mockList);
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims existingClaim = createDefaultTestClaim(
      twoClaimsSameBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims claimBeingProcessed = createDefaultTestClaim(
      twoClaimsSameBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0001',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claimBeingProcessed
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should not be possible to evaluate claims with flights not operated by SAS.'
    );
    System.assertEquals(
      'cannot handle potential duplicates',
      claimsWithEvaluationDetails[0].decision.reasoning,
      'Rejection reason should be "cannot handle potential duplicates"'
    );
  }

  @IsTest
  static void minimalClaimShouldBeEvaluatedCorrectly() {
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      minimalClaimBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0009',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      250,
      claimsWithEvaluationDetails[0].decision.compensationAmount,
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      0,
      claimsWithEvaluationDetails[0].decision.reimbursementAmount,
      'Reimbursement should be 250 euros.'
    );
  }

  @IsTest
  static void minimalCancellationClaimWithoutRebookingCannotBeEvaluated() {
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      cancellationBookingWithinSASControlReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0008',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      cancellationBookingOutsideSASControlReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0011',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'It should be possible to evaluate minimal claims with cancellations outside SAS control and they should not receive any compensation.'
    );
  }

  @IsTest
  static void claimsWithUnsupportedCancellationCodesShouldNotBeAutomated() {
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      cancellationBookingUnsupportedReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0012',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      cancellationBookingTwoCancellationsReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0013',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
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
    TestDataFactories.CasesClaims c = createDefaultTestClaim(
      cancellationWithRebookingBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK0013',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation'
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      c
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Claim> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      claimsWithEvaluationDetails[0].decision.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      250,
      claimsWithEvaluationDetails[0].decision.compensationAmount,
      'We shuold pay out €250 for the minimal cancellation claim'
    );
  }
}
