/**
 * @author Anton Norell
 * @date 2019-12-05
 * @description Test class for controller IdentifyCustomerComponentController
 */
@IsTest
private class IdentifyCustomerComponentController_Test {
    /**
     * Asserts that the correct case and fields are retrieved from method in controller
     */
    @IsTest
    static void shouldReturnCaseBasedOnCaseId(){
        Account acc = new Account(
                RecordTypeId = RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'Last Name'
        );
        insert acc;
        Case originalCase = new Case(
                AccountId = acc.Id,
                EBNumber__c = '123',
                TPAccountNumber__c = '321'
        );
        insert originalCase;

        Case retrievedCase = IdentifyCustomerComponentController.getCaseData(originalCase.Id);

        System.assertNotEquals(null, retrievedCase);
        System.assertEquals(originalCase.EBNumber__c, retrievedCase.EBNumber__c);
        System.assertEquals(acc.Id, retrievedCase.AccountId);
        System.assertEquals(null, retrievedCase.Account.LastRetrievedFromSource__c);
    }

    /**
     * Asserts that the controller maps information from a frequent flyer record to an account record correctly.
     * Checks both valid values and null values.
     */
    @IsTest
    static void shouldReturnAccountBasedOnFrequentFlyer(){
        FrequentFlyer__x ff = new FrequentFlyer__x(
                ExternalId = '123',
                AddressLine1__c = 'AddressLine1',
                City__c = 'City',
                ZipCode__c = 'ZipCode',
                CountryCode__c = 'Country',
                CountyState__c = 'State',
                BirthDate__c = Date.today().addYears(-2),
                ConsentEmail__c = true,
                ConsentEB__c = false,
                ConsentSMS__c = true,
                ConsentEB0__c = false,
                ConsentTelemarketing__c = true,
                EmailPersonal__c = 'email@email.com',
                EBBalance__c = 1000,
                EBLevel__c = null,
                EBNumber__c = '321',
                FirstName__c = 'First Name',
                Gender__c = 'F',
                LastName__c = 'Last Name',
                EBMemberSinceDate__c = null,
                Mobile__c = '0701234567',
                Phone__c = null,
                EBQualifyingPeriodEndDate__c = Date.today().addYears(1),
                EBQualifyingPeriodStartDate__c = Date.today(),
                EBReachesNextLevelPoints__c = null,
                SubscriptionId__c = null,
                TPAccountNumber__c = '678',
                CompanyName__c = 'Company Name',
                MiddleName__c = 'Middle',
                Salutation__c = 'Salutation',
                Title__c = 'Title'
        );

        List<Account> accounts = IdentifyCustomerComponentController.createAccountRecordsBasedOnFrequentFlyers(
                new List<FrequentFlyer__x>{ff}
        );
        insert accounts;

        System.assertEquals(1, accounts.size(), 'Method returned wrong number of accounts - should contain one account');
        Account acc = accounts[0];
        System.assertEquals(RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER, acc.RecordTypeId);
        System.assertEquals(ff.ExternalId, acc.FrequentFlyer__c);
        System.assertEquals(ff.AddressLine1__c, acc.PersonMailingStreet);
        System.assertEquals(ff.City__c, acc.PersonMailingCity);
        System.assertEquals(ff.ZipCode__c, acc.PersonMailingPostalCode);
        System.assertEquals(ff.CountryCode__c, acc.PersonMailingCountry);
        System.assertEquals(ff.CountyState__c, acc.PersonMailingState);
        System.assertEquals(ff.BirthDate__c, acc.PersonBirthdate);
        System.assertEquals(ff.ConsentEmail__c, acc.ConsentEmail__c);
        System.assertEquals(ff.ConsentEB__c, acc.ConsentEuroBonus__c);
        System.assertEquals(ff.ConsentEB0__c, acc.ConsentSiteProfile__c);
        System.assertEquals(ff.ConsentSMS__c, acc.ConsentSMS__c);
        System.assertEquals(ff.ConsentTelemarketing__c, acc.ConsentTelemarketing__c);
        System.assertEquals(ff.EmailPersonal__c, acc.PersonEmail);
        System.assertEquals(ff.EBBalance__c, acc.EBBalance__c);
        System.assertEquals(ff.EBLevel__c, acc.EBLevel__c);
        System.assertEquals(ff.EBNumber__c, acc.EBNumber__c);
        System.assertEquals(ff.FirstName__c, acc.FirstName);
        System.assertEquals(ff.Gender__c, acc.Gender__c);
        System.assertEquals(ff.LastName__c, acc.LastName);
        System.assertEquals(ff.EBMemberSinceDate__c, acc.EBMemberSinceDate__c);
        System.assertEquals(ff.EBQualifyingPeriodEndDate__c, acc.EBQualifyingPeriodEndDate__c);
        System.assertEquals(ff.EBQualifyingPeriodStartDate__c, acc.EBQualifyingPeriodStartDate__c);
        System.assertEquals(ff.EBReachesNextLevelPoints__c, acc.EBReachesNextLevelPoints__c);
        System.assertEquals(ff.SubscriptionId__c, acc.SubscriptionId__c);
        System.assertEquals(ff.TPAccountNumber__c, acc.TPAccountNumber__c);
        System.assertEquals(ff.CompanyName__c, acc.CompanyName__c);
        System.assertEquals(ff.Title__c, acc.PersonTitle);
        System.assertEquals(ff.Salutation__c, acc.Salutation);
        System.assertEquals(ff.MiddleName__c, acc.MiddleName);
        System.assert(acc.LastRetrievedFromSource__c > DateTime.now().addMinutes(-5)
                && acc.LastRetrievedFromSource__c < DateTime.now().addMinutes(5));
    }
}