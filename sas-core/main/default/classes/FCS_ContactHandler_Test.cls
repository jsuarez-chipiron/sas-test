/**
 * Test class to ensure that the contact handler works as intended
 */
@isTest
private class FCS_ContactHandler_Test {
    /**
     * Tests inserting a new email contact with a specified account id
     */
    @isTest static void withAccountId(){
        RecordType accRT = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND IsPersonType=false LIMIT 1];
        Account acc = new Account(Name='TEST',RecordTypeId=accRT.Id);
        insert acc;

        C_Settings.getSettings('EmailContact').set('AccountId', acc.Id+'');

        Contact con = new Contact(FirstName='Test',LastName='Test',RecordTypeId=C_RecordTypeHelper.CONTACT_EMAILCONTACT);
        insert con;

        con = [SELECT Id,AccountId FROM Contact WHERE Id=:con.Id];
        System.assertEquals(acc.Id,con.AccountId);
    }

    /**
     * Tests inserting a new email contact without a specified account id
     */
    @isTest static void withoutAccountId(){
        RecordType accRT = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND IsPersonType=false LIMIT 1];
        Account acc = new Account(Name='TEST',RecordTypeId=accRT.Id);
        insert acc;

        C_Settings.getSettings('EmailContact').set('AccountId', null);

        Contact con = new Contact(FirstName='Test',LastName='Test',RecordTypeId=C_RecordTypeHelper.CONTACT_EMAILCONTACT);
        insert con;

        con = [SELECT Id,AccountId FROM Contact WHERE Id=:con.Id];
        System.assertEquals(null,con.AccountId);
    }
}
