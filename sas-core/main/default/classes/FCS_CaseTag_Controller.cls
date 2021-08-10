public class FCS_CaseTag_Controller {
  static CasesSelector cases = (CasesSelector) SAS_Service_Application.Selector.newInstance(
    Case.SObjectType
  );
  public FCS_CaseTag_Controller() {
  }
  @AuraEnabled(cacheable=true)
  public static Case findCase(string recordId) {
    List<Case> lstCases = cases.selectByChatId(new Set<Id>{ recordId });
    return lstCases[0];
  }
}