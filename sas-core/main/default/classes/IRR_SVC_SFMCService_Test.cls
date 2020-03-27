/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

@IsTest
private class IRR_SVC_SFMCService_Test {

    @IsTest
    static void testSendSMSMessage() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ISFMCService serviceMock = (IRR_SVC_ISFMCService) mocks.mock(IRR_SVC_SFMCServiceImpl.class);
        IRR_Application.Service.setMock(IRR_SVC_ISFMCService.class, serviceMock);

        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);
        IRR_SEL_ISMSDefinitionsSelector selectorMock = (IRR_SEL_ISMSDefinitionsSelector) mocks.mock(
                IRR_SEL_SMSDefinitionsSelector.class);

        //Given
        List<SFMC_SMSDefinition__mdt> smsDefinitions = new List<SFMC_SMSDefinition__mdt>{
                new SFMC_SMSDefinition__mdt(SFMC_CountryPrefix__c = 'TEST', SFMC_DefinitionKey__c='TEST_DEF_KEY'),
                new SFMC_SMSDefinition__mdt(SFMC_CountryPrefix__c = null, SFMC_DefinitionKey__c='TEST_NULL_KEY')
        };
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                    (Map<String, Object>) fflib_Match.anyObject(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn('{"requestId": "ccdb94bf-fcac-4fef-b194-08f534a2079a", "errorcode": 0, "responses": [{"messageKey": "GV1LhQ6NFkqFUAE1IsoQ9Q"}]}');
        mocks.when(selectorMock.getAllSMSDefinitions()).thenReturn(smsDefinitions);
        mocks.when(selectorMock.sObjectType()).thenReturn(SFMC_SMSDefinition__mdt.SObjectType);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(
                'TEST_CONTENT', 'TEST_RECIPIENT', 'TEST_CONTACT_KEY');
        IRR_SVC_SFMCService.SMSMessage smsMessageOther = new IRR_SVC_SFMCService.SMSMessage(
                'OTHER_CONTENT', 'OTHER_RECIPIENT', 'OTHER_CONTACT_KEY');

        //When
        IRR_SVC_SFMCService.sendSMSMessages(new List<IRR_SVC_SFMCService.SMSMessage>{smsMessage, smsMessageOther});

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_MC_API');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock, 2)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        Map<String, Object> recipientMatch = new Map<String, Object>{
                'recipients[0].to' => 'TEST_RECIPIENT',
                'recipients[0].contactKey' => 'TEST_CONTACT_KEY',
                'recipients[0].attributes.message' => 'TEST_CONTENT',
                'definitionKey' => 'TEST_DEF_KEY'
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                fflib_Match.eqString('/messaging/v1/sms/messages/'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                fflib_Match.mapWithPath(recipientMatch),
                (Map<String, Object>) fflib_Match.isNull());
        System.assertEquals('GV1LhQ6NFkqFUAE1IsoQ9Q', smsMessage.messageKey);
        Map<String, Object> otherRecipientMatch = new Map<String, Object>{
                'recipients[0].to' => 'OTHER_RECIPIENT',
                'recipients[0].contactKey' => 'OTHER_CONTACT_KEY',
                'recipients[0].attributes.message' => 'OTHER_CONTENT',
                'definitionKey' => 'TEST_NULL_KEY'
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                fflib_Match.eqString('/messaging/v1/sms/messages/'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.POST),
                fflib_Match.mapWithPath(otherRecipientMatch),
                (Map<String, Object>) fflib_Match.isNull());
        System.assertEquals('GV1LhQ6NFkqFUAE1IsoQ9Q', smsMessageOther.messageKey);
    }
}