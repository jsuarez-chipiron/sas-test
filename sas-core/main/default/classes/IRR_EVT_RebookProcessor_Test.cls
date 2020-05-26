/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

@IsTest
private class IRR_EVT_RebookProcessor_Test {

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        IRR_EVT_RebookProcessor rebookProcessor = (IRR_EVT_RebookProcessor)
                new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        String eventName = rebookProcessor.getEventName();

        //Then
        System.assertEquals('Rebook', eventName);
    }


    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.bookingId = 'TEST_BOOKING_ID';
        rebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        rebookInfo.eventTime = Datetime.now();
        rebookInfo.source = 'TEST_SOURCE';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        eventProcessor.validateEvent();

        //Then
        System.assert(true);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoBookingRef() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.bookingId = 'TEST_BOOKING_ID';
        rebookInfo.eventTime = Datetime.now();
        rebookInfo.source = 'TEST_SOURCE';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Booking Ref is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoSource() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.bookingId = 'TEST_BOOKING_ID';
        rebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        rebookInfo.eventTime = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Source is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoEventTime() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.bookingId = 'TEST_BOOKING_ID';
        rebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        rebookInfo.source = 'TEST_SOURCE';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Event time is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testValidateEvent_ThrowsNoBookingId() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        rebookInfo.eventTime = Datetime.now();
        rebookInfo.source = 'TEST_SOURCE';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Booking Id is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }


    @IsTest
    static void testInitiateEvent() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID'))
                .thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.bookingId = 'TEST_BOOKING_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
    }

    @IsTest
    static void testCheckActiveBlock() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_RebookProcessor.Constructor().newInstance(rebookInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        System.assertEquals(false, result);
    }

    @IsTest
    static void testProcessEventSASDisruption_Confirmed_SendSMSEmail() {
        //Given
        IRR_MOD_RebookInfo rebookInfo = new IRR_MOD_RebookInfo();
        rebookInfo.source = 'SASDisruption';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_RebookProcessor eventProcessor = (IRR_EVT_RebookProcessor) new IRR_EVT_RebookProcessor.Constructor()
                .newInstance(rebookInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(2, messages.size());
        System.assertEquals('irr_rebooking_sms_01', messages[0].template);
        System.assertEquals('irr_rebooking_email_01', messages[1].template);
        System.assertEquals('Rebook', messages[0].type);
        System.assertEquals('Rebook', messages[1].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(passengerInfos[0], messages[1].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(messages[1].recipient, 'TEST_EMAIL');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assertEquals(IRR_MOD_Message.MessageChannel.Email, messages[1].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('rebookInfo'));
        System.assert(messages[1].variables.containsKey('passengerInfo') &&
                messages[1].variables.containsKey('rebookInfo'));
    }
}