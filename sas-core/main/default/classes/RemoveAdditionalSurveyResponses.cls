public without sharing class RemoveAdditionalSurveyResponses {
    @InvocableMethod(label='Remove Additional SurveyResponses' description='Only the first SurveyResponse per Case will be saved')
    public static void updateSurveyResponses(List<SurveyInvitation> invitationId) {
        List<SurveyResponse> surveyResponses = [
            SELECT InvitationId 
            FROM SurveyResponse
            WHERE InvitationId IN: new Map<Id, SurveyInvitation>(invitationId).keySet()
            ORDER BY CreatedDate ASC
        ];
        if(surveyResponses.size() > 1) {
            List<SurveyResponse> recordsToRemove = new List<SurveyResponse>();
            for(SurveyResponse sr : surveyResponses) {
                recordsToRemove.add(sr);
            } 
            recordsToRemove.remove(0);
            delete recordsToRemove;
        }
    }
}
