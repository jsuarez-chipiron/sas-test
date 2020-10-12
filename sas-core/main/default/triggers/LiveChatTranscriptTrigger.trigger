trigger LiveChatTranscriptTrigger on LiveChatTranscript (before update, after update) {
	new FCS_LiveChatTranscriptTriggerHandler().run();
}