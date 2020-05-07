/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Incoming Event REST API.
*/

@IsTest
private class IRR_API_IncomingEvent_Test {

    @IsTest
    static void testHandleIncomingEvent_Success() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService) mocks.mock(IRR_SVC_CommunicationServiceImpl.class);

        //Given
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('TEST_EVENT_BODY');
        req.httpMethod = 'POST';
        req.requestURI = 'https://instance_name.salesforce.com/services/apexrest/EventAPI/testEventName';
        RestContext.request = req;
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        IRR_API_IncomingEvent.handleIncomingEvent();

        //Then
        ((IRR_SVC_ICommunicationService) mocks.verify(serviceMock)).processEvent('testEventName', 'TEST_EVENT_BODY');
    }

    @IsTest
    static void testHandleIncomingEvent_ErrorResponse() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService) mocks.mock(IRR_SVC_CommunicationServiceImpl.class);

        //Given
        mocks.startStubbing();
        ((IRR_SVC_ICommunicationService) mocks.doThrowWhen(
                new IRR_SVC_CommunicationService.EventException('TEST_EXCEPTION'), serviceMock))
                .processEvent(fflib_Match.anyString(), fflib_Match.anyString());
        mocks.stopStubbing();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('TEST_EVENT_BODY');
        req.httpMethod = 'POST';
        req.requestURI = 'https://instance_name.salesforce.com/services/apexrest/EventAPI/testEventName';
        RestContext.request = req;
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        IRR_API_IncomingEvent.handleIncomingEvent();

        //Then
        ((IRR_SVC_ICommunicationService) mocks.verify(serviceMock)).processEvent('testEventName', 'TEST_EVENT_BODY');
        RestResponse response = RestContext.response;
        System.assertNotEquals(null, response);
        System.assertEquals(500, response.statusCode);
        System.assertEquals('TEST_EXCEPTION', response.responseBody.toString());
        System.assertEquals(1, [SELECT COUNT() FROM C_Log__c WHERE LogGroup__c = 'IRR']);
    }
}