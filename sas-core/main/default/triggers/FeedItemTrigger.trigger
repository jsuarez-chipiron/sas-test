trigger FeedItemTrigger on FeedItem (after insert, after update) {
    new FCS_MentionHandler().run();
}