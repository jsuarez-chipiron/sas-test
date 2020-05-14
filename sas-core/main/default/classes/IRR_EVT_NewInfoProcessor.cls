/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the New Info event.
 *      Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_NewInfoProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'New Info event details are missing: {0}';
    private static final String ERROR_FLIGHT_ID = 'Flight Id is missing from event: {0}';
    private static final String ERROR_NEW_INFO_TIME = 'New Info time is missing from event: {0}';
    private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_NewInfoFlow';

    @TestVisible
    private IRR_MOD_NewInfo newInfo;

    public String getEventName(){
        return 'New Info';
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (newInfo == null) {
            throwEventException(ERROR_NO_EVENT, newInfo);
        }
        if (String.isBlank(newInfo.flightId)) {
            throwEventException(ERROR_FLIGHT_ID, newInfo);
        }
        if (newInfo.newInfoTimeLocal == null || newInfo.newInfoTimeUTC == null) {
            throwEventException(ERROR_NEW_INFO_TIME, newInfo);
        }
        if (newInfo.scheduledTimeOfDepartureUTC == null || newInfo.scheduledTimeOfDepartureLocal == null) {
            throwEventException(ERROR_SCHD_TIME, newInfo);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     */
    public void initiateEvent() {
        //Split flightId into Flight Reference, and Departure and Arrival stations.
        List<String> flightIdSplit = newInfo.flightId.split('-');
        newInfo.flightRef = flightIdSplit[0];
        newInfo.stationDeparture = flightIdSplit.size() >= 3 ? flightIdSplit[2] : null;
        newInfo.stationArrival = flightIdSplit.size() >= 4 ? flightIdSplit[3] : null;

        //Retrieve passengers for flight
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(newInfo.flightId);
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
        flowVariables.newInfo = newInfo;

        //Process passengers
        for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
            //Only process passengers confirmed for this segment
            if (passengerInfo.thisSegment == null || !passengerInfo.thisSegment.isConfirmed) continue;

            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(EVENT_FLOW_NAME, flowVariables);
        }
    }

    public IRR_EVT_NewInfoProcessor(IRR_MOD_NewInfo newInfo) {
        this.newInfo = newInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_NewInfoProcessor((IRR_MOD_NewInfo) payload);
        }
    }
}