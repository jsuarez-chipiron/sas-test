@RestResource(urlMapping='/RefundForm/*')
global with sharing class RefundRequestForm {
  public class APIException extends Exception {
  }

  @HttpPost
  global static void createRefundRequest(RefundJsonToApex form) {
    try {
      RefundRequestService.createRefundRequest(form);
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'RefundRequestFormAPI',
        null
      );
      throw new APIException();
    }
  }
}