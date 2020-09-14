/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-14-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   09-14-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public with sharing class AirportCityNames {
    

    @isTest
    static void testInitiateEventNoPreviousDelay() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IDelayLogsSelector selectorMock = (IRR_SEL_IDelayLogsSelector) mocks.mock(
                IRR_SEL_DelayLogsSelector.class);
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('ARN', 'Stockholm');
        airportInfoMap.put('CPH', 'Copenhagen');
        Map<String, Integer> delayMinutesByFlightIds = new Map<String, Integer>();
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_DelayLog__c.SObjectType);
        mocks.when(selectorMock.getLatestDelayByFlightIds(new Set<String>{'SK1429-20191104-ARN-CPH'}))
                .thenReturn(delayMinutesByFlightIds);
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-ARN-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new List<String>{'ARN','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-ARN-CPH';
        delayInfo.delayedMinutes = 10;
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(3);
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(4);
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now().addHours(5);
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        eventProcessor.initiateEvent();

        //Then
        ((IRR_SEL_IDelayLogsSelector) mocks.verify(selectorMock))
                .getLatestDelayByFlightIds(new Set<String>{'SK1429-20191104-ARN-CPH'});
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('SK1429-20191104-ARN-CPH');
        System.assertEquals(0, delayInfo.previousDelayedMinutes);
        System.assertEquals(10, delayInfo.delayDifference);
        System.assertEquals(10, delayInfo.delayedMinutes);
        System.assertEquals('SK1429', delayInfo.flightRef);
        System.assertEquals('ARN', delayInfo.stationDeparture);
        System.assertEquals('CPH', delayInfo.stationArrival);
        System.assert(delayInfo.firstDelay);
        System.assert(delayInfo.minutesToScheduledTime >= 179 && delayInfo.minutesToScheduledTime < 181);
        System.assertEquals('Stockholm' ,delayInfo.departureCity);
        System.assertEquals('Copenhagen' ,delayInfo.arrivalCity);
    }


}
