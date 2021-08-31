@RestResource(urlMapping='/Refundform/*')
global with sharing class RefundRequestForm {
  @HttpPost
  global static String refundForm(RefundJsonToApex form) {
    return RefundRequestService.createRefundForm(form);
  }
}
