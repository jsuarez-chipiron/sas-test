    /**
* @author Chetan Singh,CoforgeTech
* @date 2020
*
* @description Event Processor for the Checkin event. Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_CheckinProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Checkin event info is missing: {0}';
    private static final String ERROR_FLIGHT_ID = 'Flight Id is missing from event: {0}';
    private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_CheckinFlow';

    @TestVisible
    private Boolean isQueued = false;

    List<String> curfewTime;
    private static Datetime startCurfew;
    private static Datetime endCurfew;
    private static Datetime localTime;
    
    @TestVisible
    private IRR_MOD_CheckinInfo checkinInfo;

    public String getEventName(){
        return 'Checkin';
    }

    /**
     * @author Chetan Singh, Coforgetech
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (checkinInfo == null) {
            throwEventException(ERROR_NO_EVENT, checkinInfo);
        }
        if (String.isBlank(checkinInfo.flightId)) {
            throwEventException(ERROR_FLIGHT_ID, checkinInfo);
        }
        if (checkinInfo.scheduledTimeOfDepartureUTC == null || checkinInfo.scheduledTimeOfDepartureLocal == null) {
            throwEventException(ERROR_SCHD_TIME, checkinInfo);
        }
    }

    /**
     * @author Chetan Singh, Coforgetech
     * @date 2020
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     * Additional filter to black out Checkin messages if initiated between 22:00-07:00 
     * Added AirportCityNames callout to TEDS to render citynames on the templates
     */
    public void initiateEvent() {
        curfewTime = C_Settings.getSettings('IRR_Checkin').get('CheckinCurfew').split('-');
        startCurfew = Datetime.newInstanceGmt(2099, 12, 12, Integer.valueOf(curfewTime.get(0).split(':').get(0)),
                         Integer.valueOf(curfewTime.get(0).split(':').get(1)), 0);
        endCurfew = Datetime.newInstanceGmt(2099, 12, 12, Integer.valueOf(curfewTime.get(1).split(':').get(0)),
                         Integer.valueOf(curfewTime.get(1).split(':').get(1)), 0);
    
        Long localDeparture = checkinInfo.scheduledTimeOfDepartureLocal.gettime();
        Long utcDeparture = checkinInfo.scheduledTimeOfDepartureUTC.gettime();
        Long difference = ((localDeparture-utcDeparture)/1000)/60;


        //Add the difference betwwen local and UTC departure time to Eventtime and convert it to local time
        localTime = checkinInfo.eventTime.addMinutes(Integer.valueOf(difference));

        //Check for the curfew criteria
        if (localTime.timeGmt() <= startCurfew.timeGmt() && localTime.timeGmt() >= endCurfew.timeGmt()) {
            IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                new IRR_SVC_CommunicationService.FlightIdSplit(checkinInfo.flightId);
        checkinInfo.flightRef = flightIdSplit.flightNumber;
        checkinInfo.stationDeparture = flightIdSplit.stationDeparture;
        checkinInfo.stationArrival = flightIdSplit.stationArrival;

         //Retrieve Airport city names from TEDS
        if(checkinInfo.stationDeparture != null && checkinInfo.stationDeparture != '' 
                && checkinInfo.stationArrival != null && checkinInfo.stationArrival != ''){
        this.airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(new List<String>{checkinInfo.stationDeparture,checkinInfo.stationArrival});        
        checkinInfo.departureCity = airportInfoMap.get(checkinInfo.stationDeparture);
        checkinInfo.arrivalCity = airportInfoMap.get(checkinInfo.stationArrival);
        }

        //Retrieve passengers for flight
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(checkinInfo.flightId);

        }else{

            this.isQueued = true;
        }
        
    }
    /**
     * @author Chetan Singh, CoforgeTech
     * @date 2020
     *
     * @description Checks if any active manual override blocks exist for this flight.
     *
     * @return isQueued to check if the messages falls outside checkin curfew or not
     */
    public Boolean checkActiveBlock() {
        return this.isQueued;
    }

    /**
     * @author Chetan Singh, CoforgeTech
     * @date 2020
     *
     * @description Executes flow with for each passenger with event specific information.
     */
    public void processEvent() {
        //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.checkinInfo = checkinInfo;

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
     * @author Chetan Singh, CoforgeTech
     * @date 2020
     *
     * @description Finalizes the event by inserting COM logs if messages have been created or inserting Eventlogs if within checkin curfew.
     *
     * @param uow Unit of Work
     */
    public override void finalizeEvent(fflib_ISObjectUnitOfWork uow) {
        
        if(!isQueued){
            super.finalizeEvent(uow);
        }else{
            insertEventLog(uow);
        }
    }

    /**
     * @author Chetan Singh, CoforgeTech
     * @date 2020
     *
     * @description Creates a Event Log based on event object information and registers it in the Unit of Work.
     *
     * @param uow Unit of Work
     */
    private void insertEventLog(fflib_ISObjectUnitOfWork uow) {

        curfewTime = C_Settings.getSettings('IRR_Checkin').get('CheckinCurfew').split('-');
        startCurfew = Datetime.newInstanceGmt(Date.today().year(),
                        Date.today().month(),Date.today().day(),
                        Integer.valueOf(curfewTime.get(0).split(':').get(0)), Integer.valueOf(curfewTime.get(0).split(':').get(1)), 0);
        endCurfew = null;
        // To set the correct day(next day or the same day) for the endcurfew based on event time received in the payload
        if(localTime.hourGmt() >= Integer.valueOf(curfewTime.get(1).split(':').get(0))){
            endCurfew = Datetime.newInstanceGmt(Date.today().year(),Date.today().month(),
                            Date.today().addDays(1).day(),Integer.valueOf(curfewTime.get(1).split(':').get(0)), 
                            Integer.valueOf(curfewTime.get(1).split(':').get(1)), 0);
            }else {
                endCurfew = Datetime.newInstanceGmt(Date.today().year(),Date.today().month(),Date.today().day(),
                                Integer.valueOf(curfewTime.get(1).split(':').get(0)), 
                                Integer.valueOf(curfewTime.get(1).split(':').get(1)), 0);
            }
            System.debug('##endCurfew##'+endCurfew);
        IRR_EventLog__c eventLog = new IRR_EventLog__c();
        eventLog.IRR_FlightId__c = checkinInfo.flightId;

        //difference between endcurfew and eventTime in minutes
        Long difference = ((endCurFew.getTime()-localTime.getTime())/1000)/60;
        System.debug('##difference##'+difference);
        System.debug('##endCurFew##'+endCurFew.getTime());
        System.debug('##localTime##'+localTime);

        // Preparing ScheduleTime to be the time(currentTime plus difference between endCurfew and Local eventTime)
        // Checkin Batch job will reprocess these messages based on schedule time

        eventLog.IRR_ScheduleTime__c = Datetime.now().addMinutes(Integer.valueof(Difference));
        System.debug('##SchTime##'+eventLog.IRR_ScheduleTime__c);
        String payloadJSON = JSON.serialize(checkinInfo);
        eventLog.IRR_EventPayload__c = payloadJSON;
        uow.registerNew(eventLog);
    }

    public IRR_EVT_CheckinProcessor(IRR_MOD_CheckinInfo checkinInfo) {
        this.checkinInfo = checkinInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_CheckinProcessor((IRR_MOD_CheckinInfo) payload);
        }
    }
}

