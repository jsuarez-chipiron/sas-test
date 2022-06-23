public without sharing class ProactivitiesController {
  public class Proactivity {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String note;
    @AuraEnabled
    public String matchingReasons;
    @AuraEnabled
    public String type;

    Proactivity(Proactivity__c proactivity, LIA_Claim__c claim, String reason) {
      this.id = proactivity.Id;
      this.note = proactivity.Note__c;
      this.type = proactivity.Type__c;
      this.matchingReasons = reason;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Proactivity> getProactivitiesForRecord(
    String recordId,
    String objectApiName // Case or Settlement__c
  ) {
    String caseId = recordId;
    if (objectApiName == 'Settlement__c') {
      caseId = SettlementsSelector.newInstance()
          .selectByIdWithClaimFields(new Set<Id>{ recordId })[0]
        .Claim__r.Case__c;
    }

    ProactivitiesSelector proactivities = ProactivitiesSelector.newInstance();
    List<Proactivity> proactivitiesWithMatchingReason = new List<Proactivity>();
    Map<Proactivity__c, String> proactivityToReason = proactivities.selectByCaseIdWithMatchingReasons(
      caseId
    ); //
    List<Proactivity__c> proactivitiesFound = new List<Proactivity__c>(
      proactivityToReason.keySet()
    );

    if (proactivitiesFound.size() > 0) {
      ClaimsSelector claims = ClaimsSelector.newInstance();

      LIA_Claim__c claim = claims.selectByCaseIdWithCustomers(
        new Set<Id>{ caseId }
      )[0];

      for (Proactivity__c p : proactivitiesFound) {
        String reasons = proactivityToReason.get(p);
        proactivitiesWithMatchingReason.add(new Proactivity(p, claim, reasons));
      }
    }

    return proactivitiesWithMatchingReason;
  }

  @AuraEnabled(cacheable=true)
  public static List<Case> getCasesForProactivity(String proactivityId) {
    CasesSelector cases = CasesSelector.newInstance();

    return cases.selectByProactivityId(proactivityId);
  }
}
