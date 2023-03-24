@IsTest
public class SasAccount_Test {
    
    private static string EB_NUMBER = '12345';
    
    @IsTest 
    static void getId_Found() {
        // Create test account
        Account acc = new Account(
            RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
            LastName = 'Last Name',
            FCS_CODSId__c = '123',
            FCS_EBNumber__c = EB_NUMBER
        );
        insert acc;
        
        List<Account> accounts = SasAccount.getId(new List<String>{EB_NUMBER});
        Assert.areEqual(1, accounts.size());
        Assert.areEqual(acc.id, accounts[0].Id);
    }
    /*
    @IsTest 
    static void getId_NotFound() {
        // Create test account
        Account acc = new Account(
            RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
            LastName = 'Last Name',
            FCS_CODSId__c = '123',
            FCS_EBNumber__c = EB_NUMBER
        );
        insert acc;
        
        List<String> accountIds = SasAccount.getId(new List<String>{'EB_NOT_FOUND'});
        Assert.areEqual(1, accountIds.size());
        Assert.isNotNull(accountIds[0]);
    }*/
}