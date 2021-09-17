@RestResource(urlMapping='/SpecialServiceForm/*')
global with sharing class SpecialServiceRequestForm {
  @HttpPost
  global static String specialServiceForm(
    SpecialServiceJSON2Apex specialServiceForm
  ) {
    return SpecialService.createSpecialServiceForm(specialServiceForm);
  }
}
