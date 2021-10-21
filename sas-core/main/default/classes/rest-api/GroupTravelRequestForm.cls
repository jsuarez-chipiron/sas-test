@RestResource(urlMapping='/GroupTravelForm/*')
global with sharing class GroupTravelRequestForm {
  @HttpPost
  global static void createGroupTravelRequest(GroupTravelJsonToApex form) {
    try {
      GroupTravelService.createGroupTravelRequest(form);
    } catch (Exception e) {
      C_Log.logException(e, 'GroupTravelFormAPI', null);
      throw e;
    }
  }
}
