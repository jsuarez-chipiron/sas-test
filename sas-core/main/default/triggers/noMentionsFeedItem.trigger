trigger noMentionsFeedItem on FeedItem (after insert, after update) {
    new MentionHandler().run();
}