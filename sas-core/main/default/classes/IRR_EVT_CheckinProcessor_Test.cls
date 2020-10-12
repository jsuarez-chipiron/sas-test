/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
* @description Test class for the CheckinProcessor class, also covers parts of EventProcessor abstract class.
*/

@IsTest
private class IRR_EVT_CheckinProcessor_Test {

    @IsTest
    static void testInitiateEvent_Object() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();

        //When
        Object result = IRR_Application.EventProcessor.newInstance('flightCheckInOpen', checkinInfo);

        //Then
        System.assert(result instanceof IRR_EVT_CheckinProcessor, 'Expected result of type CheckinProcessor');
    }

    @IsTest
    static void testInitiateEvent_JSON() {
        //Given
        String jsonPayload = '{}';

        //When
        Object result = IRR_Application.EventProcessor.newInstance('flightCheckInOpen', jsonPayload);

        //Then
        System.assert(result instanceof IRR_EVT_CheckinProcessor, 'Expected result of type CheckinProcessor');
    }

    @IsTest
    static void testGetEventName() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        IRR_EVT_CheckinProcessor checkinProcessor = (IRR_EVT_CheckinProcessor)
                new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);


        //When
        String eventName = checkinProcessor.getEventName();

        //Then
        System.assertEquals('Checkin', eventName);
    }

    @IsTest
    static void testValidateEvent_Success() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.flightId = 'TEST_FLIGHT_ID';
        checkinInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        checkinInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);

        //When
        eventProcessor.validateEvent();
    }

    @IsTest
    static void testValidateEvent_ThrowsNoFlightId() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        checkinInfo.scheduledTimeOfDepartureLocal = Datetime.now();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Flight Id is missing from event')) caughtException = true;
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testValidateEvent_ThrowsNoScheduledTime() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.flightId = 'TEST_FLIGHT_ID';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);

        //When
        Boolean caughtException = false;
        try {
            eventProcessor.validateEvent();
        }
        catch (IRR_SVC_CommunicationService.EventException eventException) {
            if (eventException.getMessage().contains('Scheduled time of departure is missing from event')){
                caughtException = true;
            }
        }

        //Then
        System.assert(caughtException);
    }

    @IsTest
    static void testInitiateEventNoCheckinCurfew() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.eventTime = Datetime.now();
        checkinInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        checkinInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(2);
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new List<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        checkinInfo.flightId = 'SK1429-20191104-ARN-CPH';
        checkinInfo.scheduledTimeOfDepartureUTC = Datetime.now();
        checkinInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(2);
        checkinInfo.stationArrival='CPH';
        checkinInfo.stationDeparture='ARN';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('SK1429-20191104-ARN-CPH');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new List<String>{'ARN','CPH'});

        System.assertEquals('SK1429', checkinInfo.flightRef);
        System.assertEquals('ARN', checkinInfo.stationDeparture);
        System.assertEquals('CPH', checkinInfo.stationArrival);
        System.assertEquals('Copenhagen' ,airportInfoMap.get(checkinInfo.stationArrival));
        System.assertEquals('Stockholm' ,airportInfoMap.get(checkinInfo.stationDeparture));
    }

    @IsTest
    static void testInitiateEventWithCheckinCurfew() {

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock =  (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_ITedsService.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new List<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.flightId = 'TEST_FLIGHT_ID';
        checkinInfo.eventTime = DateTime.newInstancegmt(Date.today(),Time.newInstance(22,0,0,0));
        checkinInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(2);
        checkinInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(3);
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock,0)).getPassengerInfosForFlight('SK1429-20191104-ARN-CPH');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock,0)).getAirportCityNames(new List<String>{'ARN','CPH'});
    }

    @IsTest
    static void testCheckActiveBlock_Queued() {

        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_CheckinProcessor.Constructor().newInstance(checkinInfo);

        //When
        Boolean result = eventProcessor.checkActiveBlock();

        //Then
        System.assertEquals(false, result);
    }

//     @IsTest
//     static void testCheckActiveBlock_NotQueued() {
//         //Set up mocks
//         fflib_ApexMocks mocks = new fflib_ApexMocks();
//         IRR_SEL_IManualOverridesSelector selectorMock = (IRR_SEL_IManualOverridesSelector) mocks.mock(
//                 IRR_SEL_ManualOverridesSelector.class);

//         //Given
//         mocks.startStubbing();
//         mocks.when(selectorMock.selectActiveManualOverridesByFlightId(fflib_Match.anyString()))
//                 .thenReturn(new List<IRR_ManualOverride__c>());
//         mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualOverride__c.SObjectType);
//         mocks.stopStubbing();
//         IRR_Application.Selector.setMock(selectorMock);
//         IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
//         delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
//         IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);

//         //When
//         Boolean result = eventProcessor.checkActiveBlock();

