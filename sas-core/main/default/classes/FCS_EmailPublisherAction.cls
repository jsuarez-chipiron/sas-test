/**
 * @author Philip Ossler
 * @date 2020-04-14
 * @description Class for overriding the default QuickAction when writing Emails
 */
global class FCS_EmailPublisherAction implements QuickAction.QuickActionDefaultsHandler {
    // Empty constructor
    global FCS_EmailPublisherAction() {
    }

    // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        //Set different values to enable Apex tests for when using default email quick action
        String actionName = Test.isRunningTest() ? 'Case.Email' : 'Case.SendEmail';
        String actionType = Test.isRunningTest() ? 'Email' : 'SendEmail';

        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
        // Check if the quick action is the standard Case Feed send email action
        for (QuickAction.QuickActionDefaults action : defaults) {
            if (action instanceof QuickAction.SendEmailQuickActionDefaults && 
                action.getTargetSObject().getSObjectType() == EmailMessage.sObjectType && 
                action.getActionName().equals(actionName) && 
                action.getActionType().equals(actionType)) {
                    sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) action;
                    break;
            }
        }
        
        if(sendEmailDefaults != null) {
            Case c = [SELECT CaseNumber, Type FROM Case WHERE Id=:sendEmailDefaults.getContextId()];

            EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject(); 

            // Assign default FromAddress based on the Case Type
            if (c.Type != null && c.Type.equals('Sales Information')) {
                emailMessage.FromAddress = C_Settings.getSettings('EMAIL ADDRESS').get('Sales Information');
                System.debug('From: ' + emailMessage.FromAddress);
            }
            else if (c.Type != null && c.Type.equals('SASSI Internal')) {
                emailMessage.FromAddress = C_Settings.getSettings('EMAIL ADDRESS').get('SASSI Internal');
                System.debug('From: ' + emailMessage.FromAddress);
            }    
            else if (c.Type == null || c.Type.equals('System') || c.Type.equals('Tariff')) {
                emailMessage.FromAddress = C_Settings.getSettings('EMAIL ADDRESS').get('System & Tariff');
                System.debug('From: ' + emailMessage.FromAddress);
            }
            System.debug('From: ' + emailMessage.FromAddress);
        }
    }
}
