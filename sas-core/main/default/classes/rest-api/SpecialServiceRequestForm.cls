@RestResource(urlMapping='/SpecialServiceForm/*')
global with sharing class SpecialServiceRequestForm {
  @HttpPost
  global static void createSpecialServiceRequest(SpecialServiceJSON2Apex form) {
    try {
      SpecialServiceRequestService.createSpecialServiceRequest(form);
    } catch (Exception e) {
      C_Log.logException(e, 'SpecialServiceRequestFormAPI', null);
      throw e;
    }
  }
}
