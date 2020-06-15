/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the Delay event. Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_DelayProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Delay event info is missing: {0}';
    private static final String ERROR_FLIGHT_ID = 'Flight Id is missing from event: {0}';
    private static final String ERROR_DELAY_MINUTES = 'Delay minutes is missing from event: {0}';
    private static final String ERROR_DEPT_TIME = 'Estimated time of departure is missing from event: {0}';
    private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_DelayFlow';

    @TestVisible
    private IRR_MOD_DelayInfo delayInfo;

    public String getEventName(){
        return 'Delay';
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (delayInfo == null) {
            throwEventException(ERROR_NO_EVENT, delayInfo);
        }
        if (String.isBlank(delayInfo.flightId)) {
            throwEventException(ERROR_FLIGHT_ID, delayInfo);
        }
        if (delayInfo.delayedMinutes == null) {
            throwEventException(ERROR_DELAY_MINUTES, delayInfo);
        }
        if (delayInfo.estimatedTimeOfDepartureLocal == null) {
            throwEventException(ERROR_DEPT_TIME, delayInfo);
        }
        if (delayInfo.scheduledTimeOfDepartureUTC == null || delayInfo.scheduledTimeOfDepartureLocal == null) {
            throwEventException(ERROR_SCHD_TIME, delayInfo);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     */
    public void initiateEvent() {
        //Retrieve previous delay and calculate difference
        Map<String, Integer> delayMinutesByFlightIds = IRR_SEL_DelayLogsSelector.newInstance()
                .getLatestDelayByFlightIds(new Set<String>{delayInfo.flightId});
        delayInfo.previousDelayedMinutes = delayMinutesByFlightIds.containsKey(delayInfo.flightId) ?
                delayMinutesByFlightIds.get(delayInfo.flightId) : 0;
        delayInfo.firstDelay = delayInfo.previousDelayedMinutes == 0;
        delayInfo.delayDifference = Math.abs(delayInfo.delayedMinutes - delayInfo.previousDelayedMinutes);


        IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                new IRR_SVC_CommunicationService.FlightIdSplit(delayInfo.flightId);
        delayInfo.flightRef = flightIdSplit.flightNumber;
        delayInfo.stationDeparture = flightIdSplit.stationDeparture;
        delayInfo.stationArrival = flightIdSplit.stationArrival;

        //Calculate time difference of scheduled time of departure and estimated time of departure in minutes
        Long millisecondsToScheduledTime = delayInfo.scheduledTimeOfDepartureUTC.getTime() - Datetime.now().getTime();
        delayInfo.minutesToScheduledTime = (Integer) millisecondsToScheduledTime / 60000;

        //Retrieve passengers for flight
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(delayInfo.flightId);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Checks if any active manual override blocks exist for this flight.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId(delayInfo.flightId);
        return !manualOverrides.isEmpty();
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
        flowVariables.delayInfo = delayInfo;

        //Process passengers
        for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
            //Only process passengers confirmed for this segment
            if (passengerInfo.thisSegment != null && !passengerInfo.thisSegment.isConfirmed) continue;

            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(EVENT_FLOW_NAME, flowVariables);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Finalizes the event by inserting logs if messages have been created.
     *
     * @param uow Unit of Work
     */
    public override void finalizeEvent(fflib_ISObjectUnitOfWork uow) {
        super.finalizeEvent(uow);
        if (messages != null && !messages.isEmpty()) {
            insertDelayLog(uow);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates a Delay Log based on event object information and registers it in the Unit of Work.
     *
     * @param uow Unit of Work
     */
    private void insertDelayLog(fflib_ISObjectUnitOfWork uow) {
        IRR_DelayLog__c delayLog = new IRR_DelayLog__c();
        delayLog.IRR_FlightId__c = delayInfo.flightId;
        delayLog.IRR_DelayMinutes__c = delayInfo.delayedMinutes;
        uow.registerNew(delayLog);
    }


    public IRR_EVT_DelayProcessor(IRR_MOD_DelayInfo delayInfo) {
        this.delayInfo = delayInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_DelayProcessor((IRR_MOD_DelayInfo) payload);
        }
    }
}