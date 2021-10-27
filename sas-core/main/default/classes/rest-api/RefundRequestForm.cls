@RestResource(urlMapping='/RefundForm/*')
global with sharing class RefundRequestForm {
  @HttpPost
  global static void createRefundRequest(RefundJsonToApex form) {
    try {
      RefundRequestService.createRefundRequest(form);
    } catch (Exception e) {
      C_Log.logException(e, 'RefundRequestFormAPI', null);
      throw e;
    }
  }
}
