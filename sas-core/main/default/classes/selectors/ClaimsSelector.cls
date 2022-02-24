public inherited sharing class ClaimsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      LIA_Claim__c.Id,
      LIA_Claim__c.Claims_Exist_In_CARE_For_PNR__c,
      LIA_Claim__c.Last_Checked_Claims_From_CARE__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return LIA_Claim__c.SObjectType;
  }

  public static ClaimsSelector newInstance() {
    return (ClaimsSelector) SAS_Service_Application.Selector.newInstance(
      LIA_Claim__c.SObjectType
    );
  }

  public List<LIA_Claim__c> selectById(Set<Id> ids) {
    return (List<LIA_Claim__c>) selectSObjectsById(ids);
  }
}
