public without sharing class Accounts extends fflib_SObjectDomain {
  public Accounts(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Accounts(records);
    }
  }

  public override void onAfterInsert() {
    if (Records.size() == 1) {
      fetchBookingsFromTEDS();
      fetchTravelPassAccount();
    }
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    if (Records.size() == 1) {
      // If we're updating just one account, refetch bookings if the eb number has changed
      Boolean ebNumberHasChanged =
        existingRecords.size() == 1 &&
        ((Account) existingRecords.values()[0]).FCS_EBNumber__c !=
        ((Account) Records[0]).FCS_EBNumber__c;

      if (ebNumberHasChanged) {
        fetchBookingsFromTEDS();
      }
    }
  }

  private void fetchBookingsFromTEDS() {
    Account acc = (Account) Records[0];
    if (
      acc.FCS_EBNumber__c != null &&
      !System.isFuture() &&
      !System.isBatch() &&
      !System.isQueueable()
    ) {
      // Guard against nesting futures. FIXME: update logic so that this isn't needed
      BookingService.fetchBookingsByEBNumber(acc.FCS_EBNumber__c);
    }
  }

  private void fetchTravelPassAccount() {
    Account acc = (Account) Records[0];
    if (
      acc.FCS_TPAccountNumber__c != null &&
      acc.FCS_CMP__c != null &&
      !System.isFuture() &&
      !System.isBatch() &&
      !System.isQueueable()
    ) {
      // Guard against nesting futures. FIXME: update logic so that this isn't needed
      TravelPassService.fetchTravelPassAccount(
        acc.FCS_TPAccountNumber__c,
        acc.Id
      );
    }
  }
}
