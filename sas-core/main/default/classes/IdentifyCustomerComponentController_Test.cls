/**
 * @author Anton Norell
 * @date 2019-12-05
 * @description Test class for controller IdentifyCustomerComponentController
 */
@IsTest
private class IdentifyCustomerComponentController_Test {
    /**
     * Asserts that the correct case and fields are retrieved from method in controller.
     */
    @IsTest
    static void shouldReturnRecordDataBasedOnCaseId(){
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

        IdentifyCustomerComponentController.ComponentRecordData retrievedData = IdentifyCustomerComponentController.getRecordData(originalCase.Id);

        System.assertNotEquals(null, retrievedData);
        System.assertEquals(originalCase.EBNumber__c, retrievedData.euroBonusNumber);
        System.assertEquals(acc.Id, retrievedData.accountId);
        System.assertEquals(null, retrievedData.lastRetrievedFromSource);
    }

    /**
     * Asserts that the correct LiveChatTranscript and fields are retrieved from method in controller
     */
    @IsTest
    static void shouldReturnRecordDataBasedOnLiveChatTranscriptId(){
        Account acc = new Account(
                RecordTypeId = RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'Last Name'
        );
        insert acc;
        acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :acc.Id];
        Case originalCase = new Case(
                AccountId = acc.Id,
                EBNumber__c = '123',
                TPAccountNumber__c = '321'
        );
        insert originalCase;
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        LiveChatTranscript transcript = new LiveChatTranscript(
                LiveChatVisitorId = visitor.Id,
                CaseId = originalCase.Id,
                AccountId = acc.Id,
                ContactId = acc.PersonContactId,
                EBNumber__c = '123',
                CODSId__c = '321'
        );
        insert transcript;

        IdentifyCustomerComponentController.ComponentRecordData retrievedData = IdentifyCustomerComponentController.getRecordData(transcript.Id);

