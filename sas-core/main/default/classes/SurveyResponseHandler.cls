/**
    SurveyResponseTriggerHandler for restricting SurveyResponses and limiting to only one response per Case
    @author Philip Ossler - Deloitte
*/
public without sharing class SurveyResponseHandler extends C_TriggerHandler {
    public override void afterInsert() {
        Set<String> setInvitationId = new Set<String>();
        
        for(SurveyResponse sr : (List<SurveyResponse>) Trigger.new) {
            setInvitationId.add(sr.InvitationId);
        }

        if(setInvitationId.size() > 0) {
            Map<Id, SurveyResponse> responseMap = new Map<Id, SurveyResponse>([SELECT Id FROM SurveyResponse WHERE InvitationId =: setInvitationId ORDER BY CreatedDate ASC]);
            List<Id> responseIds = new List<Id>();
            responseIds.addAll(responseMap.keySet());

            responseIds.remove(0);

            if(responseIds.size() > 0) deleteNewResponse(responseIds);
        }
    }

    /** 
        Method to delete all other SurveyResponses but the first response
    */
    @future(callout=true)
    public static void deleteNewResponse(List<Id> responseId) {
        delete [SELECT Id FROM SurveyResponse WHERE Id =: responseId];
    }
}