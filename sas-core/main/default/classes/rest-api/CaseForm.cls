@RestResource(urlMapping='/CaseForm/*')
global with sharing class CaseForm {
  @HttpPost
  global static void createCase(CaseFormJSON2Apex form) {
    try {
      CaseService.createCase(form);
    } catch (Exception e) {
      C_Log.logException(e, 'CaseFormAPI', null);
      throw e;
    }
  }
}
