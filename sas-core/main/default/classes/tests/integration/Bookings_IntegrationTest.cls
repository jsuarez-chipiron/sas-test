@IsTest
public with sharing class Bookings_IntegrationTest {
  public static String bookingReferenceOnlyInTEDS = 'TEDS12';

  public static BookingsSelector bookingsSel = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );

  @IsTest
  public static void itsPossibleToAddBookingInTEDSToCase() {
    // Given
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];

    insert testCase;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When
    CustomerCardController.addBookingToCase(
      testCase.Id,
      bookingReferenceOnlyInTEDS
    );
    Test.stopTest();

    // Then
    Booking__c bookingFromDB = bookingsSel.selectByCaseId(
      new Set<Id>{ testCase.Id }
    )[0];

    System.assertEquals(
      bookingReferenceOnlyInTEDS,
      bookingFromDB.Booking_Reference__c,
      'Booking should be found by case Id and have the same reference'
    );
  }

  @IsTest
  public static void itsPossibleToRemoveABookingFromCase() {
    // Given
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];

    insert testCase;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    CustomerCardController.addBookingToCase(
      testCase.Id,
      bookingReferenceOnlyInTEDS
    );
    CustomerCardController.removeBookingFromCase(
      testCase.Id,
      bookingReferenceOnlyInTEDS
    );
    Test.stopTest();

    // Then
    List<Booking__c> bookingsByCaseId = bookingsSel.selectByCaseId(
      new Set<Id>{ testCase.Id }
    );

    System.assertEquals(
      bookingsByCaseId.size(),
      0,
      'Booking should not be found by case Id'
    );
  }

  @IsTest
  public static void invalidBookingReferenceFailsGracefully() {
    // Given
    Case testCase = FCS_TestDataFactory.createCases(1, null, null, null)[0];

    insert testCase;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    CustomerCardController.addBookingToCase(
      testCase.Id,
      APIMMock.INVALID_BOOKING_REFERENCE
    );
    Test.stopTest();

    // Then
    List<Booking__c> bookingsFromDB = bookingsSel.selectByCaseId(
      new Set<Id>{ testCase.Id }
    );

    System.assert(
      bookingsFromDB.size() == 0,
      'No bookings should exist for the case'
    );
  }

  @IsTest
  public static void itsPossibleToFetchBookingsByEBNumber() {
    // Given
    Account testAccount = FCS_TestDataFactory.createFrequentFlyers(1)[0];
    testAccount.FCS_EBNumber__c = APIMMock.EB_NUMBER_WITH_BOOKINGS;
    insert testAccount;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When
    BookingService.fetchBookingsByEBNumber(APIMMock.EB_NUMBER_WITH_BOOKINGS);
    Test.stopTest();

    // Then
    Booking__c bookingFromDB = bookingsSel.selectByAccountId(
      new Set<Id>{ testAccount.Id }
    )[0];

    System.assertEquals(
      testAccount.Id,
      bookingFromDB.Passengers__r[0].Account__c,
      'There should be a new passenger record linking the booking and account.'
    );
  }

  @IsTest
  public static void noBookingsForEBNumberFailsGracefully() {
    // Given
    Account testAccount = FCS_TestDataFactory.createFrequentFlyers(1)[0];
    testAccount.FCS_EBNumber__c = APIMMock.EB_NUMBER_WITHOUT_BOOKINGS;
    insert testAccount;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When
    BookingService.fetchBookingsByEBNumber(APIMMock.EB_NUMBER_WITHOUT_BOOKINGS);
    Test.stopTest();

    // Then
    List<Booking__c> bookingsFromDB = bookingsSel.selectByAccountId(
      new Set<Id>{ testAccount.Id }
    );

    System.assert(
      bookingsFromDB.size() == 0,
      'No bookings should be found in the DB for EB number.'
    );
  }

  @IsTest
  public static void itsPossibleToUpdateExistingBookings() {
    // Given
    Account testAccount = FCS_TestDataFactory.createFrequentFlyers(1)[0];
    testAccount.FCS_EBNumber__c = APIMMock.EB_NUMBER_WITH_BOOKINGS;
    insert testAccount;

    Booking__c existingBooking = TestDataFactories.createBookings(
      1,
      APIMMock.DEFAULT_VALID_TEDS_PNR
    )[0];
    existingBooking.TEDS_Identifier__c = APIMMock.DEFAULT_VALID_TEDS_IDENTIFIER;
    update existingBooking;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    DateTime bookingLastModifiedBeforeFetch = [
      SELECT LastModifiedDate
      FROM Booking__c
      WHERE Id = :existingBooking.Id
    ][0]
    .LastModifiedDate;

    // When
    Test.startTest();
    BookingService.fetchBookingByBookingIdentifier(
      APIMMock.DEFAULT_VALID_TEDS_IDENTIFIER
    );
    Test.stopTest();

    // Then
    List<Booking__c> bookingsForAccount = bookingsSel.selectByAccountId(
      new Set<Id>{ testAccount.Id }
    );

    System.assert(
      bookingsForAccount.size() == 1,
      'There should be only one booking for the account.'
    );
  }
  @IsTest
  public static void canInsertSingleEDWBooking() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    List<Reservation> edwb = BookingService.fetchEDWBookingByBookingReference(
        APIMMock.EDW_SINGLE_PNR
      )
      .reservations;
    Test.stopTest();
    System.assert(edwb.size() != 0, 'Booking should have been created');
    EDWReservation edwBooking = (EDWReservation) edwb[0];
    System.assert(
      edwBooking.booking != null,
      '1 Booking should have been created'
    );
    System.assert(
      edwBooking.flights.values().size() == 3,
      '3 Flights should have been created'
    );
    List<FlightIrregularity> allIrregularities = new List<FlightIrregularity>();
    for (Flight f : edwBooking.flights.values()) {
      if (f.irregularities != null) {
        allIrregularities.addAll(f.irregularities);
      }
    }
    System.assert(
      allIrregularities.size() == 2,
      '3 Flight Irregularities should have been created'
    );
    List<SegmentEvent> allSegmentEvents = new List<SegmentEvent>();
    for (Segment s : edwBooking.booking.segments) {
      if (s.getEvents() != null) {
        allSegmentEvents.addAll(s.getEvents());
      }
    }

    System.assert(
      edwBooking.booking.segments.size() == 15,
      '15 Segments should have been created'
    );
    System.assertEquals(
      55,
      allSegmentEvents.size(),
      '55 Segment Events should have been created'
    );
    System.assert(
      edwBooking.booking.passengers.size() == 5,
      '5 Passengers should have been created'
    );
  }
  @IsTest
  public static void itIsPossibleToUpdateEDWBooking() {
    Booking__c existingBooking = TestDataFactories.createBookings(
      1,
      APIMMock.EDW_SINGLE_PNR
    )[0];
    existingBooking.TEDS_Identifier__c = APIMMock.EDW_IDENTIFIER;
    update existingBooking;

    DateTime bookingLastModifiedBeforeFetch = [
      SELECT LastModifiedDate
      FROM Booking__c
      WHERE Id = :existingBooking.Id
    ][0]
    .LastModifiedDate;
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    BookingService.fetchEDWBookingByBookingReference(APIMMock.EDW_SINGLE_PNR);
    Test.stopTest();
    DateTime bookingLastModifiedAfterFetch = [
      SELECT LastModifiedDate
      FROM Booking__c
      WHERE Id = :existingBooking.Id
    ][0]
    .LastModifiedDate;

    System.assert(
      bookingLastModifiedBeforeFetch < bookingLastModifiedAfterFetch,
      'Booking should have been updated'
    );
  }
}
