trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert) {
	new FCS_LiveChatTranscriptTriggerHandler().run();
}