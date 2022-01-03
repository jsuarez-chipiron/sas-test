@IsTest
public with sharing class Accounts_IntegrationTest {
  public static String bookingReference = 'SF1234';
  public static String euroBonusNumber = '123456789098';

  public static BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );

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

  @IsTest
  public static void insertingAnAccountShouldFetchTPProducts() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Account newAccount = new Account(
      FCS_TPAccountNumber__c = 'TEST12',
      FCS_CMP__c = 'TEST12',
      RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
      FirstName = 'Test',
      LastName = 'Account'
    );
    insert newAccount;
    Test.stopTest();

    List<Travel_Pass_Product__c> associatedTPProducts = [
      SELECT Id, Account__c
      FROM Travel_Pass_Product__c
      WHERE Account__c = :newAccount.Id
    ];

    System.assert(
      associatedTPProducts.size() == 2,
      'There should be two TP products associated with the account as the mock response contains two products.'
    );
  }
}
