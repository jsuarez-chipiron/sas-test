public with sharing class Accounts extends fflib_SObjectDomain {
  public Accounts(List<SObject> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Accounts(records);
    }
  }

  public override void onAfterInsert() {
    associateWithPassengers();

    if (Records.size() == 1) {
      fetchBookingsFromTEDS();
    }
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    associateWithPassengers();
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

  private void associateWithPassengers() {
    Set<String> euroBonusNumbers = new Set<String>();

    for (Account acc : (List<Account>) Records) {
      if (acc.IsPersonAccount && (acc.FCS_EBNumber__c != null)) {
        euroBonusNumbers.add(acc.FCS_EBNumber__c);
      }
    }

    PassengersSelector passengersSel = (PassengersSelector) SAS_Service_Application.Selector.newInstance(
      Passenger__c.SObjectType
    );

    ((Passengers) SAS_Service_Application.Domain.newInstance(
        passengersSel.selectByEuroBonusNumber(euroBonusNumbers)
      ))
      .associateWithExistingEBAccounts();
  }

  private void fetchBookingsFromTEDS() {
    Account acc = (Account) Records[0];
    if (acc.FCS_EBNumber__c != null) {
      BookingService.fetchBookingsByEBNumber(acc.FCS_EBNumber__c);
    }
  }
}
