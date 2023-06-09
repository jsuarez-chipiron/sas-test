/**
 * @author Anton Norell
 * @date 2019-12-19
 * @description Test class for GDPR_DataExtractService
 */
@IsTest
private class GDPR_DataExtractService_Test {
    /**
     * Asserts that the queries in the service are generated correctly based on provided FieldDefinition list. The
     * field definitions are retrieved from static resources.
     */
    @IsTest
    static void shouldReturnQueriesBasedOnFieldDefinitions() {
        Account acc = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc;
        StaticResource fieldDefinition = [SELECT Id, Body FROM StaticResource WHERE Name = 'FieldDefinitionsJSON'];
        List<FieldDefinition> fieldDefinitions = (List<FieldDefinition>)JSON.deserialize(fieldDefinition.Body.toString(), List<FieldDefinition>.class);

        List<String> queries = GDPR_DataExtractService.getQueries(fieldDefinitions, new Id[]{acc.Id});

        System.assertEquals(
                            'SELECT null FROM Account WHERE Id IN (\'' + acc.Id + '\')', queries[0],
                            'Generated incorrect Account query based on provided field definition'
        );
        System.assertEquals(
                        'SELECT Status, AccountId, Description, FCS_Case_Reason__c, (SELECT MessageDate, FromName, ToAddress, ' +
                        'HtmlBody, TextBody, Subject, FromAddress FROM EmailMessages) FROM Case ' +
                        'WHERE AccountId IN (\'' + acc.Id + '\')',
                        queries[1], 'Generated incorrect Case query based on provided field definition'
        );

        System.assertEquals(
                        'SELECT EndTime, VisitorMessageCount, ChatDuration, EndedBy, StartTime, ' +
                        'IpAddress, Body, Status, AccountId, Location FROM LiveChatTranscript WHERE AccountId IN (\'' + acc.Id + '\')',
                        queries[2], 'Generated incorrect LiveChatTranscript query based on provided field definition'
        );
    }

    /**
     * Asserts that the extract generated by the service includes all records in scope connected to the selected account.
     * Field definitions are retrieved from static resources and the date included in the extract is generated in the
     * test class.
     */
    @IsTest
    static void shouldReturnMultipleExtractsForMultipleAccounts(){
        Account acc1 = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc1;

        Account acc2 = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc2;

        StaticResource fieldDefinition = [SELECT Id, Body FROM StaticResource WHERE Name = 'FieldDefinitionsJSON'];
        List<FieldDefinition> fieldDefinitions = (List<FieldDefinition>)JSON.deserialize(fieldDefinition.Body.toString(), List<FieldDefinition>.class);
        String[] jsonData = GDPR_DataExtractService.extractAccountPersonalData(new Id[]{acc1.Id, acc2.Id}, fieldDefinitions, generateExtractObjectSettings());

        System.assertEquals(2, jsonData.size(), 'Incorrect number of accounts in extract');
        List<SObject> extractedRecordsForAccount1 = (List<SObject>)JSON.deserialize(jsonData[0], List<SObject>.class);
        List<SObject> extractedRecordsForAccount2 = (List<SObject>)JSON.deserialize(jsonData[1], List<SObject>.class);
        System.assertEquals(acc1.Id, extractedRecordsForAccount1[0].Id);
        System.assertEquals(acc2.Id, extractedRecordsForAccount2[0].Id);
    }

    /**
     * Asserts that the extract generated by the service includes all records in scope connected to the selected account.
     * Field definitions are retrieved from static resources and the date included in the extract is generated in the
     * test class.
     */
    @IsTest
    static void shouldReturnCorrectPersonalDataExtractBasedOnProvidedFieldDefinition(){
        Account acc = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc;
        Case cse = new Case(
                Subject = 'Subject',
                AccountId = acc.Id
        );
        insert cse;
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        lct.AccountId = acc.Id;
        insert lct;

        StaticResource fieldDefinition = [SELECT Id, Body FROM StaticResource WHERE Name = 'FieldDefinitionsJSON'];
        List<FieldDefinition> fieldDefinitions = (List<FieldDefinition>)JSON.deserialize(fieldDefinition.Body.toString(), List<FieldDefinition>.class);

        String[] jsonData = GDPR_DataExtractService.extractAccountPersonalData(new Id[]{acc.Id}, fieldDefinitions, generateExtractObjectSettings());
        List<SObject> extractObjects = (List<SObject>)JSON.deserialize(jsonData[0], List<SObject>.class);

        System.assertEquals(3, extractObjects.size(), 'Incorrect number of records in extract');
        System.assertEquals(acc.Id, extractObjects[0].Id);
        System.assertEquals(cse.Id, extractObjects[1].Id);
        System.assertEquals(lct.Id, extractObjects[2].Id);
    }

