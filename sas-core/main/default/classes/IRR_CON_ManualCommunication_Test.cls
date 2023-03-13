/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Manual Communication LWC Controller.
*/

@IsTest
private class IRR_CON_ManualCommunication_Test {

    @IsTest
    static void testGetBookingPassengerInfos() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getBookingPassengerInfos(
                'TEST_BOOKING_ID');

        //Then
        System.assertEquals(passengerInfos, passengerResult);
        System.assertEquals(1, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
    }

    @IsTest
    static void testGetBookingPassengerInfos_Error() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_SVC_TedsService.TedsException tedsException =
                new IRR_SVC_TedsService.TedsException('Integration Response: 404 - Not Found');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenThrow(tedsException);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getBookingPassengerInfos(
                    'TEST_BOOKING_ID');
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage() == 'TEST_BOOKING_ID - Integration Response: 404 - Not Found') caughtException = true;
        }

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testGetBookingPassengerInfos_Multiple() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        IRR_MOD_PassengerInfo passengerInfoOther = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'OTHER_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfosOther = new List<IRR_MOD_PassengerInfo>{
                passengerInfoOther
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenReturn(passengerInfos);
        mocks.when(serviceMock.getPassengerInfosForBooking('OTHER_BOOKING_ID')).thenReturn(passengerInfosOther);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getBookingPassengerInfos(
                'TEST_BOOKING_ID,OTHER_BOOKING_ID');

        //Then
        System.assertEquals(2, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        System.assertEquals(passengerInfoOther.emailAddress, passengerResult[1].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('OTHER_BOOKING_ID');
    }

    @IsTest
    static void testGetBookingPassengerInfos_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID'))
                .thenThrow(new IRR_SVC_TedsService.TedsException('TEST_TEDS_EXCEPTION'));
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.getBookingPassengerInfos('TEST_BOOKING_ID');
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_TEDS_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @isTest
    static void testGetAdvancedFilterPassengerInfos() {

        //Set up mock
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04'))
                .thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //when
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getAdvancedFilterPassengerInfos(
                'ARN!CPH!2021-03-03!2021-03-04');

        //Then
        System.assertEquals(passengerInfos, passengerResult);
        System.assertEquals(1, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock))
                .getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04');

    }

    @isTest
    static void testGetAdvancedFilterPassengerInfos_Error (){

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_SVC_TedsService.TedsException tedsException = new IRR_SVC_TedsService.TedsException('Integration Response: 404 - Not Found');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04'))
                .thenThrow(tedsException);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
             List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getAdvancedFilterPassengerInfos(
                     'ARN!CPH!2021-03-03!2021-03-04');
        } catch (AuraHandledException ahe) {
                if(ahe.getMessage().contains('Integration Response: 404 - Not Found')) caughtException = true;
                
        }
        //Then
       ((IRR_SVC_ITedsService) mocks.verify(serviceMock))
                .getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04');
        System.assert(caughtException , 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testGetFlightPassengerInfos() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('TEST_FLIGHT_ID')).thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getFlightPassengerInfos(
                'TEST_FLIGHT_ID');

        //Then
        System.assertEquals(passengerInfos, passengerResult);
        System.assertEquals(1, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('TEST_FLIGHT_ID');
    }

    @IsTest
    static void testGetFlightPassengerInfos_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('TEST_FLIGHT_ID')).
                thenThrow(new IRR_SVC_TedsService.TedsException('TEST_TEDS_EXCEPTION'));
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.getFlightPassengerInfos('TEST_FLIGHT_ID');
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_TEDS_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testSendManualCommunication() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService)
                mocks.mock(IRR_SVC_CommunicationServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.passengerInfos = passengerInfos;
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        IRR_CON_ManualCommunication.sendManualCommunication(manualRequest);

        //Then
        ((IRR_SVC_ICommunicationService) mocks.verify(serviceMock)).processEvent('manualCommunication', manualRequest);
    }

    @IsTest
    static void testSendManualCommunication_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService)
                mocks.mock(IRR_SVC_CommunicationServiceImpl.class);

        //Given
        mocks.startStubbing();
        ((IRR_SVC_ICommunicationService) mocks.doThrowWhen(
                    new IRR_SVC_CommunicationService.EventException('TEST_EVENT_EXCEPTION'), serviceMock))
                .processEvent(fflib_Match.anyString(), fflib_Match.isNull());
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.sendManualCommunication(null);
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_EVENT_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testGetManualTemplatesBySendMode() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IManualTemplatesSelector selectorMock = (IRR_SEL_IManualTemplatesSelector)
                mocks.mock(IRR_SEL_ManualTemplatesSelector.class);
        IRR_SEL_IEmailTemplatesSelector etSelectorMock = (IRR_SEL_IEmailTemplatesSelector)
                mocks.mock(IRR_SEL_IEmailTemplatesSelector.class);

        //Given
        List<IRR_ManualCommunicationTemplate__mdt> manualCommunicationTemplates =
                new List<IRR_ManualCommunicationTemplate__mdt>{
                        new IRR_ManualCommunicationTemplate__mdt(
                                MasterLabel = 'TEST_LABEL',
                                DeveloperName = 'TEST_DEV_NAME',
                                IRR_SendMode__c = 'TEST_SEND_MODE',
                                IRR_EmailTemplate__c = 'TEST_EMAIL_TEMPLATE',
                                IRR_SMSTemplate__c = 'TEST_SMS_TEMPLATE'),
                        new IRR_ManualCommunicationTemplate__mdt(
                                MasterLabel = 'OTHER_LABEL',
                                DeveloperName = 'OTHER_DEV_NAME',
                                IRR_SendMode__c = 'OTHER_SEND_MODE',
                                IRR_EmailTemplate__c = 'OTHER_EMAIL_TEMPLATE',
                                IRR_SMSTemplate__c = 'OTHER_SMS_TEMPLATE')
                };
        Map<String, EmailTemplate> emailTemplatesByName = new Map<String, EmailTemplate>{
                'test_sms_template' => new EmailTemplate(Name = 'TEST_SMS_TEMPLATE', HtmlValue = '<html>test</html>'),
                'other_sms_template' => new EmailTemplate(Name = 'OTHER_SMS_TEMPLATE', HtmlValue = '<html>other</html>')
        };
        mocks.startStubbing();
        mocks.when(etSelectorMock.sObjectType()).thenReturn(EmailTemplate.SObjectType);
        mocks.when(etSelectorMock.selectEmailTemplatesByName((Set<String>) fflib_Match.anyObject()))
                .thenReturn(emailTemplatesByName);
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualCommunicationTemplate__mdt.SObjectType);
        mocks.when(selectorMock.selectAllManualCommunicationTemplates()).thenReturn(manualCommunicationTemplates);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Selector.setMock(etSelectorMock);

        //When
        Map<String, List<IRR_CON_ManualCommunication.ManualTemplate>> templateResult =
                IRR_CON_ManualCommunication.getManualTemplatesBySendMode();
        System.debug(JSON.serializePretty(templateResult));

        //Then
        ((IRR_SEL_IManualTemplatesSelector) mocks.verify(selectorMock))
                .selectAllManualCommunicationTemplates();
        ((IRR_SEL_IEmailTemplatesSelector) mocks.verify(etSelectorMock))
                .selectEmailTemplatesByName(new Set<String>{'TEST_SMS_TEMPLATE','OTHER_SMS_TEMPLATE'});
        System.assert(templateResult.containsKey('TEST_SEND_MODE'), 'Result should contain test send mode');
        System.assert(templateResult.containsKey('OTHER_SEND_MODE'), 'Result should contain other send mode');
        System.assertEquals(1, templateResult.get('TEST_SEND_MODE').size());
        System.assertEquals(1, templateResult.get('OTHER_SEND_MODE').size());
        System.assertEquals('TEST_EMAIL_TEMPLATE', templateResult.get('TEST_SEND_MODE')[0].emailTemplate);
        System.assertEquals('OTHER_EMAIL_TEMPLATE', templateResult.get('OTHER_SEND_MODE')[0].emailTemplate);
        System.assertEquals('TEST_LABEL', templateResult.get('TEST_SEND_MODE')[0].templateLabel);
        System.assertEquals('OTHER_LABEL', templateResult.get('OTHER_SEND_MODE')[0].templateLabel);
        System.assertEquals('TEST_DEV_NAME', templateResult.get('TEST_SEND_MODE')[0].templateName);
        System.assertEquals('OTHER_DEV_NAME', templateResult.get('OTHER_SEND_MODE')[0].templateName);
        System.assertEquals('TEST_SMS_TEMPLATE', templateResult.get('TEST_SEND_MODE')[0].smsTemplate);
        System.assertEquals('test', templateResult.get('TEST_SEND_MODE')[0].templatePreview);
        System.assertEquals('OTHER_SMS_TEMPLATE', templateResult.get('OTHER_SEND_MODE')[0].smsTemplate);
        System.assertEquals('other', templateResult.get('OTHER_SEND_MODE')[0].templatePreview);
    }

    @IsTest
    static void testGetManualTemplatesBySendMode_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IManualTemplatesSelector selectorMock = (IRR_SEL_IManualTemplatesSelector)
                mocks.mock(IRR_SEL_ManualTemplatesSelector.class);

        //Given
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualCommunicationTemplate__mdt.SObjectType);
        mocks.when(selectorMock.selectAllManualCommunicationTemplates()).
                thenThrow(new QueryException('TEST_QUERY_EXCEPTION'));
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.getManualTemplatesBySendMode();
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_QUERY_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }
}