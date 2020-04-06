/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for Teds Service.
*/

@IsTest
private class IRR_SVC_TedsService_Test {

    @IsTest
    static void testGetPassengerInfosForFlight() {
        String jsonResponse = '[{"id":"P2WNNO-20200205","reference":"P2WNNO","type":"ReturnTrip","status":"Active","codsId":"ABC1234","audit":{"created":{"officeId":"STOSK08RV","at":"2020-02-05T17:32:28Z"},"updated":{"officeId":"STOSK08RV","at":"2017-02-12T17:32:28Z"}},"passengers":[{"id":"P2WNNO-01","title":"MR","firstName":"Sam","lastName":"Milley","type":"Adult","contact":{"phone":[{"type":"CTCM","number":"+46701234567"}],"email":[{"type":"CTCE","address":"name@email.com"}]},"frequentTraveler":{"carrier":"SK","tier":"G","number":"128054392"},"segments":[{"segmentId":"P2WNNO-O-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-02","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-03","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-04","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-I-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true}]}],"trips":[{"id":"P2WNNO-O-01","type":"Outbound","segments":[{"id":"P2WNNO-O-01-01","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"SK0946-20200211-ORD-ARN","operatingCarrier":"SK","operatingFlightNumber":"0946","marketingCarrier":"SK","marketingFlightNumber":"0946","departure":{"station":"ORD","terminal":"2","scheduledTime":{"local":"2020-02-11T16:00:00Z","utc":"2020-02-12T00:00:00Z"}},"arrival":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T07:25:00Z","utc":"2020-02-12T06:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"TX7ZK8-O-01-02","transportationType":"Flight","statusCode":"UN","status":"Cancelled","flight":{"id":"SK0579-20200212-ARN-CDG","operatingCarrier":"SK","operatingFlightNumber":"0579","marketingCarrier":"SK","marketingFlightNumber":"0579","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T16:10:00Z","utc":"2020-02-12T15:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T18:45:00Z","utc":"2020-02-12T17:45:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK1407-20200212-ARN-CPH","operatingCarrier":"SK","operatingFlightNumber":"1407","marketingCarrier":"SK","marketingFlightNumber":"1407","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T15:10:00Z","utc":"2020-02-12T14:10:00Z"}},"arrival":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T16:25:00Z","utc":"2020-02-12T15:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK0559-20200212-CPH-CDG","operatingCarrier":"SK","operatingFlightNumber":"0559","marketingCarrier":"SK","marketingFlightNumber":"0559","departure":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T17:10:00Z","utc":"2020-02-12T16:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T19:05:00Z","utc":"2020-02-12T18:05:00Z"}}}},{"id":"P2WNNO-O-01-04","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LX0645-20200212-CDG-ZRH","operatingCarrier":"LX","operatingFlightNumber":"0645","marketingCarrier":"LX","marketingFlightNumber":"0645","departure":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T20:50:00Z","utc":"2020-02-12T19:50:00Z"}},"arrival":{"station":"ZRH","terminal":"2","scheduledTime":{"local":"2020-02-12T22:00:00Z","utc":"2020-02-12T21:00:00Z"}}},"bookingClass":"Y","serviceClass":"C"}]}]}]';

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.anyObject()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String flightId = 'SK0946-20200211-ORD-ARN';

        //When
        List<IRR_MOD_PassengerInfo> passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(
                flightId);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v1');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.anyObject()
        );
        Map<String, Object> matchMap = new Map<String, Object>{
                'flightId' => flightId
        };
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.eqString('/teds-booking/bookings'),
                (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.mapWithPath(matchMap)
        );
        System.assertEquals(1, passengerInfos.size());
        IRR_MOD_PassengerInfo passengerInfo = passengerInfos[0];
        System.assertEquals('P2WNNO', passengerInfo.bookingReference);
        System.assertEquals('ABC1234', passengerInfo.codsId);
        System.assert(passengerInfo.hasPhoneNumber);
        //System.assert(passengerInfo.hasEmailAddress); //TODO
        System.assertEquals('+46701234567', passengerInfo.phoneNumber);
        System.assertEquals('SK0946-20200211-ORD-ARN', passengerInfo.thisSegment.flightId);
        System.assertEquals(true, passengerInfo.thisSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.thisSegment.isWideroeTicket);
        System.assertEquals('117-3456789009876', passengerInfo.thisSegment.ticketNumber);
        System.assertEquals('ORD', passengerInfo.thisSegment.stationDeparture);
        System.assertEquals('ARN', passengerInfo.thisSegment.stationArrival);
        System.assertEquals(true, passengerInfo.thisSegment.isConfirmed);
        System.assertEquals('Confirmed', passengerInfo.thisSegment.status);
        System.assertEquals(true, passengerInfo.hasNextSegment);
        System.assertEquals('SK1407-20200212-ARN-CPH', passengerInfo.nextSegment.flightId);
        System.assertEquals(true, passengerInfo.nextSegment.isSASTicket);
        System.assertEquals(false, passengerInfo.nextSegment.isWideroeTicket);
        System.assertEquals('117-3456789009876', passengerInfo.nextSegment.ticketNumber);
        System.assertEquals('ARN', passengerInfo.nextSegment.stationDeparture);
        System.assertEquals('CPH', passengerInfo.nextSegment.stationArrival);
        System.assertEquals(true, passengerInfo.nextSegment.isConfirmed);
        System.assertEquals('Confirmed', passengerInfo.nextSegment.status);
    }

    @IsTest
    static void testGetPassengerInfosForBooking() {
        String jsonResponse = '{"id":"P2WNNO-20200205","reference":"P2WNNO","type":"ReturnTrip","status":"Active","codsId":"ABC1234","audit":{"created":{"officeId":"STOSK08RV","at":"2020-02-05T17:32:28Z"},"updated":{"officeId":"STOSK08RV","at":"2017-02-12T17:32:28Z"}},"passengers":[{"id":"P2WNNO-01","title":"MR","firstName":"Sam","lastName":"Milley","type":"Adult","contact":{"phone":[{"type":"CTCM","number":"+46701234567"}],"email":[{"type":"CTCE","address":"name@email.com"}]},"frequentTraveler":{"carrier":"SK","tier":"G","number":"128054392"},"segments":[{"segmentId":"P2WNNO-O-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-02","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-03","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-O-01-04","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true},{"segmentId":"P2WNNO-I-01-01","seatedWith":null,"ticket":{"number":"117-3456789009876","type":"ETKT"},"seat":"3C","isCheckedIn":true,"checkinOfficeId":"OSLSK08VB","isBoarded":true}]}],"trips":[{"id":"P2WNNO-O-01","type":"Outbound","segments":[{"id":"P2WNNO-O-01-01","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"SK0946-20200211-ORD-ARN","operatingCarrier":"SK","operatingFlightNumber":"0946","marketingCarrier":"SK","marketingFlightNumber":"0946","departure":{"station":"ORD","terminal":"2","scheduledTime":{"local":"2020-02-11T16:00:00Z","utc":"2020-02-12T00:00:00Z"}},"arrival":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T07:25:00Z","utc":"2020-02-12T06:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"TX7ZK8-O-01-02","transportationType":"Flight","statusCode":"UN","status":"Cancelled","flight":{"id":"SK0579-20200212-ARN-CDG","operatingCarrier":"SK","operatingFlightNumber":"0579","marketingCarrier":"SK","marketingFlightNumber":"0579","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T16:10:00Z","utc":"2020-02-12T15:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T18:45:00Z","utc":"2020-02-12T17:45:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK1407-20200212-ARN-CPH","operatingCarrier":"SK","operatingFlightNumber":"1407","marketingCarrier":"SK","marketingFlightNumber":"1407","departure":{"station":"ARN","terminal":"2","scheduledTime":{"local":"2020-02-12T15:10:00Z","utc":"2020-02-12T14:10:00Z"}},"arrival":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T16:25:00Z","utc":"2020-02-12T15:25:00Z"}}},"bookingClass":"Y","serviceClass":"C"},{"id":"P2WNNO-O-01-03","transportationType":"Flight","statusCode":"TK","status":"Confirmed","flight":{"id":"SK0559-20200212-CPH-CDG","operatingCarrier":"SK","operatingFlightNumber":"0559","marketingCarrier":"SK","marketingFlightNumber":"0559","departure":{"station":"CPH","terminal":"2","scheduledTime":{"local":"2020-02-12T17:10:00Z","utc":"2020-02-12T16:10:00Z"}},"arrival":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T19:05:00Z","utc":"2020-02-12T18:05:00Z"}}}},{"id":"P2WNNO-O-01-04","transportationType":"Flight","statusCode":"HK","status":"Confirmed","flight":{"id":"LX0645-20200212-CDG-ZRH","operatingCarrier":"LX","operatingFlightNumber":"0645","marketingCarrier":"LX","marketingFlightNumber":"0645","departure":{"station":"CDG","terminal":"2","scheduledTime":{"local":"2020-02-12T20:50:00Z","utc":"2020-02-12T19:50:00Z"}},"arrival":{"station":"ZRH","terminal":"2","scheduledTime":{"local":"2020-02-12T22:00:00Z","utc":"2020-02-12T21:00:00Z"}}},"bookingClass":"Y","serviceClass":"C"}]}]}';

        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        C_IIntegrationExecutorBuilder builderMock = (C_IIntegrationExecutorBuilder) mocks.mock(
                C_IntegrationExecutorBuilder.class);
        C_IIntegrationExecutor executorMock = (C_IIntegrationExecutor) mocks.mock(C_IntegrationExecutorRest.class);


        //Given
        mocks.startStubbing();
        mocks.when(builderMock.setBaseURL(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIMSubscriptionKey(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.setAPIVersion(fflib_Match.anyString())).thenReturn(builderMock);
        mocks.when(builderMock.build()).thenReturn(executorMock);
        mocks.when(executorMock.executeRequest(
                    fflib_Match.anyString(),
                    (C_IntegrationExecutor.Method) fflib_Match.eq(C_IntegrationExecutor.Method.GET),
                    (Map<String, Object>) fflib_Match.isNull(),
                    (Map<String, Object>) fflib_Match.isNull()))
                .thenReturn(new C_IntegrationExecutor.IntegrationResponse(200, jsonResponse));
        mocks.stopStubbing();
        IRR_Application.IntegrationExecutorBuilder.setMock(IRR_Application.IntegrationType.REST, builderMock);
        String bookingRef = 'P2WNNO-20200205';

        //When
        List<IRR_MOD_PassengerInfo> passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(bookingRef);

        //Then
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setBaseURL('callout:SAS_APIM');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock))
                .setAPIMSubscriptionKey('b8568217401c49acb3931605cea78835');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).setAPIVersion('v1');
        ((C_IIntegrationExecutorBuilder) mocks.verify(builderMock)).build();
        ((C_IIntegrationExecutor) mocks.verify(executorMock)).executeRequest(
                (String) fflib_Match.anyObject(),
                (C_IntegrationExecutor.Method) fflib_Match.anyObject(),
                (Map<String, Object>) fflib_Match.isNull(),
                (Map<String, Object>) fflib_Match.isNull()
        );
        System.assertEquals(1, passengerInfos.size());
        IRR_MOD_PassengerInfo passengerInfo = passengerInfos[0];
        System.assertEquals('P2WNNO', passengerInfo.bookingReference);
        System.assertEquals('ABC1234', passengerInfo.codsId);
        System.assert(passengerInfo.hasPhoneNumber);
        //System.assert(passengerInfo.hasEmailAddress); //TODO
        System.assertEquals('+46701234567', passengerInfo.phoneNumber);
        System.assert(!passengerInfo.hasThisSegment);
        System.assert(!passengerInfo.hasNextSegment);
    }
}