trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert) {
	new LiveChatTranscriptTriggerHandler().run();
}