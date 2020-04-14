/**
 * Class for overriding the default QuickAction when writing Emails
 * @author Philip Ossler
 */
global class FCS_EmailPublisherAction implements QuickAction.QuickActionDefaultsHandler {
    // Empty constructor
    global FCS_EmailPublisherAction() {
    }

    // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults)defaults.get(0);
        EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject(); 
        
        Case c = [SELECT CaseNumber, Type FROM Case WHERE Id=:sendEmailDefaults.getContextId()];

        // Assign default FromAddress based on the Case Type
        if (c.Type != null && c.Type.equals('Sales Information')) {
            emailMessage.FromAddress = String.valueOf(C_Settings.getSettings('EMAIL ADDRESS').get('Sales Information'));
        }
        else if (c.Type != null && c.Type.equals('SASSI Internal')) {
            emailMessage.FromAddress = C_Settings.getSettings('EMAIL ADDRESS').get('SASSI Internal');
        }    
        else if (c.Type == null || c.Type.equals('System') || c.Type.equals('Tariff')) {
            emailMessage.FromAddress = C_Settings.getSettings('EMAIL ADDRESS').get('System & Tariff');
        }
    } 
}
