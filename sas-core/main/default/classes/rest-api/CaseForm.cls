@RestResource(urlMapping='/CaseForm/*')
global with sharing class CaseForm {
  @HttpPost
  global static String CaseForm(CaseFormJSON2Apex form) {
    return CaseService.createCaseForm(form);
  }
}
