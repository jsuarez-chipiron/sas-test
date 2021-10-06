@RestResource(urlMapping='/GroupTravelForm/*')
global with sharing class GroupTravelRequestForm {
  @HttpPost
  global static String groupTravelForm(GroupTravelJsonToApex form) {
    return GroupTravelService.createGroupTravelForm(form);
  }
}
