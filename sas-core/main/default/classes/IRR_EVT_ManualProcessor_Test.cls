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
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.emailTemplate = 'EMAIL_TEMPLATE';
        manualInfo.smsTemplate = 'SMS_TEMPLATE';
        manualInfo.sendSMSMessages = true;
        manualInfo.sendEmailMessages = true;
        manualInfo.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualInfo);

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
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.emailTemplate = 'EMAIL_TEMPLATE';
        manualInfo.smsTemplate = 'SMS_TEMPLATE';
        manualInfo.sendSMSMessages = true;
        manualInfo.sendEmailMessages = true;
        manualInfo.passengerInfos = null;
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualInfo);

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
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.emailTemplate = null;
        manualInfo.sendSMSMessages = true;
        manualInfo.smsTemplate = 'SMS_TEMPLATE';
        manualInfo.sendEmailMessages = true;
        manualInfo.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualInfo);

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
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.emailTemplate = 'EMAIL_TEMPLATE';
        manualInfo.sendSMSMessages = true;
        manualInfo.smsTemplate = null;
        manualInfo.sendEmailMessages = true;
        manualInfo.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualInfo);

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
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.sendSMSMessages = false;
        manualInfo.sendEmailMessages = false;
        manualInfo.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_ManualProcessor.Constructor().newInstance(manualInfo);

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
    static void testInitiateEvent() {
        //Given
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.sendSMSMessages = null;
        manualInfo.sendEmailMessages = null;
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualInfo);

        //When
        eventProcessor.initiateEvent();

        //Then
        System.assertEquals(false, eventProcessor.manualInfo.sendEmailMessages);
        System.assertEquals(false, eventProcessor.manualInfo.sendSMSMessages);
    }

    @IsTest
    static void testProcessEvent_SendMessages() {
        //Given
        IRR_MOD_ManualInfo manualInfo = new IRR_MOD_ManualInfo();
        manualInfo.flowVariables = new IRR_MOD_FlowVariables();
        manualInfo.flowVariables.delayInfo = new IRR_MOD_DelayInfo();
        manualInfo.emailTemplate = 'EMAIL_TEMPLATE';
        manualInfo.smsTemplate = 'SMS_TEMPLATE';
        manualInfo.sendSMSMessages = true;
        manualInfo.sendEmailMessages = true;
        manualInfo.passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        manualInfo.passengerInfos[0].hasPhoneNumber = true;
        manualInfo.passengerInfos[0].phoneNumber = 'TEST_PHONE';
        manualInfo.passengerInfos[0].hasEmailAddress = true;
        manualInfo.passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_ManualProcessor eventProcessor = new IRR_EVT_ManualProcessor(manualInfo);

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(2, messages.size());
        System.assertEquals('SMS_TEMPLATE', messages[0].template);
        System.assertEquals('EMAIL_TEMPLATE', messages[1].template);
        System.assertEquals('Manual', messages[0].type);
        System.assertEquals('Manual', messages[1].type);
        System.assertEquals(manualInfo.passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(manualInfo.passengerInfos[0], messages[1].passengerInfo);
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