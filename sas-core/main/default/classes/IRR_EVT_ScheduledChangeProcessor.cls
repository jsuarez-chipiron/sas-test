/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the Scheduled Change Rebook event.
*      Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_ScheduledChangeProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Scheduled Change event details are missing: {0}';
    private static final String ERROR_BOOKING_ID = 'Booking Id is missing from event: {0}';
    private static final String ERROR_BOOKING_REF = 'Booking Ref is missing from event: {0}';
    private static final String ERROR_NO_EVENT_TIME = 'Event time is missing from event: {0}';
    private static final String ERROR_NO_IS_DAY_CHANGE = 'Is Day Change is missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_ScheduledChangeFlow';

    @TestVisible
    private IRR_MOD_ScheduledChangeInfo scheduledChangeInfo;

    public String getEventName() {
        return 'Scheduled Change';
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (scheduledChangeInfo == null) {
            throwEventException(ERROR_NO_EVENT, scheduledChangeInfo);
        }
        if (String.isBlank(scheduledChangeInfo.bookingId)) {
            throwEventException(ERROR_BOOKING_ID, scheduledChangeInfo);
        }
        if (String.isBlank(scheduledChangeInfo.bookingReference)) {
            throwEventException(ERROR_BOOKING_REF, scheduledChangeInfo);
        }
        if (scheduledChangeInfo.eventTime == null) {
            throwEventException(ERROR_NO_EVENT_TIME, scheduledChangeInfo);
        }
        if (scheduledChangeInfo.isDayChange == null) {
            throwEventException(ERROR_NO_IS_DAY_CHANGE, scheduledChangeInfo);
        }
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     */
    public void initiateEvent() {
        //Retrieve passengers for booking
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(scheduledChangeInfo.bookingId);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Checks if any active manual override blocks exist.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        //Active blocks are currently not applicable for Scheduled Change event
        return false;
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Executes flow with for each passenger with event specific information.
     */
    public void processEvent() {
        //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.scheduledChangeInfo = scheduledChangeInfo;

        //Process passengers
        for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(EVENT_FLOW_NAME, flowVariables);
        }
    }


    public IRR_EVT_ScheduledChangeProcessor(IRR_MOD_ScheduledChangeInfo scheduledChangeInfo) {
        this.scheduledChangeInfo = scheduledChangeInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_ScheduledChangeProcessor((IRR_MOD_ScheduledChangeInfo)payload);
        }
    }
}