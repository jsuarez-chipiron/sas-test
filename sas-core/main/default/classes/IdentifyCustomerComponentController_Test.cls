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

        Account account = IdentifyCustomerComponentController.createAccountRecordBasedOnFrequentFlyers(
                new List<FrequentFlyer__x>{ff}
        );

        System.assertNotEquals(null, account, 'Method did not return expected account');
        System.assertEquals(RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER, account.RecordTypeId);
        System.assertEquals(ff.ExternalId, account.FrequentFlyer__c);
        System.assertEquals(ff.AddressLine1__c, account.PersonMailingStreet);
        System.assertEquals(ff.City__c, account.PersonMailingCity);
        System.assertEquals(ff.ZipCode__c, account.PersonMailingPostalCode);
        System.assertEquals(ff.CountryCode__c, account.PersonMailingCountry);
        System.assertEquals(ff.CountyState__c, account.PersonMailingState);
        System.assertEquals(ff.BirthDate__c, account.PersonBirthdate);
        System.assertEquals(ff.ConsentEmail__c, account.ConsentEmail__c);
        System.assertEquals(ff.ConsentEB__c, account.ConsentEuroBonus__c);
        System.assertEquals(ff.ConsentEB0__c, account.ConsentSiteProfile__c);
        System.assertEquals(ff.ConsentSMS__c, account.ConsentSMS__c);
        System.assertEquals(ff.ConsentTelemarketing__c, account.ConsentTelemarketing__c);
        System.assertEquals(ff.EmailPersonal__c, account.PersonEmail);
        System.assertEquals(ff.EBBalance__c, account.EBBalance__c);
        System.assertEquals(ff.EBLevel__c, account.EBLevel__c);
        System.assertEquals(ff.EBNumber__c, account.EBNumber__c);
        System.assertEquals(ff.FirstName__c, account.FirstName);
        System.assertEquals(ff.Gender__c, account.Gender__c);
        System.assertEquals(ff.LastName__c, account.LastName);
        System.assertEquals(ff.EBMemberSinceDate__c, account.EBMemberSinceDate__c);
        System.assertEquals(ff.EBQualifyingPeriodEndDate__c, account.EBQualifyingPeriodEndDate__c);
        System.assertEquals(ff.EBQualifyingPeriodStartDate__c, account.EBQualifyingPeriodStartDate__c);
        System.assertEquals(ff.EBReachesNextLevelPoints__c, account.EBReachesNextLevelPoints__c);
        System.assertEquals(ff.SubscriptionId__c, account.SubscriptionId__c);
        System.assertEquals(ff.TPAccountNumber__c, account.TPAccountNumber__c);
        System.assertEquals(ff.CompanyName__c, account.CompanyName__c);
        System.assertEquals(ff.Title__c, account.PersonTitle);
        System.assertEquals(ff.Salutation__c, account.Salutation);
        System.assertEquals(ff.MiddleName__c, account.MiddleName);
        System.assert(account.LastRetrievedFromSource__c > DateTime.now().addMinutes(-5)
                && account.LastRetrievedFromSource__c < DateTime.now().addMinutes(5));
    }

    /**
     * Asserts that an account record is inserted based on a provided Frequent Flyer record provided to controller
     */
    @IsTest
    static void shouldInsertBasedOnFrequentFlyer(){
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

        IdentifyCustomerComponentController.createAccountRecordBasedOnFrequentFlyers(new List<FrequentFlyer__x>{ff});

        System.assertEquals(1, [SELECT Id FROM Account].size(), 'Expected 1 account to be inserted based on Frequent Flyer');
    }

    /**
     * Asserts that the controller can handle an empty return when querying for Frequent Flyer
     */
    @IsTest
    static void shouldReturnNullIfFrequentFlyerListIfEmpty(){
        Account account = IdentifyCustomerComponentController.createAccountRecordBasedOnFrequentFlyers(
                new List<FrequentFlyer__x>()
        );

        System.assertEquals(null, account);
    }

    /**
     * Asserts that the query for the external object Frequent Flyer can run correctly. As external object queries
     * are not supported in test context, the test should return a null result.
     */
    @IsTest
    static void shouldReturnNullResultDueToNoSupportForQuery(){
        Account account = IdentifyCustomerComponentController.findCustomer('EBNumber__c', '700001423');

        System.assertEquals(null, account);
    }

    /**
     * Asserts that the query for the external object Frequent Flyer can run correctly. As external object queries
     * are not supported in test context, the test catches the expected exception and verifies the message.
     *//*
    @IsTest
    static void shouldThrowExceptionDueToUnsupportedExternalObjectQuery(){
        Exception returnedException;
        try{
            Account account = IdentifyCustomerComponentController.findCustomer('EBNumber__c', '700001423');

        } catch (QueryException e){
            returnedException = e;
        }
        System.assertNotEquals(null, returnedException, 'Expected a QueryException to be thrown');
        System.assertEquals('entity type FrequentFlyer__x does not support query',
                returnedException.getMessage(),
                'Expected the exception to contain another message. Check that used query is not malformed. '
        );
    }*/
}