/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_IEventService {
    void processEvent(String eventType, String payload);
    void processEvent(String eventType, Object payload);
}