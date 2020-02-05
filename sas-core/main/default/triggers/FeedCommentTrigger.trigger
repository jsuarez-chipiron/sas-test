trigger FeedCommentTrigger on FeedComment (after insert, after update) {
    new FCS_MentionHandler().run();
}