/**
    Class used to delete messaging interactions
    @author Peter Södergren
*/
global class FCS_GDPRDeleteMessaging_Batch extends FCS_GDPRDeleteInteraction_Batch{
    /**
        Deletes messaging interactions
    */
    global FCS_GDPRDeleteMessaging_Batch() {
        super(MessagingSession.SObjectType,MessagingSession.CaseId,MessagingEndUser.SObjectType,MessagingSession.MessagingEndUserId,null);
    }
}
