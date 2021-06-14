public without sharing class CustomerCardController {
  static AccountsSelector accounts = (AccountsSelector) SAS_Service_Application.Selector.newInstance(
    Account.SObjectType
  );
  static BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
    Booking__c.SObjectType
  );

  @AuraEnabled
  public static List<Booking__c> addBookingToCase(
    ID caseId,
    String bookingReference
  ) {
    BookingService.addBookingToCase(caseId, bookingReference);

    return bookings.selectByBookingReference(bookingReference);
    // TODO: Handle errors
    // TODO: This probably can't return anything
    /*
      try {
        BookingService.addBookingToCase(caseId, bookingReference);
      }
      catch (Exception e) {
        Application.throwAuraHandledException(e);
      }
    */
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
  public static Booking__c getBooking(String bookingId) {
    return bookings.selectByBookingReference('VKQLKR')[0];
  }

  @AuraEnabled(cacheable=true)
  public static List<Account> getFullAccountDataForEBNumber(String euroBonusNumber) {
    return accounts.selectByEuroBonusNumberFull(new Set<String>{ euroBonusNumber });
  }
}

/*
  TODO: Error handler
  public static void throwAuraHandledException(Exception e) {
      String message = e.getMessage();
      AuraHandledException error = 
        new AuraHandledException(message);
      error.setMessage(message); 
      throw error;
  }
*/

