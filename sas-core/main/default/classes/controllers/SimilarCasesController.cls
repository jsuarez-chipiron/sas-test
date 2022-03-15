public without sharing class SimilarCasesController {
  private static CasesSelector cases = CasesSelector.newInstance();
  private static ClaimsSelector claims = ClaimsSelector.newInstance();

  @AuraEnabled(cacheable=true)
  public static List<Case> getSimilarCasesForCase(String caseId) {
    return cases.selectSimilarCasesById(caseId);
  }
}
