/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Unit test class for manual message event.
*/

@IsTest
private class IRR_EVT_ManualProcessor_Test {

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_EVT_ManualProcessor manualProcessor = (IRR_EVT_ManualProcessor)
                new IRR_EVT_ManualProcessor.Constructor().newInstance(null);


        //When
        String eventName = manualProcessor.getEventName();

        //Then
        System.assertEquals('Manual', eventName);
    }

    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.emailTemplate = 'EMAIL_TEMPLATE';
        manualRequest.smsTemplate = 'SMS_TEMPLATE';
        manualRequest.sendSMSMessages = true;
        manualRequest.sendEmailMessages = true;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualRequest);

        //When
        eventProcessor.validateEvent();
    }

    @IsTest
    static void testValidateEvent_NullEvent_Throws() {
        //Given
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(null);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Manual message request is missing')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_NoPassengers_Throws() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.emailTemplate = 'EMAIL_TEMPLATE';
        manualRequest.smsTemplate = 'SMS_TEMPLATE';
        manualRequest.sendSMSMessages = true;
        manualRequest.sendEmailMessages = true;
        manualRequest.passengerInfos = null;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('No passengers to send message to')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_NoEmailTemplate_Throws() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.emailTemplate = null;
        manualRequest.sendSMSMessages = true;
        manualRequest.smsTemplate = 'SMS_TEMPLATE';
        manualRequest.sendEmailMessages = true;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('No Email template selected')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_NoSMSTemplate_Throws() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.emailTemplate = 'EMAIL_TEMPLATE';
        manualRequest.sendSMSMessages = true;
        manualRequest.smsTemplate = null;
        manualRequest.sendEmailMessages = true;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('No SMS template selected')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_NoMessageToSend_Throws() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.sendSMSMessages = false;
        manualRequest.sendEmailMessages = false;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualRequest);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('There is no message to send')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testInitiateEvent_NoEventInfo() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.sendSMSMessages = null;
        manualRequest.sendEmailMessages = null;
        manualRequest.responseMessage = null;
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualRequest);

        //When
        eventProcessor.initiateEvent();

        //Then
        System.assertEquals(false, eventProcessor.manualRequest.sendEmailMessages);
        System.assertEquals(false, eventProcessor.manualRequest.sendSMSMessages);
        System.assertEquals(false, eventProcessor.manualRequest.responseMessage);
    }

    @IsTest
    static void testInitiateEvent_DelayEvent() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.sendSMSMessages = true;
        manualRequest.sendEmailMessages = false;
        manualRequest.delayInfo = new IRR_MOD_DelayInfo();
        manualRequest.delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualRequest);

        //When
        eventProcessor.initiateEvent();

        //Then
        System.assertEquals('SK1429', manualRequest.delayInfo.flightRef);
        System.assertEquals('ARN', manualRequest.delayInfo.stationDeparture);
        System.assertEquals('CPH', manualRequest.delayInfo.stationArrival);
    }

    @IsTest
    static void testProcessEvent_SendMessages_NoResponse() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.flowVariables = new IRR_MOD_FlowVariables();
        manualRequest.flowVariables.delayInfo = new IRR_MOD_DelayInfo();
        manualRequest.emailTemplate = 'EMAIL_TEMPLATE';
        manualRequest.smsTemplate = 'SMS_TEMPLATE';
        manualRequest.sendSMSMessages = true;
        manualRequest.sendEmailMessages = true;
        manualRequest.responseMessage = false;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        manualRequest.passengerInfos[0].hasPhoneNumber = true;
        manualRequest.passengerInfos[0].phoneNumber = 'TEST_PHONE';
        manualRequest.passengerInfos[0].hasEmailAddress = true;
        manualRequest.passengerInfos[0].emailAddress = 'TEST_EMAIL';
        manualRequest.customInfo = new IRR_MOD_CustomInfo();
        manualRequest.customInfo.subject = 'TEST_SUBJECT';
        manualRequest.customInfo.content = 'TEST_CONTENT';
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualRequest);

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(2, messages.size());
        System.assertEquals('SMS_TEMPLATE', messages[0].template);
        System.assertEquals('EMAIL_TEMPLATE', messages[1].template);
        System.assertEquals('Manual', messages[0].type);
        System.assertEquals('Manual', messages[1].type);
        System.assertEquals(manualRequest.passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(manualRequest.passengerInfos[0], messages[1].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(messages[1].recipient, 'TEST_EMAIL');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assertEquals(IRR_MOD_Message.MessageChannel.Email, messages[1].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('delayInfo')); //TODO ADD OTHER EVENTS
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('customInfo'));
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('delayInfo')); //TODO ADD OTHER EVENTS
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('customInfo'));
        System.assert(!messages[0].responseMessage, 'Message 1 Response not expected');
        System.assert(!messages[1].responseMessage, 'Message 2 Response not expected');
    }

    @IsTest
    static void testProcessEvent_SendMessages_Response() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.flowVariables = new IRR_MOD_FlowVariables();
        manualRequest.flowVariables.delayInfo = new IRR_MOD_DelayInfo();
        manualRequest.emailTemplate = 'EMAIL_TEMPLATE';
        manualRequest.smsTemplate = 'SMS_TEMPLATE';
        manualRequest.sendSMSMessages = true;
        manualRequest.sendEmailMessages = true;
        manualRequest.responseMessage = true;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        manualRequest.passengerInfos[0].hasPhoneNumber = true;
        manualRequest.passengerInfos[0].phoneNumber = 'TEST_PHONE';
        manualRequest.passengerInfos[0].hasEmailAddress = true;
        manualRequest.passengerInfos[0].emailAddress = 'TEST_EMAIL';
        manualRequest.customInfo = new IRR_MOD_CustomInfo();
        manualRequest.customInfo.subject = 'TEST_SUBJECT';
        manualRequest.customInfo.content = 'TEST_CONTENT';
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualRequest);

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(2, messages.size());
        System.assert(messages[0].responseMessage, 'Message 1 Response not expected');
        System.assert(messages[1].responseMessage, 'Message 2 Response not expected');
    }



    @IsTest
    static void testFinalizeEvent_MessageResponse() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        //Given
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(null, null, null);
        smsMessage.messageKey = 'TEST_MESSAGE_KEY';
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.lastNameSlashFirstName = 'TEST_LAST_NAME/TEST_FIRST_NAME';
        passengerInfo.phoneNumber = 'TEST_PHONE';
        passengerInfo.emailAddress = 'TEST_EMAIL';
        passengerInfo.codsId = 'TEST_CODS_ID';
        passengerInfo.thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfo.thisSegment.flightId = 'TEST_FLIGHT_ID';
        passengerInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_EVT_ManualProcessor eventProcessor = (IRR_EVT_ManualProcessor) new IRR_EVT_ManualProcessor.Constructor()
                .newInstance(null);
        IRR_MOD_Message message = new IRR_MOD_Message('TEST_STATUS', IRR_MOD_Message.MessageChannel.SMS, null, null,
                passengerInfo, 'TEST_TYPE', true);
        message.SFMCMessage = smsMessage;
        eventProcessor.messages.add(message);

        //When
        eventProcessor.finalizeEvent(uowMock);

        //Then
        Map<SObjectField, Object> cLogMatcher = new Map<SObjectField, Object>{
                IRR_CommunicationLog__c.IRR_FlightId__c => 'TEST_FLIGHT_ID',
                IRR_CommunicationLog__c.IRR_BookingReference__c => 'TEST_BOOKING_REFERENCE',
                IRR_CommunicationLog__c.IRR_CodsId__c => 'TEST_CODS_ID',
                IRR_CommunicationLog__c.IRR_Channel__c => 'SMS',
                IRR_CommunicationLog__c.IRR_ContactKey__c => 'TEST_EMAIL',
                IRR_CommunicationLog__c.IRR_MessageKey__c => 'TEST_MESSAGE_KEY',
                IRR_CommunicationLog__c.IRR_Recipient__c => 'TEST_PHONE',
                IRR_CommunicationLog__c.IRR_Status__c => 'TEST_STATUS',
                IRR_CommunicationLog__c.IRR_RecipientName__c => 'TEST_LAST_NAME/TEST_FIRST_NAME',
                IRR_CommunicationLog__c.IRR_ResponseMessage__c => true
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_CommunicationLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(cLogMatcher));
    }



    @IsTest
    static void testFinalizeEvent_NoMessage() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        //Given
        IRR_EVT_ManualProcessor eventProcessor = (IRR_EVT_ManualProcessor) new IRR_EVT_ManualProcessor.Constructor()
                .newInstance(null);

        //When
        eventProcessor.finalizeEvent(uowMock);

        //Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 0))
                .registerNew(fflib_Match.anySObject());
    }
}