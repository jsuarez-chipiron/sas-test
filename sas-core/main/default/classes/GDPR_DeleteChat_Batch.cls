/**
    Classs used to delete chat interactions
    @author Peter Södergren
*/
global class GDPR_DeleteChat_Batch extends GDPR_DeleteInteraction_Batch{
    /**
        Deletes chats
    */
    global GDPR_DeleteChat_Batch() {
        super(LiveChatTranscript.SObjectType,LiveChatTranscript.CaseId,LiveChatVisitor.SObjectType,LiveChatTranscript.LiveChatVisitorId,null);
    }
}
