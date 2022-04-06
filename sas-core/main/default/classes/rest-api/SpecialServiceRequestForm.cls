@RestResource(urlMapping='/SpecialServiceForm/*')
global with sharing class SpecialServiceRequestForm {
  public class APIException extends Exception {
  }

  @HttpPost
  global static void createSpecialServiceRequest(SpecialServiceJSON2Apex form) {
    try {
      SpecialServiceRequestService.createSpecialServiceRequest(form);
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'SpecialServiceRequestFormAPI',
        null
      );
      throw new APIException();
    }
  }
}