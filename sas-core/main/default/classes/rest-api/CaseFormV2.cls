@RestResource(urlMapping='/CaseFormV2/*')
global with sharing class CaseFormV2 {
  public class APIException extends Exception {
  }
  public class ValidationException extends Exception {
  }

  @HttpPost
  global static CaseFormResponse createCase(CaseFormJSONV2 form) {
    try {
      switch on form.formData.type {
        when 'claim' {
          CreateClaimRequest validatedRequest = null;
          try {
            validatedRequest = new CreateClaimRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }
          return new CaseFormResponse(
            ClaimService.createClaim(validatedRequest)
          );
        }
        when 'denied-boarding' {
          CreateClaimRequest validatedRequest = null;
          try {
            validatedRequest = new CreateClaimRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }
          return new CaseFormResponse(
            ClaimService.createCompensationCardClaim(validatedRequest)
          );
        }
        when else {
          return new CaseFormResponse('1');
          /*TODO: Implement
           return new CaseFormResponse(CaseService.createCase(form));*/
        }
      }
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'CaseFormV2API',
        null
      );
      throw new APIException();
    }
  }
}
