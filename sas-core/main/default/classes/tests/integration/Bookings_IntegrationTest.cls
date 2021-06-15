@IsTest
public with sharing class Bookings_IntegrationTest {
  public static String bookingReferenceInDB = 'SF1234';
  public static String bookingReferenceOnlyInTEDS = 'TEDS12';
  public static String invalidBookingReference = 'AAAAAA';
  public static String ebNumberWithBookings = 'TEST123456';
  public static String ebNumberWithoutBookings = 'TEST654321';

  public static List<Booking__c> bookingsInDB = new List<Booking__c>();

  public static BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );

  @TestSetup
  static void setup() {
    bookingsInDB = TestDataFactories.createBookings(1, bookingReferenceInDB);
    C_Settings.SETTINGS_OVERRIDE = new C_GeneralSetting__mdt[]{
        new C_GeneralSetting__mdt(MasterLabel='APIM_Subscription_Key',Value__c='TESTKEY',Group__c='APIM')
    };
  }

  @IsTest
  public static void itsPossibleToAddBookingInDBToCase() {
    // Given
    Case testCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    )[0];

    Test.startTest();
    insert testCase;

    // When
    CustomerCardController.addBookingToCase(testCase.Id, bookingReferenceInDB);
    Test.stopTest();

    // Then
    Booking__c bookingFromDB = bookings.selectByCaseId(
      new Set<Id>{ testCase.Id }
    )[0];

    System.assertEquals(
      bookingReferenceInDB,
      bookingFromDB.Booking_Reference__c,
      'Booking should be found by case Id'
    );
  }

  @IsTest
  public static void itsPossibleToAddBookingInTEDSToCase() {
    // Given
    Case testCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    )[0];

    insert testCase;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingSingleSuccessMock());
    // When
    CustomerCardController.addBookingToCase(
      testCase.Id,
      bookingReferenceOnlyInTEDS
    );
    Test.stopTest();

    // Then
    Booking__c bookingFromDB = bookings.selectByCaseId(
      new Set<Id>{ testCase.Id }
    )[0];

    System.assertEquals(
      bookingReferenceOnlyInTEDS,
      bookingFromDB.Booking_Reference__c,
      'Booking should be found by case Id and have the same reference'
    );
  }

  @IsTest
  public static void invalidBookingReferenceFailsGracefully() {
    // Given
    Case testCase = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      null,
      null
    )[0];

    insert testCase;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingSingle404Mock());

    // When
    CustomerCardController.addBookingToCase(
      testCase.Id,
      invalidBookingReference
    );
    Test.stopTest();

    // Then
    List<Booking__c> bookingsFromDB = bookings.selectByCaseId(
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
    testAccount.FCS_EBNumber__c = ebNumberWithBookings;
    insert testAccount;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingQuerySuccessMock());
    // When
    CustomerCardController.getBookingsForEBCustomer(ebNumberWithBookings);
    Test.stopTest();

    // Then
    Booking__c bookingFromDB = bookings.selectByAccountId(
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
    testAccount.FCS_EBNumber__c = ebNumberWithoutBookings;
    insert testAccount;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingQueryNFMock());
    // When
    List<Booking__c> bookingsFromCustomerCard = CustomerCardController.getBookingsForEBCustomer(
      ebNumberWithoutBookings
    );
    Test.stopTest();

    // Then
    List<Booking__c> bookingsFromDB = bookings.selectByAccountId(
      new Set<Id>{ testAccount.Id }
    );

    System.assert(
      bookingsFromCustomerCard.size() == 0,
      'No bookings should be return by the controller.'
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
    testAccount.FCS_EBNumber__c = ebNumberWithBookings;
    insert testAccount;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new TEDSBookingQuerySuccessMock());
    // When
    CustomerCardController.getBookingsForEBCustomer(ebNumberWithBookings);
    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingQuerySuccessAnotherMock()
    );
    CustomerCardController.getBookingsForEBCustomer(ebNumberWithBookings);
    Test.stopTest();

    // Then
    List<Booking__c> bookingsForAccount = bookings.selectByAccountId(
      new Set<Id>{ testAccount.Id }
    );

    System.assert(
      bookingsForAccount.size() == 1,
      'There should be only one booking for the account.'
    );

    System.assert(
      bookingsForAccount[0].Is_Cancelled__c == true,
      'Booking should have been updated changed between the calls.'
    );
  }
}
