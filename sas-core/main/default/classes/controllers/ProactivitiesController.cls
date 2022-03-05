public without sharing class ProactivitiesController {
  private static ProactivitiesSelector proactivities = ProactivitiesSelector.newInstance();
  private static CasesSelector cases = CasesSelector.newInstance();
  private static ClaimsSelector claims = ClaimsSelector.newInstance();

  public class Proactivity {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String note;
    @AuraEnabled
    public String matchingReasons;

    Proactivity(Proactivity__c proactivity, LIA_Claim__c claim) {
      this.id = proactivity.Id;
      this.note = proactivity.Note__c;
      String reason = '';
      Boolean reasonIsBlank = true;

      String flightId = claim.Flight_Number__c != null &&
        claim.Flight_Date__c != null
        ? claim.Flight_Number__c + '-' + String.valueOf(claim.Flight_Date__c)
        : null;

      List<String> passengerNames = null;
      if (claim.Customers__r != null) {
        passengerNames = new List<String>();
        for (Customer__c customer : claim.Customers__r) {
          if (customer.Name != null) {
            passengerNames.add(customer.Name);
          }
        }
      }

      if (
        !String.isBlank(proactivity.Bank_Account_Number__c) &&
        proactivity.Bank_Account_Number__c == claim.Bank_Account_Number__c
      ) {
        reason += reasonIsBlank ? 'Bank' : ', Bank';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.Booking_Reference__c) &&
        proactivity.Booking_Reference__c == claim.Liability_PNR__c
      ) {
        reason += reasonIsBlank ? 'PNR' : ', PNR';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.Email__c) &&
        proactivity.Email__c == claim.Contact_Email__c
      ) {
        reason += reasonIsBlank ? 'Email' : ', Email';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.EuroBonus_Number__c) &&
        proactivity.EuroBonus_Number__c == claim.EuroBonus_Number__c
      ) {
        reason += reasonIsBlank ? 'EB' : ', EB';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.Flight_Id__c) &&
        proactivity.Flight_Id__c == flightId
      ) {
        reason += reasonIsBlank ? 'Flight' : ', Flight';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.Passenger_Name__c) &&
        passengerNames.contains(proactivity.Passenger_Name__c)
      ) {
        reason += reasonIsBlank ? 'Name' : ', Name';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.Phone_Number__c) &&
        proactivity.Phone_Number__c == claim.Phone_Number__c
      ) {
        reason += reasonIsBlank ? 'Phone' : ', Phone';
        reasonIsBlank = false;
      }
      if (
        !String.isBlank(proactivity.PIR__c) &&
        proactivity.PIR__c == claim.PIR__c
      ) {
        reason += reasonIsBlank ? 'PIR' : ', PIR';
        reasonIsBlank = false;
      }
      this.matchingReasons = reason;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Proactivity> getProactivitiesForCase(String caseId) {
    List<Proactivity> proactivitiesWithMatchingReason = new List<Proactivity>();

    List<Proactivity__c> proactivitiesFound = proactivities.selectByCaseId(
      caseId
    );
    if (proactivitiesFound.size() > 0) {
      LIA_Claim__c claim = claims.selectByCaseIdWithCustomers(
        new Set<Id>{ caseId }
      )[0];

      for (Proactivity__c p : proactivitiesFound) {
        proactivitiesWithMatchingReason.add(new Proactivity(p, claim));
      }
    }

    return proactivitiesWithMatchingReason;
  }

  @AuraEnabled(cacheable=true)
  public static List<Case> getCasesForProactivity(String proactivityId) {
    return cases.selectByProactivityId(proactivityId);
  }
}
