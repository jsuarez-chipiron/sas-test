/**
    Class used to delete email interactions
    @author Peter Södergren
*/
global with sharing class GDPR_DeleteEmail_Batch extends GDPR_DeleteInteraction_Batch{
    /**
        Deletes emails (Emails retain consent through their parent case)
    */
    global GDPR_DeleteEmail_Batch() {
        super(EmailMessage.SObjectType,'DeletePeriodEmail','DeletePeriodEmailConsent',EmailMessage.ParentId,null,null);
    }
}
