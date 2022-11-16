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
    @TestVisible
    private IRR_MOD_ICouponInfo ICouponInfo;
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
     * Added AirportCityNames callout to TEDS to render citynames on the templates
     */
    public void initiateEvent() {
        //Retrieve previous delay and calculate difference
        if( System.Isbatch()==false){
        Map<String, Integer> delayMinutesByFlightIds = IRR_SEL_DelayLogsSelector.newInstance()
                .getLatestDelayByFlightIds(new Set<String>{delayInfo.flightId});
        delayInfo.previousDelayedMinutes = delayMinutesByFlightIds.containsKey(delayInfo.flightId) ?
                delayMinutesByFlightIds.get(delayInfo.flightId) : 0;
            
                
       
         delayInfo.firstDelay = delayInfo.previousDelayedMinutes == 0;
            
        
        delayInfo.delayDifference =Math.abs(delayInfo.delayedMinutes - delayInfo.previousDelayedMinutes);


        IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                new IRR_SVC_CommunicationService.FlightIdSplit(delayInfo.flightId);
        delayInfo.flightRef = flightIdSplit.flightNumber;
        delayInfo.stationDeparture = flightIdSplit.stationDeparture;
        delayInfo.stationArrival = flightIdSplit.stationArrival;

        //Retrieve Airport city names from TEDS
        if(delayinfo.stationDeparture != null && delayinfo.stationDeparture != '' 
                && delayinfo.stationArrival != null && delayinfo.stationArrival != ''){
        this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames(new Set<String>{delayinfo.stationDeparture,delayinfo.stationArrival} );        
        delayInfo.departureCity = airportInfoMap.get(delayinfo.stationDeparture);
        delayInfo.arrivalCity = airportInfoMap.get(delayinfo.stationArrival);
        }

        //Calculate time difference of scheduled time of departure and estimated time of departure in minutes
        Long millisecondsToScheduledTime = delayInfo.scheduledTimeOfDepartureUTC.getTime() - Datetime.now().getTime();
        delayInfo.minutesToScheduledTime = (Integer) millisecondsToScheduledTime / 60000;
    }
        //Retrieve passengers for flight
        this.passengerInfos = IRR_SVC_TedsService.getPassengerInfosForFlight(delayInfo.flightId);
       
        Map<String,List<String>> segmentIdToBoarding = new Map<String,List<String>>();

        // binding segment id with boarding sequence number 
         for(IRR_MOD_PassengerInfo passenger :this.passengerInfos){
 
             if( passenger.hasThisSegment ==true && 
                 passenger.thisSegment.serviceClass !=null&& 
                 passenger.thisSegment.boardingSequenceNumber !=null
               ){
                     if(!segmentIdToBoarding.containsKey(passenger.thisSegment.serviceClass)){
                         segmentIdToBoarding.put(passenger.thisSegment.serviceClass,new List<String> { });
 
                     }
                   segmentIdToBoarding.get(passenger.thisSegment.serviceClass).add(String.valueOf(passenger.thisSegment.boardingSequenceNumber));
 
             }
         }
         
         
         Map<String,String> serviceClassToSegId = new Map<String,String>();
          
    
          if(System.Isbatch()==true){
           List<IRR_MOD_ICouponInfo> iCouponInfo = IRR_SVC_ICouponService.createFlightIrregularity(delayInfo,segmentIdToBoarding);
              if(iCouponInfo !=null && iCouponInfo.size()>0){
                   delayInfo.hasCouponBatchId = true;
              }
             
              System.debug('ICOUPONINFO-->'+iCouponInfo);
              Map<String,IRR_MOD_ICouponInfo> classToAmount = new  Map<String,IRR_MOD_ICouponInfo>();
              for(IRR_MOD_ICouponInfo icouponMod : iCouponInfo){
                  classToAmount.put(icouponMod.serviceClassCode,icouponMod);
              }
 
             for(IRR_MOD_PassengerInfo passenger :this.passengerInfos){
 
             if( passenger.hasThisSegment ==true && 
                 passenger.thisSegment.serviceClass !=null &&
                 passenger.thisSegment.boardingSequenceNumber !=null
 
               ){
                   if(classToAmount.containsKey(passenger.thisSegment.serviceClass)){
 
                   IRR_MOD_ICouponInfo icoupon =classToAmount.get(passenger.thisSegment.serviceClass);
 
                       String str    = 'The voucher amount is ' ;
                                str +=icoupon.voucherAmount;
                                str +=' ' +icoupon.currencyCode;
                               str +='.';
 
                       passenger.thisSegment.emailBackBody = str;
                       passenger.thisSegment.couponBatchId  = classToAmount.get(passenger.thisSegment.serviceClass).couponBatchId;
                   }
 
               }
                 else{
                     passenger.thisSegment.emailBackBody ='';
                 }
             }
          }
         
       
         
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
       
        if (messages != null && !messages.isEmpty() && System.Isbatch() ==false) {
            insertDelayLog(uow);
            
        }
        if (
            (delayInfo !=null && delayInfo.firstDelay ==true  && System.Isbatch() ==false && delayInfo.delayedMinutes >= 120)
            ||
            (delayInfo !=null && delayInfo.firstDelay ==false  && System.Isbatch() ==false)
            )
        {
            insertEventLog(uow);
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

      /**
     * @author Gaurav , Coforge
     * @date 2022
     *
     * @description Creates a Event Log based on event object information and registers it in the Unit of Work.
     *
     * @param uow Unit of Work
     */
    private void insertEventLog(fflib_ISObjectUnitOfWork uow) {
             boolean isEventFound = false;
             // Get a query locator
            Database.QueryLocator sObjectList=   IRR_SEL_EventLogsSelector.newInstance()
              .getQueuedIcouponQueryLocator(delayInfo.flightId);
            
              Database.QueryLocatorIterator it =  sObjectList.iterator();
              // Iterate over the records
                while (it.hasNext())
                {
                    IRR_EventLog__c eventLog = (IRR_EventLog__c)it.next();
                    eventLog.IRR_ScheduleTime__c = delayInfo.estimatedTimeOfDepartureUTC;
                    eventLog.IRR_FlightId__c =delayInfo.flightId ;
                    eventLog.IRR_Event_Type__c = 'ICOUPON';
                    eventLog.IRR_Delayed_Minutes__c = delayInfo.delayedMinutes;
                    eventLog.IRR_Station_Departure__c = delayInfo.stationDeparture;
                    eventLog.IRR_Flight_Ref__c = delayInfo.flightRef;
                    uow.registerUpsert(eventLog);
                    isEventFound = true ;
                }
            
               if(isEventFound == false){
                IRR_EventLog__c eventLog = new IRR_EventLog__c();
                eventLog.IRR_ScheduleTime__c = delayInfo.estimatedTimeOfDepartureUTC;
                eventLog.IRR_FlightId__c =delayInfo.flightId ;
                eventLog.IRR_Event_Type__c = 'ICOUPON';
                eventLog.IRR_Delayed_Minutes__c = delayInfo.delayedMinutes;
                eventLog.IRR_Station_Departure__c = delayInfo.stationDeparture;
                eventLog.IRR_Flight_Ref__c = delayInfo.flightRef;
                uow.registerNew(eventLog);
               }
        
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