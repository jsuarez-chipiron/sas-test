/**
* @author Gaurav Singh, CoforgeTech
* @date 2022
*
* @description unit tests for Scheduled Icoupon communication batch
*/
@isTest

public with sharing class IRR_BCH_Scheduled_IcouponEvent_Test {
    @isTest
    static void testProcessIcouponEventLogs() {
             //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IDelayLogsSelector selectorMock = (IRR_SEL_IDelayLogsSelector) mocks.mock(
                IRR_SEL_DelayLogsSelector.class);
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        Map<String, Integer> delayMinutesByFlightIds = new Map<String, Integer>();
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_DelayLog__c.SObjectType);
        mocks.when(selectorMock.getLatestDelayByFlightIds(new Set<String>{'SK1429-20191104-ARN-CPH'}))
                .thenReturn(delayMinutesByFlightIds);
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new Set<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
        delayInfo.delayedMinutes = 10;
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(3);
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(4);
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now().addHours(5);
        delayInfo.stationArrival='CPH';
        delayInfo.stationDeparture='ARN';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
            //Given
            IRR_EventLog__c eventLogs = new IRR_EventLog__c();
            eventLogs.IRR_ScheduleTime__c = System.Now().addHours(1);
            eventLogs.IRR_FlightId__c ='SK1429-20191104-ARN-CPH' ;
            eventLogs.IRR_Event_Type__c = 'ICOUPON';
            eventLogs.IRR_Delayed_Minutes__c = 70;
            eventLogs.IRR_Station_Departure__c = 'ARN';
            eventLogs.IRR_Flight_Ref__c = 'SK1429';
            eventLogs.Is_Communication_Send__c = false;

            insert eventLogs;
        
            
            //When
            SBS_ScheduledBatch scheduledIcouponMessages = new IRR_BCH_Scheduled_IcouponEvent();
            //Then
            Test.startTest();
            IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
            Database.executeBatch(scheduledIcouponMessages);
            Test.stopTest();

    }
}