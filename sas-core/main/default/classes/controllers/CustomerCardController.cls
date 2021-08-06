public without sharing class CustomerCardController {
  static AccountsSelector accounts = (AccountsSelector) SAS_Service_Application.Selector.newInstance(
    Account.SObjectType
  );
  static BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );
  static CasesSelector cases = (CasesSelector) SAS_Service_Application.Selector.newInstance(
    Case.SObjectType
  );
  @AuraEnabled
  public static List<Booking__c> addBookingToCase(
    ID caseId,
    String bookingReference
  ) {
    BookingService.addBookingToCase(caseId, bookingReference);

    return bookings.selectByBookingReference(bookingReference);
    // TODO: This probably can't return anything
  }

  @AuraEnabled
  public static List<Booking__c> getBookingsForEBCustomer(
    String euroBonusNumber
  ) {
    BookingService.fetchBookingsByEBNumber(euroBonusNumber);

    Account acc = accounts.selectByEuroBonusNumber(
      new Set<String>{ euroBonusNumber }
    )[0];
    return bookings.selectByAccountId(new Set<Id>{ acc.Id });
    // TODO: This probably can't return anything
  }

  @AuraEnabled(cacheable=true)
  public static List<Account> getAccountData(String accountId) {
    return accounts.selectById(new Set<Id>{ accountId });
  }

  @AuraEnabled(cacheable=true)
  public static List<BookingJSON> getBookingData(String accountId) {
    List<Booking__c> bookingsForCustomer = bookings.selectByAccountId(
      new Set<Id>{ accountId }
    );
    List<BookingJSON> toReturn = new List<BookingJSON>();
    for (Booking__c b : bookingsForCustomer) {
      toReturn.add(new BookingJSON(b));
    }
    toReturn.sort();

    return toReturn;
  }

  @AuraEnabled(cacheable=true)
  public static List<Case> getCaseData(String accountId) {
    return cases.selectByAccountId(new Set<Id>{ accountId });
  }      
    @AuraEnabled(cacheable=true)
  public static  List<IRR_CommunicationLog__c> getAllCommunicationData(String accountId)
  {         
             return IRR_SEL_CommunicationLogsSelector.newInstance()
               .getCommunicationMessagesbyEBAccount(new Set<String> { accountId });
              }    
          
          
}