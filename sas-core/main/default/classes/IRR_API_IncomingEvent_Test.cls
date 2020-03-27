/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

@IsTest
private class IRR_API_IncomingEvent_Test {

    @IsTest
    static void testHandleIncomingEvent() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_IEventService serviceMock = (IRR_SVC_IEventService) mocks.mock(IRR_SVC_EventServiceImpl.class);

        //Given
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('TEST_EVENT_BODY');
        req.httpMethod = 'POST';
        req.requestURI = 'https://instance_name.salesforce.com/services/apexrest/EventAPI/testEventName';
        RestContext.request = req;
        IRR_Application.Service.setMock(IRR_SVC_IEventService.class, serviceMock);

        //When
        IRR_API_IncomingEvent.handleIncomingEvent();

        //Then
        ((IRR_SVC_IEventService) mocks.verify(serviceMock)).processEvent('testEventName', 'TEST_EVENT_BODY');
    }
}