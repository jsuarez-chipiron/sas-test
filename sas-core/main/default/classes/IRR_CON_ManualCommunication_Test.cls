/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
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

        //Given
        List<IRR_ManualCommunicationTemplate__mdt> manualCommunicationTemplates =
                new List<IRR_ManualCommunicationTemplate__mdt>{
                        new IRR_ManualCommunicationTemplate__mdt(
                                IRR_SendMode__c = 'TEST_SEND_MODE',
                                IRR_EmailTemplate__c = 'TEST_EMAIL_TEMPLATE',
                                IRR_SMSTemplate__c = 'TEST_SMS_TEMPLATE'),
                        new IRR_ManualCommunicationTemplate__mdt(
                                IRR_SendMode__c = 'OTHER_SEND_MODE',
                                IRR_EmailTemplate__c = 'OTHER_EMAIL_TEMPLATE',
                                IRR_SMSTemplate__c = 'OTHER_SMS_TEMPLATE')
                };
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualCommunicationTemplate__mdt.SObjectType);
        mocks.when(selectorMock.selectAllManualCommunicationTemplates()).thenReturn(manualCommunicationTemplates);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);

        //When
        Map<String, List<IRR_ManualCommunicationTemplate__mdt>> templateResult =
                IRR_CON_ManualCommunication.getManualTemplatesBySendMode();

        //Then
        ((IRR_SEL_IManualTemplatesSelector) mocks.verify(selectorMock))
                .selectAllManualCommunicationTemplates();
        System.assert(templateResult.containsKey('TEST_SEND_MODE'), 'Result should contain test send mode');
        System.assert(templateResult.containsKey('OTHER_SEND_MODE'), 'Result should contain other send mode');
        System.assertEquals(1, templateResult.get('TEST_SEND_MODE').size());
        System.assertEquals(1, templateResult.get('OTHER_SEND_MODE').size());
        System.assertEquals('TEST_EMAIL_TEMPLATE', templateResult.get('TEST_SEND_MODE')[0].IRR_EmailTemplate__c);
        System.assertEquals('OTHER_EMAIL_TEMPLATE', templateResult.get('OTHER_SEND_MODE')[0].IRR_EmailTemplate__c);
        System.assertEquals('TEST_SMS_TEMPLATE', templateResult.get('TEST_SEND_MODE')[0].IRR_SMSTemplate__c);
        System.assertEquals('OTHER_SMS_TEMPLATE', templateResult.get('OTHER_SEND_MODE')[0].IRR_SMSTemplate__c);
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