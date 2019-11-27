trigger FeedItemTrigger on FeedItem (after insert, after update) {
    new MentionHandler().run();
}