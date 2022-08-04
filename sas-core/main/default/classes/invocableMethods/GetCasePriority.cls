public without sharing class GetCasePriority {
  /*
   * Currently only supports a single claim.
   * Todo: Make batchable. Refactor when the routing logic is rewamped.
   */
  @InvocableMethod(label='Get Case Priority')
  public static List<String> getPriority(List<LIA_Claim__c> claimsToCheck) {
    return new List<String>{
      Claims.priorityToName.get(
        Claims.newInstance(claimsToCheck).getPriority()[0]
      )
    };
  }
}
