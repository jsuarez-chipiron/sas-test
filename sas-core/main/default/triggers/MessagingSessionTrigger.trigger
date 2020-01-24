/**
 * @author Anton Norell
 * @date 2020-01-24
 * @description Trigger for object MessagingSession
 */
trigger MessagingSessionTrigger on MessagingSession (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new FCS_MessagingSessionTriggerHandler().run();
}