//         //Then
//         ((IRR_SEL_IManualOverridesSelector) mocks.verify(selectorMock))
//                 .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');
//         System.assertEquals(false, result);
//     }

    @IsTest
    static void testProcessEventCloseToDeparture_Confirmed_SendSMS() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();

        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_CheckinProcessor eventProcessor = (IRR_EVT_CheckinProcessor) new IRR_EVT_CheckinProcessor.Constructor()
                .newInstance(checkinInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(1, messages.size());
        System.assertEquals('irr_checkin_sms_01', messages[0].template);
        System.assertEquals('Checkin', messages[0].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(messages[0].recipient, 'TEST_PHONE');
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('checkinInfo'));
    }

    @IsTest
    static void testProcessEventCloseToDeparture_Confirmed_SendSMS_NoPhone() {
        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = false;
        passengerInfos[0].phoneNumber = null;
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        IRR_EVT_CheckinProcessor eventProcessor = (IRR_EVT_CheckinProcessor) new IRR_EVT_CheckinProcessor.Constructor()
                .newInstance(checkinInfo);
        eventProcessor.passengerInfos = passengerInfos;

        //When
        eventProcessor.processEvent();

        //Then
        List<IRR_MOD_Message> messages = eventProcessor.messages;
        System.assertEquals(1, messages.size());
        System.assertEquals('irr_checkin_sms_01', messages[0].template);
        System.assertEquals('Checkin', messages[0].type);
        System.assertEquals(passengerInfos[0], messages[0].passengerInfo);
        System.assertEquals(null, messages[0].recipient);
        System.assertEquals(IRR_MOD_Message.MessageChannel.SMS, messages[0].channel);
        System.assert(messages[0].variables.containsKey('passengerInfo') &&
                messages[0].variables.containsKey('checkinInfo'));
    }

    @IsTest
    static void testFinalizeEvent_NotQueued() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        //Given
        IRR_SVC_SFMCService.SMSMessage smsMessage = new IRR_SVC_SFMCService.SMSMessage(null, null, null);
        smsMessage.messageKey = 'TEST_MESSAGE_KEY';
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.flightId = 'TEST_FLIGHT_ID';
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.lastNameSlashFirstName = 'TEST_LAST_NAME/TEST_FIRST_NAME';
        passengerInfo.phoneNumber = 'TEST_PHONE';
        passengerInfo.emailAddress = 'TEST_EMAIL';
        passengerInfo.codsId = 'TEST_CODS_ID';
        passengerInfo.thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfo.thisSegment.flightId = 'TEST_FLIGHT_ID';
        passengerInfo.bookingReference = 'TEST_BOOKING_REFERENCE';
        IRR_EVT_CheckinProcessor eventProcessor = (IRR_EVT_CheckinProcessor) new IRR_EVT_CheckinProcessor.Constructor()
                .newInstance(checkinInfo);
        IRR_MOD_Message message = new IRR_MOD_Message('TEST_STATUS', IRR_MOD_Message.MessageChannel.SMS, null, null,
                passengerInfo, 'TEST_TYPE', false);
        message.SFMCMessage = smsMessage;
        eventProcessor.messages.add(message);
        eventProcessor.isQueued = false;

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
                IRR_CommunicationLog__c.IRR_RecipientName__c => 'TEST_LAST_NAME/TEST_FIRST_NAME'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_CommunicationLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(cLogMatcher));
        Map<SObjectField, Object> eLogMatcher = new Map<SObjectField, Object>{
                IRR_EventLog__c.IRR_FlightId__c => 'TEST_FLIGHT_ID'
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock,0))
                .registerNew(fflib_Match.sObjectOfType(IRR_EventLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock,0)).registerNew(fflib_Match.sObjectWith(eLogMatcher));
    }


    @IsTest
    static void testFinalizeEvent_Queued() {
        //Set up mock implementation of UnitOfWork
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        //Given
        IRR_MOD_CheckinInfo checkinInfo = new IRR_MOD_CheckinInfo();
        checkinInfo.flightId = 'TEST_FLIGHT_ID';
        checkinInfo.eventTime = DateTime.newInstancegmt(Date.today(),Time.newInstance(22,0,0,0));
        checkinInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(2);
        checkinInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(3);
        IRR_EVT_CheckinProcessor eventProcessor = (IRR_EVT_CheckinProcessor) new IRR_EVT_CheckinProcessor.Constructor()
                .newInstance(checkinInfo);
        eventProcessor.isQueued = true;
        IRR_Application.unitOfWork.setMock(uowMock);


        // When method invoked
        eventProcessor.finalizeEvent(uowMock);

        // Then verify new SObjects were created
        Map<SObjectField, Object> eLogMatcher = new Map<SObjectField, Object>{
                IRR_EventLog__c.IRR_FlightId__c => 'TEST_FLIGHT_ID'
                // checkinInfo.eventTime => DateTime.newInstancegmt(Date.today(),Time.newInstance(22,0,0,0))
        };
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock,0))
                .registerNew(fflib_Match.sObjectOfType(IRR_CommunicationLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(fflib_Match.sObjectOfType(IRR_EventLog__c.SObjectType));
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).registerNew(fflib_Match.sObjectWith(eLogMatcher));
         System.assertEquals('TEST_FLIGHT_ID', eLogMatcher.get(IRR_EventLog__c.IRR_FlightId__c));
    }

    @IsTest
    static void testFinalizeEvent_NoMessage() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);

        //Given
        IRR_EVT_CheckinProcessor eventProcessor = (IRR_EVT_CheckinProcessor) new IRR_EVT_CheckinProcessor.Constructor()
                .newInstance(null);

        //When
        eventProcessor.finalizeEvent(uowMock);

        //Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 0))
                .registerNew(fflib_Match.anySObject());
    }

}