/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the Disruption Rebook event.
*      Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_RebookProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Rebook event details are missing: {0}';
    private static final String ERROR_BOOKING_ID = 'Booking Id is missing from event: {0}';
    private static final String ERROR_BOOKING_REF = 'Booking Ref is missing from event: {0}';
    private static final String ERROR_NO_EVENT_TIME = 'Event time is missing from event: {0}';
    private static final String ERROR_NO_ADDED_SEGMENTS = 'Added Segments are missing from event: {0}';

    private static final String EVENT_FLOW_NAME = 'IRR_EVT_RebookFlow';

    @TestVisible
    private IRR_MOD_RebookInfo rebookInfo;

    public String getEventName() {
        return 'Rebook';
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
        if (rebookInfo == null) {
            throwEventException(ERROR_NO_EVENT, rebookInfo);
        }
        if (String.isBlank(rebookInfo.bookingId)) {
            throwEventException(ERROR_BOOKING_ID, rebookInfo);
        }
        if (String.isBlank(rebookInfo.bookingReference)) {
            throwEventException(ERROR_BOOKING_REF, rebookInfo);
        }
        if (rebookInfo.eventTime == null) {
            throwEventException(ERROR_NO_EVENT_TIME, rebookInfo);
        }
        if (rebookInfo.addedSegments == null || rebookInfo.addedSegments.isEmpty()) {
            throwEventException(ERROR_NO_ADDED_SEGMENTS, rebookInfo);
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
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForBooking(rebookInfo.bookingId);
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
        //Active blocks are currently not applicable for Rebook event
        return false;
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Executes flow with for each passenger with event specific information.
     * Added AirportCityNames callout to TEDS to render citynames on the templates
     */
    public void processEvent() {
        //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.rebookInfo = rebookInfo;
        // String[] airportCodes = new List<String>();
        
        //Process passengers
        // if(passengerInfos != null && passengerInfos.size() > 0){
        //     for (IRR_MOD_PassengerInfo passengerInfo : passengerInfos) {
        //         if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0){
        //             for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary){
        //                 if(tripInfo.segments != null && tripInfo.segments.size() > 0){
        //                     for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments){
        //                         airportCodes.add(segmentInfo.stationArrival);
        //                         airportCodes.add(segmentInfo.stationDeparture);
        //                     }
        //                 }

        //             }

        //         }
        //     }
        // }
        //         this.airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(airportCodes);

            //Get the equivalent airport city names and set it in passenger info so that they are accesible in reboooking templates
        for(IRR_MOD_PassengerInfo passengerInfo : passengerInfos){
            // if(passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0){
            //     for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary){
            //         if(tripInfo.segments != null && tripInfo.segments.size() > 0){
            //             for(IRR_MOD_SegmentInfo segmentInfo: tripInfo.segments){
            //                segmentInfo.arrivalCity = this.airportInfoMap.get(segmentInfo.stationArrival);
            //                segmentInfo.departureCity = this.airportInfoMap.get(segmentInfo.stationDeparture);
            //             }
            //         }

            //     }

            // }
            //Set passenger info in flowVariables and execute flow
            flowVariables.passengerInfo = passengerInfo;
            executeFlow(EVENT_FLOW_NAME, flowVariables);  
        }
                
            

        
        
    }

    public IRR_EVT_RebookProcessor(IRR_MOD_RebookInfo rebookInfo) {
        this.rebookInfo = rebookInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_RebookProcessor((IRR_MOD_RebookInfo) payload);
        }
    }
}