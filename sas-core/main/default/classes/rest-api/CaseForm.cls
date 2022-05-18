@RestResource(urlMapping='/CaseForm/*')
global with sharing class CaseForm {
  public class APIException extends Exception {
  }

  @HttpPost
  global static CaseFormResponse createCase(CaseFormJSON2Apex form) {
    try {
      switch on form.formData.type {
        when 'claim' {
          return new CaseFormResponse(ClaimService.createClaim(form));
        }
        when 'compensation-card' {
          return new CaseFormResponse('1234567890');
          /*return new CaseFormResponse(
            ClaimService.createCompensationCardClaim(form)
          );*/
        }
        when else {
          return new CaseFormResponse(CaseService.createCase(form));
        }
      }
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'CaseFormAPI',
        null
      );
      throw new APIException();
    }
  }
}
