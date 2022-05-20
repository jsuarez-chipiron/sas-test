public without sharing class ValidateSettlements {
  /*
   * Checks if the settlement(s) are valid and ready to be submitted to approval.
   * If it is not valid it throws an error with a message of what has to be corrected.
   * @param settlementsToValidate a list with a list of settlements to be validated.
   */
  @InvocableMethod(label='Validate Settlements')
  public static void validate(List<List<Settlement__c>> settlementsToValidate) {
    Map<Id, Settlement__c> idsToSe = new Map<Id, Settlement__c>(
      settlementsToValidate[0]
    );
    Set<Id> keys = idsToSe.keySet();
    (new Settlements(SettlementsSelector.newInstance().selectById(keys)))
      .validate();
  }
}
