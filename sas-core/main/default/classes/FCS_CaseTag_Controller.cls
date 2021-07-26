public class FCS_CaseTag_Controller {
  static CaseTagsSelector caseTags = (CaseTagsSelector) SAS_Service_Application.Selector.newInstance(
    FCS_CaseTag__c.SObjectType
  );
  static CasesSelector cases = (CasesSelector) SAS_Service_Application.Selector.newInstance(
    Case.SObjectType
  );
  public static Case cse { get; set; }
  public FCS_CaseTag_Controller() {
  }
  @AuraEnabled(cacheable=true)
  public static Case findCase(string recordId) {
    List<Case> lstCases = cases.selectByChatId(new Set<Id>{ recordId });
    return lstCases[0];
  }
  @AuraEnabled(cacheable=true)
  public static FCS_CaseTag__c findCaseTag(String recordId) {
    List<FCS_CaseTag__c> lstcaseTags;
    Id ObjectId = Id.valueOf(recordId);
    String sobjectName = ObjectId.getSObjectType().getDescribe().getName();
    if (sobjectName == 'Case') {
      lstcaseTags = caseTags.selectByCaseId(new Set<Id>{ recordId });
    } else if (sobjectName == 'LiveChatTranscript') {
      lstcaseTags = caseTags.selectByChatId(new Set<Id>{ recordId });
    }

    System.debug(lstcaseTags);
    if (lstcaseTags.size() > 0)
      return lstcaseTags[0];
    else
      return null;
  }
}
