/**
 * Contact trigger handler
 * Contains the following logic
 * 1. Automatic setting of account for email contacts
 */
public without sharing class FCS_ContactHandler extends C_TriggerHandler {
  /**
   * Trigger variables
   */
  private Map<Id, Contact> newContactMap;
  private List<Contact> newContactList;
  private Map<Id, Contact> oldContactMap;
  private List<Contact> oldContactList;
  /**
   * Set variables
   */
  public FCS_ContactHandler() {
    this.newContactMap = (Map<Id, Contact>) Trigger.newMap;
    this.newContactList = (List<Contact>) Trigger.new;
    this.oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
    this.oldContactList = (List<Contact>) Trigger.old;
  }
  /**
   * Used to call the trigger in the before insert context
   */
  public override void beforeInsert() {
  }
}
