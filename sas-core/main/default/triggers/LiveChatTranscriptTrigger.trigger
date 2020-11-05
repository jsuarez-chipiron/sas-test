trigger LiveChatTranscriptTrigger on LiveChatTranscript (before update) {
	new FCS_LiveChatTranscriptTriggerHandler().run();
}