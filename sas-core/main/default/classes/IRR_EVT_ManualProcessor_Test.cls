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
        catch (IRR_SVC_EventService.EventException eventException) {
            if (eventException.getMessage().contains('Manual message info is missing')) caughtException = true;
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
        catch (IRR_SVC_EventService.EventException eventException) {
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
        catch (IRR_SVC_EventService.EventException eventException) {
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
        catch (IRR_SVC_EventService.EventException eventException) {
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
        catch (IRR_SVC_EventService.EventException eventException) {
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
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualRequest);

        //When
        eventProcessor.initiateEvent();

        //Then
        System.assertEquals(false, eventProcessor.manualRequest.sendEmailMessages);
        System.assertEquals(false, eventProcessor.manualRequest.sendSMSMessages);
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
    static void testProcessEvent_SendMessages() {
        //Given
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.flowVariables = new IRR_MOD_FlowVariables();
        manualRequest.flowVariables.delayInfo = new IRR_MOD_DelayInfo();
        manualRequest.emailTemplate = 'EMAIL_TEMPLATE';
        manualRequest.smsTemplate = 'SMS_TEMPLATE';
        manualRequest.sendSMSMessages = true;
        manualRequest.sendEmailMessages = true;
        manualRequest.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        manualRequest.passengerInfos[0].hasPhoneNumber = true;
        manualRequest.passengerInfos[0].phoneNumber = 'TEST_PHONE';
        manualRequest.passengerInfos[0].hasEmailAddress = true;
        manualRequest.passengerInfos[0].emailAddress = 'TEST_EMAIL';
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
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('delayInfo')); //TODO ADD OTHER EVENTS
    }
}