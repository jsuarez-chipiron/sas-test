/**
    Class invoked by a process to remove additional survey responses. Deletes all completed responses but the first.
    @author Philip Ossler
*/
public without sharing class FCS_RemoveStartedSurveyResponses {
  @InvocableMethod(
    label='Remove Started SurveyResponses'
    description='Only the first SurveyResponse per Case will be saved'
  )
  /**
        @param invitationId The Id of related Survey Invitation
    */
  public static void updateSurveyResponses(List<Id> responseId) {
    List<SurveyResponse> surveyResponses = [
      SELECT Id, InvitationId, Status
      FROM SurveyResponse
      WHERE Status = 'Started' AND Id IN :responseId
    ];
    List<SurveyResponse> recordsToRemove = new List<SurveyResponse>();
    for (SurveyResponse sr : surveyResponses) {
      recordsToRemove.add(sr);
    }
    delete recordsToRemove;
  }
}
