/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for EventService class.
*/

@IsTest
private class IRR_SVC_CommunicationService_Test {

    @IsTest
    static void testProcessEventJSONPayload() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', 'TEST_PAYLOAD');

        //Then
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).validateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).initiateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processMessages();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).finalizeEvent(uowMock);
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

    @IsTest
    static void testProcessEventObjectPayload() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
        IRR_EVT_IEventProcessor eventMock = (IRR_EVT_IEventProcessor) mocks.mock(IRR_EVT_DelayProcessor.class);

        //Given
        IRR_Application.UnitOfWork.setMock(uowMock);
        IRR_Application.EventProcessor.setMock('TEST_EVENT', eventMock);

        //When
        IRR_SVC_CommunicationService.processEvent('TEST_EVENT', (Object) new Map<String, Object>());

        //Then
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).validateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).initiateEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processEvent();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).processMessages();
        ((IRR_EVT_IEventProcessor) mocks.verify(eventMock)).finalizeEvent(uowMock);
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }
}