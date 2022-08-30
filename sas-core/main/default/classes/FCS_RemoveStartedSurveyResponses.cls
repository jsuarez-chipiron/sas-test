/**
    Class invoked by a process to remove Started survey responses.
*/
/**
        @param responseId The Id of related Survey Response
*/

public without sharing class FCS_RemoveStartedSurveyResponses {
  @InvocableMethod(
    label='Remove Started SurveyResponses'
    description='All the Survey with Status Started will be removed'
  )
  public static void updateSurveyResponses(List<Id> responseId) {
    List<SurveyResponse> surveyResponses = [
      SELECT Id, InvitationId, Status
      FROM SurveyResponse
      WHERE Status = 'Started' AND Id IN :responseId
    ];
    delete surveyResponses;
  }
}
