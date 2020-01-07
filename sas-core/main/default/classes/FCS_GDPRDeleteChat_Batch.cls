/**
    Classs used to delete chat interactions
    @author Peter Södergren
*/
global class FCS_GDPRDeleteChat_Batch extends FCS_GDPRDeleteInteraction_Batch{
    /**
        Deletes chats
    */
    global FCS_GDPRDeleteChat_Batch() {
        super(LiveChatTranscript.SObjectType,LiveChatTranscript.CaseId,LiveChatVisitor.SObjectType,LiveChatTranscript.LiveChatVisitorId,null);
    }
}
