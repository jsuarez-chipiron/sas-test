/**
 * Test class to ensure that the contact handler works as intended
 */
@isTest
private class FCS_ContactHandler_Test {
  /**
   * Tests inserting a new email contact with a specified account id
   */
  @isTest
  static void withAccountId() {
    Contact con = new Contact(
      FirstName = 'Test',
      LastName = 'Test',
      RecordTypeId = C_RecordTypeHelper.CONTACT_EMAILCONTACT
    );
    insert con;
  }
}
