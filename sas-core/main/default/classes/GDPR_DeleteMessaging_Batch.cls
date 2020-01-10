/**
    Class used to delete messaging interactions
    @author Peter Södergren
*/
global class GDPR_DeleteMessaging_Batch extends GDPR_DeleteInteraction_Batch{
    /**
        Deletes messaging interactions
    */
    global GDPR_DeleteMessaging_Batch() {
        super(MessagingSession.SObjectType,MessagingSession.CaseId,MessagingEndUser.SObjectType,MessagingSession.MessagingEndUserId,null);
    }
}