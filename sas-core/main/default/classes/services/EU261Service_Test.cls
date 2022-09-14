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
  private static String cancellationBookingReference = 'CANCEL';
  private static String missingClaimedFlightBookingReference = 'MISSIN';
  private static String claimExpensesBookingReference = 'EXPENS';
  private static String notOperatedBySASBookingReference = 'NOTOPE';
  private static String twoClaimsSameBookingReference = 'TWOCLA';
  private static String minimalClaimBookingReference = 'MINIMA';
  private static String rotationBookingReference = 'ROTATI';

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
    'MINIMA'
  };

  @TestSetup
  static void setup() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'HEL',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK1-20220817',
      Arrival_Delayed_Minutes__c = 130,
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
      TEDS_Identifier__c = 'SK2-20220817'
    );
    Flight__c flight3 = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK3-20220818',
      Arrival_Delayed_Minutes__c = 130,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c nonSASFlight = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'LH',
      TEDS_Identifier__c = 'LH1-20220818',
      Arrival_Delayed_Minutes__c = 130,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );
    Flight__c nonEUFlight = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'JFK',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK4-20220817',
      Arrival_Delayed_Minutes__c = 130,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 4, 11, 0)
    );
    Flight__c flightWithTwoIrregularities = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK5-20220817',
      Arrival_Delayed_Minutes__c = 170,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 4, 51, 0)
    );
    Flight__c flightWithTooShortDelay = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK6-20220817',
      Arrival_Delayed_Minutes__c = 30,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 31, 0)
    );
    Flight__c flightWithTooLongDelay = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK7-20220817',
      Arrival_Delayed_Minutes__c = 400,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 8, 41, 0)
    );
    Flight__c flightWithCancellation = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK8-20220817'
    );
    Flight__c flightForMinimalClaim = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK9-20220817',
      Arrival_Delayed_Minutes__c = 280,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 6, 41, 0)
    );
    Flight__c flightWithRotation = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK10-20220817',
      Arrival_Delayed_Minutes__c = 280,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 6, 41, 0)
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
    Booking__c cancellationBooking = new Booking__c(
      Booking_Reference__c = cancellationBookingReference,
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
      flightWithCancellation,
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
      cancellationBooking,
      missingClaimedFlightBooking,
      claimExpensesBooking,
      notOperatedBySASBooking,
      twoClaimsSameBookingReferenceBooking,
      minimalClaimBooking,
      rotationBooking
    };
    Segment__c oneWaySegment = new Segment__c(
      Booking__c = oneWayBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c dayReturnSegment1 = new Segment__c(
      Booking__c = dayReturnBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c dayReturnSegment2 = new Segment__c(
      Booking__c = dayReturnBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A'
    );
    Segment__c roundTripSegment1 = new Segment__c(
      Booking__c = roundTripBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c roundTripSegment2 = new Segment__c(
      Booking__c = roundTripBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A'
    );
    Segment__c multiCitySegment1 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c multiCitySegment2 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A'
    );
    Segment__c multiCitySegment3 = new Segment__c(
      Booking__c = multiCityBooking.Id,
      Flight__c = flight3.Id,
      Seat__c = '1A'
    );
    Segment__c unknownSegment = new Segment__c(
      Booking__c = unknownBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c individualsSegment = new Segment__c(
      Booking__c = individualPassengerBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c husbandsSegment = new Segment__c(
      Booking__c = coupleBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c wifesSegment = new Segment__c(
      Booking__c = coupleBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1B'
    );
    Segment__c twoSegmentsOne = new Segment__c(
      Booking__c = oneWayBookingWithTwoSegments.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c twoSegmentsTwo = new Segment__c(
      Booking__c = oneWayBookingWithTwoSegments.Id,
      Flight__c = flight2.Id,
      Seat__c = '1A'
    );
    Segment__c duplicateBookingOneSegment = new Segment__c(
      Booking__c = duplicateBookingOne.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c duplicateBookingTwoSegment = new Segment__c(
      Booking__c = duplicateBookingTwo.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c withFileSegment = new Segment__c(
      Booking__c = withFileBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c nonEUSegment = new Segment__c(
      Booking__c = nonEUBooking.Id,
      Flight__c = nonEUFlight.Id,
      Seat__c = '1A'
    );
    Segment__c twoIrregularitiesSegment = new Segment__c(
      Booking__c = twoIrregularitiesBooking.Id,
      Flight__c = flightWithTwoIrregularities.Id,
      Seat__c = '1A'
    );
    Segment__c tooShortDelaySegment = new Segment__c(
      Booking__c = tooShortDelayBooking.Id,
      Flight__c = flightWithTooShortDelay.Id,
      Seat__c = '1A'
    );
    Segment__c tooLongDelaySegment = new Segment__c(
      Booking__c = tooLongDelayBooking.Id,
      Flight__c = flightWithTooLongDelay.Id,
      Seat__c = '1A'
    );
    Segment__c cancellationSegment = new Segment__c(
      Booking__c = cancellationBooking.Id,
      Flight__c = flightWithCancellation.Id,
      Trip_Type__c = 'Cancelled',
      Seat__c = '1A'
    );
    Segment__c missingClaimedFlightSegment = new Segment__c(
      Booking__c = missingClaimedFlightBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c claimExpensesSegment = new Segment__c(
      Booking__c = claimExpensesBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c notOperatedBySASSegment = new Segment__c(
      Booking__c = notOperatedBySASBooking.Id,
      Flight__c = nonSASFlight.Id,
      Seat__c = '1A'
    );
    Segment__c twoClaimsSameBookingReferenceSegment = new Segment__c(
      Booking__c = twoClaimsSameBookingReferenceBooking.Id,
      Flight__c = flight1.Id,
      Seat__c = '1A'
    );
    Segment__c minimalClaimSegment = new Segment__c(
      Booking__c = minimalClaimBooking.Id,
      Flight__c = flightForMinimalClaim.Id,
      Seat__c = '1A'
    );
    Segment__c rotationSegment = new Segment__c(
      Booking__c = rotationBooking.Id,
      Flight__c = flightWithRotation.Id,
      Seat__c = '1A'
    );
    Passenger__c oneWayPassenger = new Passenger__c(
      Booking__c = oneWayBooking.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Sven',
      Last_Name__c = 'Svensson'
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
      Last_Name__c = 'Birgitsdottir'
    );
    Passenger__c twoSegmentsPassenger = new Passenger__c(
      Booking__c = oneWayBookingWithTwoSegments.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Birgit',
      Last_Name__c = 'Birgitsdottir'
    );
    Passenger__c duplicateBookingOnePassenger = new Passenger__c(
      Booking__c = duplicateBookingOne.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Birgit',
      Last_Name__c = 'Birgitsdottir'
    );
    Passenger__c duplicateBookingTwoPassenger = new Passenger__c(
      Booking__c = duplicateBookingTwo.Id,
      Identifier__c = 'P1',
      First_Name__c = 'Birgit',
      Last_Name__c = 'Birgitsdottir'
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
    Passenger__c cancellationPassenger = new Passenger__c(
      Booking__c = cancellationBooking.Id,
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

    FlightIrregularities__c flight1Delay = new FlightIrregularities__c(
      Flight__c = flight1.Id,
      Duration_minutes__c = 130,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c flight3Delay = new FlightIrregularities__c(
      Flight__c = flight3.Id,
      Duration_minutes__c = 130,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c nonEUFlightDelay = new FlightIrregularities__c(
      Flight__c = nonEUFlight.Id,
      Duration_minutes__c = 130,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c tooShortFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTooShortDelay.Id,
      Duration_minutes__c = 30,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c tooLongFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTooLongDelay.Id,
      Duration_minutes__c = 400,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c twoDelaysFirstFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTwoIrregularities.Id,
      Duration_minutes__c = 120,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c twoDelaysSecondFlightDelay = new FlightIrregularities__c(
      Flight__c = flightWithTwoIrregularities.Id,
      Duration_minutes__c = 50,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c flightCancellation = new FlightIrregularities__c(
      Flight__c = flightWithCancellation.Id,
      Code__c = 'AIRS',
      Type__c = 'Cancellation (arrival)'
    );
    FlightIrregularities__c nonSASDelay = new FlightIrregularities__c(
      Flight__c = nonSASFlight.Id,
      Duration_minutes__c = 130,
      Code__c = 'AIRS',
      Type__c = 'Delay (arrival)'
    );
    FlightIrregularities__c minimalClaimDelay = new FlightIrregularities__c(
      Flight__c = flightForMinimalClaim.Id,
      Duration_minutes__c = 280,
      Code__c = 'AIRS',
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
      cancellationSegment,
      missingClaimedFlightSegment,
      claimExpensesSegment,
      notOperatedBySASSegment,
      twoClaimsSameBookingReferenceSegment,
      minimalClaimSegment,
      rotationSegment,
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
      cancellationPassenger,
      missingClaimedFlightPassenger,
      claimExpensesPassenger,
      notOperatedBySASPassenger,
      twoClaimsSameBookingReferencePassenger,
      minimalClaimPassenger,
      rotationPassenger,
      flight1Delay,
      flight3Delay,
      nonEUFlightDelay,
      tooShortFlightDelay,
      tooLongFlightDelay,
      twoDelaysFirstFlightDelay,
      twoDelaysSecondFlightDelay,
      flightCancellation,
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
      LIA_Claim__c.Country__c => 'Sweden',
      LIA_Claim__c.Liability_PNR__c => bookingReference,
      LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
        Claim.RecordType.CustomerClaim
      )
    };
    claimFields.putAll(extraClaimFields);
    return TestDataFactories.createCasesWithClaims(
      1,
      new Map<Schema.SObjectField, Object>{
        Case.Initially_Provided_PNR__c => bookingReference
      },
      claimFields
    );
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
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims dayReturnClaim = createDefaultTestClaim(
      dayReturnBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims multiCityClaim = createDefaultTestClaim(
      multiCityBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims roundTripClaim = createDefaultTestClaim(
      roundTripBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims unknownClaim = createDefaultTestClaim(
      unknownBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      if (claim.bookingType == Bookings.Type.OneWay) {
        System.assertEquals(
          true,
          claim.canBeEvaluated,
          'One way claim should be possible to evaluate.'
        );
      } else {
        System.assertEquals(
          false,
          claim.canBeEvaluated,
          'Other booking types should not be available for evaluation.'
        );
        System.assertEquals(
          'can handle only one one way trips',
          claim.unhandledReason,
          'Rejection reason should be "can handle only one one way trips"'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWithOnePassengerCanBeEvaluated() {
    TestDataFactories.CasesClaims individualClaim = createDefaultTestClaim(
      individualPassengerBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims coupleClaim = createDefaultTestClaim(
      coupleBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      if (claim.claim.instanceRecords[0].Id == individualClaim.claims[0].Id) {
        System.assertEquals(
          true,
          claim.canBeEvaluated,
          'It should be possible to evaluate a claim with a single passenger.'
        );
      } else {
        System.assertEquals(
          false,
          claim.canBeEvaluated,
          'Claims with more than one passenger cannot be evaluated.'
        );
        System.assertEquals(
          'can handle only one passenger per claim',
          claim.unhandledReason,
          'Rejection reason should be "can handle only one passenger per claim"'
        );
      }
    }
  }

  @IsTest
  static void onlyClaimsWithOneSegmentCanBeEvaluated() {
    TestDataFactories.CasesClaims claims = createDefaultTestClaim(
      oneWayBookingWithTwoSegmentsReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      if (
        claim.booking.instanceRecords[0].Booking_Reference__c ==
        oneWayBookingReference
      ) {
        System.assertEquals(
          true,
          claim.canBeEvaluated,
          'Claim with a single segment should be possible to evaluate.'
        );
      } else {
        System.assertEquals(
          false,
          claim.canBeEvaluated,
          'Claim with more than one segment cannot be evaluated.'
        );
        System.assertEquals(
          'can handle only one flight per claim',
          claim.unhandledReason,
          'Rejection reason should be "can handle only one flight per claim"'
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
        LIA_Claim__c.Flight_Number__c => 'SK1',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      if (
        claim.booking.instanceRecords[0].Booking_Reference__c ==
        oneWayBookingReference
      ) {
        System.assertEquals(
          true,
          claim.canBeEvaluated,
          'Claim with a single booking should be possible to evaluate.'
        );
      } else {
        System.assertEquals(
          false,
          claim.canBeEvaluated,
          'Claim with more than one booking cannot be evaluated.'
        );
        System.assertEquals(
          'can handle only one booking per claim',
          claim.unhandledReason,
          'Rejection reason should be "can handle only one booking per claim"'
        );
      }
    }
  }

  // THIS IS CURRENTLY BROKEN, TODO: find new way to implement this
  @IsTest
  static void onlyClaimsWithoutFilesCanBeEvaluated() {
    if (true) {
      return;
    }
    TestDataFactories.CasesClaims caseClaim = createDefaultTestClaim(
      withFileBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      caseClaim
    };

    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'PowerOfAttorney.txt',
      Title = 'PowerOfAttorney',
      VersionData = Blob.valueOf('Power!')
    );
    insert cv;
    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance()
      .selectById(new Set<Id>{ cv.Id });
    ContentDocumentLink cdl = new ContentDocumentLink(
      ContentDocumentId = contentToLink[0].ContentDocumentId,
      LinkedEntityId = caseClaim.cases[0].Id
    );
    insert cdl;

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      if (claimIds.contains(claim.claim.instanceRecords[0].Id)) {
        System.assertEquals(
          false,
          claim.canBeEvaluated,
          'It should not be possible to evaluate claims with files.'
        );
        System.assertEquals(
          'cannot handle claims with attachments (might have POA)',
          claim.unhandledReason,
          'Rejection reason should be "cannot handle claims with attachments (might have POA)"'
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
        LIA_Claim__c.Flight_Number__c => 'SK4',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      if (claimIds.contains(claim.claim.instanceRecords[0].Id)) {
        System.assertEquals(
          false,
          claim.canBeEvaluated,
          'It should not be possible to evaluate claims with files.'
        );
        System.assertEquals(
          'can only handle claims with origin and destination airports in EU',
          claim.unhandledReason,
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
        LIA_Claim__c.Flight_Number__c => 'SK1',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      false,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should not be possible to evaluate claims with expenses.'
    );
    System.assertEquals(
      'cannot handle claim expenses',
      claimsWithEvaluationDetails[0].unhandledReason,
      'Rejection reason should be "cannot handle claim expenses"'
    );
  }

  @IsTest
  static void onlyClaimsWithin2to5HoursDelayCanBeEvaluated() {
    TestDataFactories.CasesClaims claimWithTooShortDelay = createDefaultTestClaim(
      tooShortDelayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK6',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims claimWithTooLongDelay = createDefaultTestClaim(
      tooLongDelayBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK7',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    for (
      EU261Service.ClaimWithCompensationDetails claim : claimsWithEvaluationDetails
    ) {
      System.assertEquals(
        false,
        claim.canBeEvaluated,
        'It should not be possible to evaluate claims with too long or too short delay.'
      );
      System.assertEquals(
        'can handle only delays between 2 and 5 hours',
        claim.unhandledReason,
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
        LIA_Claim__c.Flight_Number__c => 'SK6',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      false,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should not be possible to evaluate claims with flight missing from booking.'
    );
    System.assertEquals(
      'cannot find claimed flight from booking',
      claimsWithEvaluationDetails[0].unhandledReason,
      'Rejection reason should be "cannot find claimed flight from booking"'
    );
  }

  @IsTest
  static void claimsWithMoreThanOneIrregularityCanBeEvaluated() {
    TestDataFactories.CasesClaims claim = createDefaultTestClaim(
      twoIrregularitiesBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK5',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      true,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should be possible to evaluate claims with more than one irregularity.'
    );
  }

  @IsTest
  static void claimsWithRotationIrregularitiesCannotBeEvaluated() {
    TestDataFactories.CasesClaims claim = createDefaultTestClaim(
      rotationBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK10',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      false,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should not be possible to evaluate claims with rotation delays.'
    );
    System.assertEquals(
      'cannot handle flights with irregularities caused by rotations',
      claimsWithEvaluationDetails[0].unhandledReason,
      'Rejection reason should be "cannot handle flights with irregularities caused by rotations"'
    );
  }

  @IsTest
  static void onlyClaimsWithoutCancellationsCanBeEvaluated() {
    TestDataFactories.CasesClaims claim = createDefaultTestClaim(
      cancellationBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK8',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      false,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should not be possible to evaluate claims with cancellations.'
    );
    System.assertEquals(
      'cannot handle claims regarding a trip that has cancellations',
      claimsWithEvaluationDetails[0].unhandledReason,
      'Rejection reason should be "cannot handle claims regarding a trip that has cancellations"'
    );
  }

  @IsTest
  static void onlyClaimsWithFlightsOperatedBySASCanBeEvaluated() {
    TestDataFactories.CasesClaims claim = createDefaultTestClaim(
      notOperatedBySASBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'LH1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-18')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      false,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should not be possible to evaluate claims with flights not operated by SAS.'
    );
    System.assertEquals(
      'cannot handle claims where SAS is not the only operating carrier',
      claimsWithEvaluationDetails[0].unhandledReason,
      'Rejection reason should be "cannot handle claims where SAS is not the only operating carrier"'
    );
  }

  @IsTest
  static void onlyClaimsWithoutDuplicatesCanBeEvaluated() {
    TestDataFactories.CasesClaims existingClaim = createDefaultTestClaim(
      twoClaimsSameBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );
    TestDataFactories.CasesClaims claimBeingProcessed = createDefaultTestClaim(
      twoClaimsSameBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK1',
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
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    System.assertEquals(
      false,
      claimsWithEvaluationDetails[0].canBeEvaluated,
      'It should not be possible to evaluate claims with flights not operated by SAS.'
    );
    System.assertEquals(
      'cannot handle potential duplicates',
      claimsWithEvaluationDetails[0].unhandledReason,
      'Rejection reason should be "cannot handle potential duplicates"'
    );
  }

  @IsTest
  static void minimalClaimShouldBeEvaluatedCorrectly() {
    TestDataFactories.CasesClaims claim = createDefaultTestClaim(
      minimalClaimBookingReference,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
        LIA_Claim__c.Flight_Number__c => 'SK9',
        LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17')
      }
    );

    List<TestDataFactories.CasesClaims> casesClaims = new List<TestDataFactories.CasesClaims>{
      claim
    };

    createCaseToBookings(casesClaims); // TODO: This should be done by claim insertion already.

    Set<Id> claimIds = getClaimIds(casesClaims);

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<EU261Service.ClaimWithCompensationDetails> claimsWithEvaluationDetails = EU261Service.newInstance()
      .automateEU261Claims(claimIds, uow);
    Test.stopTest();

    LIA_Claim__c automatedClaim = claimsWithEvaluationDetails[0]
      .claim.instanceRecords[0];

    System.assertEquals(
      'Eligible for compensation',
      automatedClaim.EU261_Handling_Status__c,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      'Compensation: 400 | Reimbursement: 0',
      automatedClaim.EU261_Handling_Note__c,
      'Handling Note should be "Compensation: 400 | Reimbursement: 0"'
    );
  }
}
