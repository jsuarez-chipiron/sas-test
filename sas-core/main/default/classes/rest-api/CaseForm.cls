@RestResource(urlMapping='/CaseForm/*')
global with sharing class CaseForm {
  @HttpPost
  global static CaseFormResponse createCase(CaseFormJSON2Apex form) {
    try {
      if (form.formData.type == 'claim') {
        return new CaseFormResponse(ClaimService.createClaim(form));
      } else {
        return new CaseFormResponse(CaseService.createCase(form));
      }
    } catch (Exception e) {
      C_Log.logException(e, 'CaseFormAPI', null);
      throw e;
    }
  }
}