        System.assertNotEquals(null, retrievedData);
        System.assertEquals(transcript.EBNumber__c, retrievedData.euroBonusNumber);
        System.assertEquals(acc.Id, retrievedData.accountId);
        System.assertEquals(transcript.CODSId__c, retrievedData.codsId);
        System.assertEquals(acc.PersonContactId, retrievedData.personContactId);
        System.assertEquals(null, retrievedData.lastRetrievedFromSource);
    }

    /**
     * Asserts that the correct MessagingSession and fields are retrieved from method in controller
     */
    @IsTest
    static void shouldReturnRecordDataBasedOnMessagingSession(){
        Account acc = new Account(
                RecordTypeId = RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'Last Name'
        );
        insert acc;
        acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :acc.Id];
        Case originalCase = new Case(
                AccountId = acc.Id,
                EBNumber__c = '123',
                TPAccountNumber__c = '321'
        );
        insert originalCase;
        MessagingEndUser messagingEndUser1 = new MessagingEndUser(
                MessagingChannelId = '0Mj1X0000004CLJSA2',
                Name = 'User1',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123',
                AccountId = acc.Id,
                ContactId = acc.PersonContactId
        );
        insert messagingEndUser1;
        MessagingSession session = new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'New',
                MessagingChannelId = '0Mj1X0000004CLJSA2',
                CaseId = originalCase.Id
        );
        insert session;

        IdentifyCustomerComponentController.ComponentRecordData retrievedData = IdentifyCustomerComponentController.getRecordData(session.Id);

        System.assertNotEquals(null, retrievedData);
        System.assertEquals(acc.Id, retrievedData.accountId);
        System.assertEquals(acc.PersonContactId, retrievedData.personContactId);
        System.assertEquals(null, retrievedData.lastRetrievedFromSource);
    }

    /**
     * Asserts that the controller can update a chat transcript record based on a supplied JSON string with record id and data
     */
    @IsTest
    static void shouldUpdateLiveChatTranscriptBasedOnSuppliedJSONData(){
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        LiveChatTranscript transcript = new LiveChatTranscript(LiveChatVisitorId = visitor.Id);
        insert transcript;

        String jsonData = '{"recordId": "' + transcript.Id + '", "euroBonusNumber": "123"}';
        IdentifyCustomerComponentController.updateRecordDataWithApex(jsonData);

        System.assertEquals(
                '123',
                [SELECT Id, EBNumber__c FROM LiveChatTranscript WHERE Id = :transcript.Id].EBNumber__c,
                'The method did not update the underlying transcript correctly. Expected EBNumber__ to be updated.'
        );
    }


    /**
     * Asserts that the controller can update a chat transcript record based on a supplied JSON string with,
     * record id and data as well as updating a related case record
     */
    @IsTest
    static void shouldUpdateLiveChatTranscriptAndRelatedRecordsBasedOnSuppliedJSONData(){
        Case originalCase = new Case();
        insert originalCase;
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        LiveChatTranscript transcript = new LiveChatTranscript(LiveChatVisitorId = visitor.Id, CaseId = originalCase.Id);
        insert transcript;

        String jsonData = '{"recordId": "' + transcript.Id + '", "euroBonusNumber": "123", "caseId": "' + originalCase.Id + '"  }';
        IdentifyCustomerComponentController.updateRecordDataWithApex(jsonData);

        System.assertEquals(
                '123',
                [SELECT Id, EBNumber__c FROM LiveChatTranscript WHERE Id = :transcript.Id].EBNumber__c,
                'The method did not update the underlying transcript correctly. Expected EBNumber__ to be updated.'
        );
        System.assertEquals(
                '123',
                [SELECT Id, EBNumber__c FROM Case WHERE Id = :originalCase.Id].EBNumber__c,
                'The method did not update the related case correctly. Expected EBNumber__ to be updated.'
        );
    }

    /**
     * Asserts that the controller can update a case record based on a supplied JSON string with record id and data
     */
    @IsTest
    static void shouldUpdateCaseAndRelatedRecordsBasedOnSuppliedJSONData(){
        Case originalCase = new Case();
        insert originalCase;
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        LiveChatTranscript transcript = new LiveChatTranscript(LiveChatVisitorId = visitor.Id, CaseId = originalCase.Id);
        insert transcript;

        String jsonData = '{"recordId": "' + originalCase.Id + '", "euroBonusNumber": "123"}';
        IdentifyCustomerComponentController.updateRecordDataWithApex(jsonData);

        System.assertEquals(
                '123',
                [SELECT Id, EBNumber__c FROM Case WHERE Id = :originalCase.Id].EBNumber__c,
                'The method did not update the underlying case correctly. Expected EBNumber__ to be updated.'
        );
        System.assertEquals(
                '123',
                [SELECT Id, EBNumber__c FROM LiveChatTranscript WHERE Id = :transcript.Id].EBNumber__c,
                'The method did not update the related chat transcript correctly. Expected EBNumber__ to be updated.'
        );
    }

    /**
     * Asserts that the controller can update a MassagingSession record based on a supplied JSON string with record id and data
     */
    @IsTest
    static void shouldUpdateMessagingSessionAndRelatedRecordsBasedOnSuppliedJSONData(){
        Case originalCase = new Case();
        insert originalCase;
        MessagingEndUser messagingEndUser1 = new MessagingEndUser(
                MessagingChannelId = '0Mj1X0000004CLJSA2',
                Name = 'User1',
                MessageType = 'Facebook',
                MessagingPlatformKey = '123'
        );
        insert messagingEndUser1;
        MessagingSession session = new MessagingSession(
                Origin = 'InboundInitiated',
                MessagingEndUserId = messagingEndUser1.Id,
                Status = 'New',
                MessagingChannelId = '0Mj1X0000004CLJSA2',
                CaseId = originalCase.Id
        );
        insert session;

        Account account = new Account(RecordTypeId = RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER, LastName = 'Name');
        insert account;

        String jsonData = '{"recordId": "' + session.Id + '", "euroBonusNumber": "123", "caseId": "' + originalCase.Id + '", "accountId": "' + account.Id + '"}';
        IdentifyCustomerComponentController.updateRecordDataWithApex(jsonData);

        System.assertEquals(
                '123',
                [SELECT Id, AccountId, EBNumber__c FROM Case WHERE Id = :originalCase.Id].EBNumber__c,
                'The method did not update the related case correctly. Expected EBNumber__ to be updated.'
        );
        System.assertEquals(
                account.Id,
                [SELECT Id, EndUserAccountId, MessagingEndUser.AccountId FROM MessagingSession WHERE Id = :session.Id].MessagingEndUser.AccountId,
                'The method did not update the related End User Account correctly. Expected AccountId to be updated.'
        );
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
                BirthDate__c = String.valueOf(Date.today().addYears(-2)),
                ConsentEmail__c = true,
                ConsentEB__c = false,
                ConsentSMS__c = true,
                ConsentEB0__c = false,
                ConsentTelemarketing__c = true,
                EmailPersonal__c = 'email@email.com',
                EBLevel__c = null,
                EBNumber__c = '321',
                FirstName__c = 'First Name',
                Gender__c = 'F',
                LastName__c = 'Last Name',
                EBMemberSinceDate__c = null,
                Mobile__c = '0701234567',
                Phone__c = null,
                SubscriptionId__c = null,
                TPAccountNumber__c = '678',
                CompanyName__c = 'Company Name',
                CMP__c = '123',
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
        System.assertEquals(Date.valueOf(ff.BirthDate__c), account.PersonBirthdate);
        System.assertEquals(ff.ConsentEmail__c, account.ConsentEmail__c);
        System.assertEquals(ff.ConsentEB__c, account.ConsentEuroBonus__c);
        System.assertEquals(ff.ConsentEB0__c, account.ConsentSiteProfile__c);
        System.assertEquals(ff.ConsentSMS__c, account.ConsentSMS__c);
        System.assertEquals(ff.ConsentTelemarketing__c, account.ConsentTelemarketing__c);
        System.assertEquals(ff.EmailPersonal__c, account.PersonEmail);
        System.assertEquals(ff.EBLevel__c, account.EBLevel__c);
        System.assertEquals(ff.EBNumber__c, account.EBNumber__c);
        System.assertEquals(ff.FirstName__c, account.FirstName);
        System.assertEquals(ff.Gender__c, account.Gender__c);
        System.assertEquals(ff.LastName__c, account.LastName);
        System.assertEquals(null, account.EBMemberSinceDate__c);
        System.assertEquals(ff.SubscriptionId__c, account.SubscriptionId__c);
        System.assertEquals(ff.TPAccountNumber__c, account.TPAccountNumber__c);
        System.assertEquals(ff.CompanyName__c, account.CompanyName__c);
        System.assertEquals(ff.CMP__c, account.CMP__c);
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
                BirthDate__c = String.valueOf(Date.today().addYears(-2)),
                ConsentEmail__c = true,
                ConsentEB__c = false,
                ConsentSMS__c = true,
                ConsentEB0__c = false,
                ConsentTelemarketing__c = true,
                EmailPersonal__c = 'email@email.com',
                EBLevel__c = null,
                EBNumber__c = '321',
                FirstName__c = 'First Name',
                Gender__c = 'F',
                LastName__c = 'Last Name',
                EBMemberSinceDate__c = null,
                Mobile__c = '0701234567',
                Phone__c = null,
                SubscriptionId__c = null,
                TPAccountNumber__c = '678',
                CompanyName__c = 'Company Name',
                CMP__c = '123',
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
    * Asserts that en exception is thrown if component is placed on an unsupported object
    */
    @IsTest
    static void shouldThrowExceptionIfNotSupportedObject(){
        Opportunity opp = new Opportunity(Name = 'Name', StageName = 'New', CloseDate = Date.today());
        insert opp;

        IdentifyCustomerComponentController.IdentifyCustomerComponentException catchedException;
        try{
            IdentifyCustomerComponentController.getRecordData(opp.Id);
        } catch (IdentifyCustomerComponentController.IdentifyCustomerComponentException e){
            catchedException = e;
        }

        System.assertNotEquals(null, catchedException, 'Expected exception for unsupported object. Check that object is still unsupported.');
    }

    /**
     * Asserts that the query for the external object Frequent Flyer can run correctly. As external object queries
     * are not supported in test context, the test should return a null result.
     */
/*
    @IsTest
    static void shouldReturnNullResultDueToNoSupportForQuery(){
        Account account = IdentifyCustomerComponentController.findCustomer('EBNumber__c', '700001423');

        System.assertEquals(null, account);
    }
*/
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