trigger SurveyResponseTrigger on SurveyResponse (after insert) {
    new SurveyResponseHandler().run();
}