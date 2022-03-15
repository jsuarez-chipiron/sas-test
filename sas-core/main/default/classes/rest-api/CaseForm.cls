@RestResource(urlMapping='/CaseForm/*')
global with sharing class CaseForm {
  @HttpPost
  global static String createCase(CaseFormJSON2Apex form) {
    try {
      if (form.formData.type == 'claim') {
        return ClaimService.createClaim(form);
      } else {
        return CaseService.createCase(form);
      }
    } catch (Exception e) {
      C_Log.logException(e, 'CaseFormAPI', null);
      throw e;
    }
  }
}
