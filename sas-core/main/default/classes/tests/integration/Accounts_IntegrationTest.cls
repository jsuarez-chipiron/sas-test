@IsTest
public with sharing class Accounts_IntegrationTest {
  public static String bookingReference = 'SF1234';
  public static String euroBonusNumber = '123456789098';

  public static BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );
  public static PassengersSelector passengers = (PassengersSelector) SAS_Service_Application.Selector.newInstance(
    Passenger__c.SObjectType
  );

  @IsTest
  public static void whenEBAccountIsCreatedItIsAssociatedWithPassengers() {
    // Given
    Booking__c booking = TestDataFactories.createBookings(
      1,
      bookingReference
    )[0];
    Booking__c bookingFromDB = bookings.selectByBookingReference(
      bookingReference
    )[0];
    Passenger__c existingPassenger = bookingFromDB.Passengers__r[0];
    existingPassenger.EuroBonus_Number__c = euroBonusNumber;

    Test.startTest();
    update existingPassenger;

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    // When
    Account newAccount = new Account(
      FCS_EBNumber__c = euroBonusNumber,
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      FirstName = 'Test',
      LastName = 'Account'
    );
    insert newAccount;

    // Then
    Passenger__c updatedPassenger = (Passenger__c) SAS_Service_Application.Selector.selectById(
      new Set<Id>{ existingPassenger.Id }
    )[0];
    System.assertEquals(
      newAccount.Id,
      updatedPassenger.Account__c,
      'Passenger with same EB number should be associated with the new account'
    );
    Test.stopTest();
  }

  @IsTest
  public static void whenEBAccountIsCreatedBookingsAreCreated() {
    // Given
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    TEDSIntegrationService mockTEDSService = (TEDSIntegrationService) mocks.mock(
      TEDSIntegrationService.class
    );
    mocks.startStubbing();
    List<List<String>> query = new List<List<String>>{
      new List<String>{ 'euroBonusNumber', euroBonusNumber }
    };
    mocks.when(mockTEDSService.fetchBookingsByQuery(query))
      .thenReturn(
        TestDataFactories.createParsedBookingData(
          bookingReference,
          euroBonusNumber
        )
      );
    mocks.stopStubbing();
    SAS_Service_Application.Service.setMock(
      TEDSIntegrationService.class,
      mockTEDSService
    );

    Test.startTest();
    // When
    Account newAccount = new Account(
      FCS_EBNumber__c = euroBonusNumber,
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      FirstName = 'Test',
      LastName = 'Account'
    );
    insert newAccount;
    Test.stopTest();

    // Then
    List<Booking__c> bookingsFromDB = bookings.selectByAccountId(
      new Set<Id>{ newAccount.Id }
    );
    System.assert(
      bookingsFromDB.size() > 0,
      'There should be a new booking related to the account'
    );
  }
}