    /**
     * Asserts that the service can query existing field definitions if none are provided as argument.
     * Only a simple assertion is performed as data in extract is dependent on dynamic field definitions
     * that can be changed by configuration in setup;
     */
    @IsTest
    static void shouldReturnPersonalDataExtractBasedOnQueriedFieldDefinition(){
        Account acc = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc;

        String[] jsonData = GDPR_DataExtractService.extractAccountPersonalData(new Id[]{acc.Id}, null, generateExtractObjectSettings());
        List<SObject> extractObjects = (List<SObject>)JSON.deserialize(jsonData[0], List<SObject>.class);

        System.assertNotEquals(null, jsonData);
        System.assertEquals(acc.Id, extractObjects[0].Id);
    }

    /**
     * Asserts that an exception is thrown if no configuration for extracting object exists. The exception is triggered
     * by providing an empty configuration list to the service.
     */
    @IsTest
    static void shouldThrowExceptionWhenNoSettingsExist(){
        Account acc = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc;
        GDPR_DataExtractService.DataExtractException catchedException;
        try{
            GDPR_DataExtractService.extractAccountPersonalData(new Id[]{acc.Id}, null, new GDPRExtractObjectSetting__mdt[]{});
        } catch (GDPR_DataExtractService.DataExtractException e){
            catchedException = e;
        }
        System.assertNotEquals(null, catchedException, 'No exception was thrown. Should throw DataExtractException.');
        System.assertEquals(
                        'No configuration for Data Extract exists. Add at least on object to perform operation.',
                        catchedException.getMessage(), 'The message in the exception was not expected. Check that the correct ' +
                        'exception was thrown and that the message has not been changed.'
        );
    }

    /**
     * Asserts that an exception is thrown if an object in extract configuration is included with a reference to a
     * parent object, but that parent is not part of the configuration.
     */
    @IsTest
    static void shouldThrowExceptionIfParentObjectIsMissingFromChildObjectConfiguration(){
        Account acc = new Account(
                RecordTypeId = C_RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                LastName = 'LastName'
        );
        insert acc;

        GDPR_DataExtractService.DataExtractException catchedException;
        try{
            GDPR_DataExtractService.extractAccountPersonalData(
                    new Id[]{acc.Id},
                    null,
                    new GDPRExtractObjectSetting__mdt[]{generateExtractObjectSettings()[3]});
        } catch (GDPR_DataExtractService.DataExtractException e){
            catchedException = e;
        }

        System.assertNotEquals(null, catchedException, 'No exception was thrown. Should throw DataExtractException.');
        System.assertEquals(
                'Object Case must be included in extract configuration as it is set as parent for object EmailMessage',
                catchedException.getMessage(),
                'The message in the exception was not expected. Check that the correct exception was thrown and that ' +
                        'the message has not been changed.'
        );
    }

    /**
     * Used to generate settings for object extraction for this test class. Ass configuration can be changes in setup,
     * the configuration for the test must remain the same for the assertions to pass.
     * @return List of settings for extracting objects
     */
    public static GDPRExtractObjectSetting__mdt[] generateExtractObjectSettings(){
        GDPRExtractObjectSetting__mdt[] settings = new GDPRExtractObjectSetting__mdt[4];
        settings[0] = (new GDPRExtractObjectSetting__mdt(
                Label = 'Account',
                DeveloperName = 'Account',
                ObjectName__c = 'Account',
                AccountIdFieldName__c = 'Id'
        ));
        settings[1] = (new GDPRExtractObjectSetting__mdt(
                Label = 'Case',
                DeveloperName = 'Case',
                ObjectName__c = 'Case',
                AccountIdFieldName__c = 'AccountId'
        ));
        settings[2] = (new GDPRExtractObjectSetting__mdt(
                Label = 'Chat',
                DeveloperName = 'Chat',
                ObjectName__c = 'LiveChatTranscript',
                AccountIdFieldName__c = 'AccountId'
        ));
        settings[3] = (new GDPRExtractObjectSetting__mdt(
                Label = 'Email',
                DeveloperName = 'Email',
                ObjectName__c = 'EmailMessage',
                ParentObjectName__c = 'Case',
                RelationshipName__c = 'EmailMessages'
        ));
        return settings;
    }
}