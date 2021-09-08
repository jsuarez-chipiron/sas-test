@RestResource(urlMapping='/GroupTravelForm/*')

global with sharing class GroupTravelRequestForm {
  @HttpPost
  global static String groupTravelForm(GroupTravelJsonToApex groupTravelForm) {
    return GroupTravelService.createGroupTravelForm(groupTravelForm);
  }
}