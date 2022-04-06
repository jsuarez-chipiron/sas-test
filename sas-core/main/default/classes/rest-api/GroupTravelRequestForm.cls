@RestResource(urlMapping='/GroupTravelForm/*')
global with sharing class GroupTravelRequestForm {
  public class APIException extends Exception {
  }

  @HttpPost
  global static void createGroupTravelRequest(GroupTravelJsonToApex form) {
    try {
      GroupTravelService.createGroupTravelRequest(form);
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'GroupTravelFormAPI',
        null
      );
      throw new APIException();
    }
  }
}