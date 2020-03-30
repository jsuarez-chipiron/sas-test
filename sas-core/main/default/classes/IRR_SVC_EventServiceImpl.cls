/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Concrete implementation of Event functionality.
*/

public class IRR_SVC_EventServiceImpl implements IRR_SVC_IEventService {

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Initiates an Event Processor using Application factory and uses it for processing an event.
     *
     * @param eventType Type of Event to process
     * @param payload JSON Serialized event payload
     */
    public void processEvent(String eventType, String payload) {
        fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
        IRR_EVT_IEventProcessor eventProcessor = IRR_Application.EventProcessor.newInstance(eventType, payload);
        eventProcessor.validateEvent();
        eventProcessor.initiateEvent();
        eventProcessor.processEvent();
        eventProcessor.processMessages();
        eventProcessor.finalizeEvent(uow);
        uow.commitWork();
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Initiates an Event Processor using Application factory and uses it for processing an event.
     *
     * @param eventType Type of Event to process
     * @param payload De-serialized Event payload
     */
    public void processEvent(String eventType, Object payload) {
        fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
        IRR_EVT_IEventProcessor eventProcessor = IRR_Application.EventProcessor.newInstance(eventType, payload);

        Integer startTime = Limits.getCpuTime();
        eventProcessor.validateEvent();
        Integer endTime = Limits.getCpuTime();
        System.debug('\n\nPERF - Validated Event in: ' + (endTime - startTime) + '\n\n');

        startTime = Limits.getCpuTime();
        eventProcessor.initiateEvent();
        endTime = Limits.getCpuTime();
        System.debug('\n\nPERF - Initiated Event in: ' + (endTime - startTime) + '\n\n');

        startTime = Limits.getCpuTime();
        eventProcessor.processEvent();
        endTime = Limits.getCpuTime();
        System.debug('\n\nPERF - Processed Event in: ' + (endTime - startTime) + '\n\n');

        startTime = Limits.getCpuTime();
        eventProcessor.processMessages();
        endTime = Limits.getCpuTime();
        System.debug('\n\nPERF - Processed Messages in: ' + (endTime - startTime) + '\n\n');

        startTime = Limits.getCpuTime();
        eventProcessor.finalizeEvent(uow);
        endTime = Limits.getCpuTime();
        System.debug('\n\nPERF - Finalized Event in: ' + (endTime - startTime) + '\n\n');

        startTime = Limits.getCpuTime();
        uow.commitWork();
        endTime = Limits.getCpuTime();
        System.debug('\n\nPERF - Committed Work in: ' + (endTime - startTime) + '\n\n');
    }
}