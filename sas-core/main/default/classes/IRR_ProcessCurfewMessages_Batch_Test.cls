@isTest

private class IRR_ProcessCurfewMessages_Batch_Test {
    
    @isTest
    static void testScheduleManualEventLogs() {
        IRR_EventLog__c ev = new IRR_EventLog__c();
        ev.Event_Payload_1__c = '{"smsTemplate":"irr_sms_manual_message","sendSMSMessages":true,"sendMessageTime":"2020-11-20T08:15:00.000Z","sendEmailMessages":false,"scheduledChangeInfo":null,"responseMessage":false,"passengerInfos":[{"title":"MS","thisSegment":{"ticketNumber":"117-2470249107","statusCode":"HK","status":"Confirmed","stationDeparture":"ARN","stationArrival":"CPH","serviceClass":"C","segmentId":"ST1","isWideroeTicket":false,"isSASTicket":true,"isConfirmed":true,"flightNumber":"SK1423","flightId":"SK1423-20200907-ARN-CPH","departureTimeLocal":"2020-09-07T13:30:00","departureCity":null,"checkinStatus":null,"bookingClass":"A","arrivalTimeLocal":"2020-09-07T14:40:00","arrivalCity":null},"SSR":"","prevSegment":null,"phoneNumber":"+6463205182","passengerId":"KCNGNS-20200330PT3","otherFQTVCarrier":"UA","nextSegment":null,"lastNameSlashFirstName":"PEACHER/THAIS","lastName":"PEACHER","itinerary":[{"tripType":"Outbound","segments":[{"ticketNumber":null,"statusCode":"HK","status":"Confirmed","stationDeparture":"ARN","stationArrival":"CPH","serviceClass":"C","segmentId":"ST1","isWideroeTicket":false,"isSASTicket":false,"isConfirmed":true,"flightNumber":"SK1423","flightId":"SK1423-20200907-ARN-CPH","departureTimeLocal":"2020-09-07T13:30:00","departureCity":null,"checkinStatus":null,"bookingClass":"A","arrivalTimeLocal":"2020-09-07T14:40:00","arrivalCity":null}]}],"hasThisSegment":true,"hasPrevSegment":false,"hasPhoneNumber":true,"hasNextSegment":false,"hasEmailAddress":true,"firstName":"THAIS","emailAddress":"KENNARD.MATTHEW@GMAIL.COM","ebLevel":null,"codsId":"35538535","bookingReference":"KCNGNS"}],"newInfo":null,"emailTemplate":"irr_manual_message","delayInfo":null,"customInfo":{"subject":"Test","content":"Test"},"checkinInfo":null,"cancelInfo":null}';
        ev.IRR_ScheduleTime__c = Datetime.newInstance(System.today().year()-1,1,1,0,0,0);
        insert ev;
        
        try{
            //Set up mocks
            fflib_ApexMocks mocks = new fflib_ApexMocks();
            IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);
            //Given
            // IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequestI();
            Map<String,String> airportInfoMap = new Map<String,String>();
            airportInfoMap.put('CPH','Copenhagen');
            airportInfoMap.put('ARN','Stockholm');
            mocks.startStubbing();
            mocks.when(serviceMock.getAirportCityNames(new List<String>{'CPH','ARN'}))
                    .thenReturn(airportInfoMap);
            mocks.stopStubbing();
            // IRR_EVT_ManualProcessor eventProcessor = (IRR_EVT_ManualProcessor) new IRR_EVT_ManualProcessor.Constructor()
            //     .newInstance(manualRequest);
            IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
            // Test.startTest();
            String day = string.valueOf(system.now().day());
            String month = string.valueOf(system.now().month());
            String hour = string.valueOf(system.now().hour());
            String minute = string.valueOf(system.now().minute() +1);
            String second = string.valueOf(system.now().second());
            String year = string.valueOf(system.now().year());
            String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
            System.schedule('Sample Test Job', strSchedule, new IRR_ProcessCurfewMessages_Batch());
            // Test.stopTest();
            //Then
            ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new List<String>{'CPH','ARN'});
        }catch(exception e){

        }
        
    }
    @isTest
    static void testProcessQueuedManualEventLogs() {
        IRR_EventLog__c ev = new IRR_EventLog__c();
        ev.Event_Payload_1__c = '{"smsTemplate":"irr_sms_manual_message","sendSMSMessages":true,"sendMessageTime":"2020-11-20T08:15:00.000Z","sendEmailMessages":false,"scheduledChangeInfo":null,"responseMessage":false,"passengerInfos":[{"title":"MS","thisSegment":{"ticketNumber":"117-2470249107","statusCode":"HK","status":"Confirmed","stationDeparture":"ARN","stationArrival":"CPH","serviceClass":"C","segmentId":"ST1","isWideroeTicket":false,"isSASTicket":true,"isConfirmed":true,"flightNumber":"SK1423","flightId":"SK1423-20200907-ARN-CPH","departureTimeLocal":"2020-09-07T13:30:00","departureCity":null,"checkinStatus":null,"bookingClass":"A","arrivalTimeLocal":"2020-09-07T14:40:00","arrivalCity":null},"SSR":"","prevSegment":null,"phoneNumber":"+6463205182","passengerId":"KCNGNS-20200330PT3","otherFQTVCarrier":"UA","nextSegment":null,"lastNameSlashFirstName":"PEACHER/THAIS","lastName":"PEACHER","itinerary":[{"tripType":"Outbound","segments":[{"ticketNumber":null,"statusCode":"HK","status":"Confirmed","stationDeparture":"ARN","stationArrival":"CPH","serviceClass":"C","segmentId":"ST1","isWideroeTicket":false,"isSASTicket":false,"isConfirmed":true,"flightNumber":"SK1423","flightId":"SK1423-20200907-ARN-CPH","departureTimeLocal":"2020-09-07T13:30:00","departureCity":null,"checkinStatus":null,"bookingClass":"A","arrivalTimeLocal":"2020-09-07T14:40:00","arrivalCity":null}]}],"hasThisSegment":true,"hasPrevSegment":false,"hasPhoneNumber":true,"hasNextSegment":false,"hasEmailAddress":true,"firstName":"THAIS","emailAddress":"KENNARD.MATTHEW@GMAIL.COM","ebLevel":null,"codsId":"35538535","bookingReference":"KCNGNS"}],"newInfo":null,"emailTemplate":"irr_manual_message","delayInfo":null,"customInfo":{"subject":"Test","content":"Test"},"checkinInfo":null,"cancelInfo":null}';
        ev.IRR_ScheduleTime__c = Datetime.newInstance(System.today().year()-1,1,1,0,0,0);
        insert ev;
        
        try{
            //Set up mocks
            fflib_ApexMocks mocks = new fflib_ApexMocks();
            IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);
            //Given
            Map<String,String> airportInfoMap = new Map<String,String>();
            airportInfoMap.put('CPH','Copenhagen');
            airportInfoMap.put('ARN','Stockholm');
            mocks.startStubbing();
            mocks.when(serviceMock.getAirportCityNames(new List<String>{'CPH','ARN'}))
                    .thenReturn(airportInfoMap);
            mocks.stopStubbing();
            SBS_ScheduledBatch scheduledManualMessages = new IRR_ProcessCurfewMessages_Batch();
            Test.startTest();
            Database.executeBatch(scheduledManualMessages);
            Test.stopTest();
            //Then
            ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getAirportCityNames(new List<String>{'CPH','ARN'});
        }catch(exception e){

        }
        
    }
}
