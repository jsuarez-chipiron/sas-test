trigger FeedCommentTrigger on FeedComment (after insert, after update) {
    new MentionHandler().run();
}