global with sharing class IRR_BCH_Scheduled_IcouponEvent extends SBS_ScheduledBatch implements Schedulable {
  public Static String eventType = 'flightDelayDeparture';
    /**
     overriding the absract method to set batch class Params
     */
     global override void setVariables(
      String obj,
      Integer retentionPeriod,
      string caseField,
      String caseType,
      String batchName,
      String scheduledBatchRunComponentId
    )
    {
    }

     /**
        Iterates over all Event Logs in the queued Status for manual communication
        @param bc The batch context
    */

  global Database.QueryLocator start(Database.BatchableContext bc) {
    this.setUseTransactionControl(false);
    return IRR_SEL_EventLogsSelector.newInstance()
      .getQueuedIcouponBatchQueryLocator();
  }
  
  /**
        Processes the Event Logs for scheduled manual messages
        @param bc The batchable context of the batch job
        @param sObjScope The scheduled Event Logs to process
    */
    global override void executeScope(
        Database.BatchableContext bc,
        SObject[] sObjScope
      ) {
        List<IRR_EventLog__c>  eventLogMap = new List<IRR_EventLog__c>();
        for(SObject sObj :sObjScope){
            IRR_EventLog__c evtLog = (IRR_EventLog__c)sObj;
            evtLog.Is_Communication_Send__c = true;
            eventLogMap.add(evtLog); 
            IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
            delayInfo.stationDeparture = evtLog.IRR_Station_Departure__c;
            delayInfo.delayedMinutes = (Integer)evtLog.IRR_Delayed_Minutes__c;
            delayInfo.scheduledTimeOfDepartureUTC = evtLog.IRR_ScheduleTime__c;
            delayInfo.scheduledTimeOfDepartureLocal = evtLog.IRR_ScheduleTime__c;
            delayInfo.flightRef = evtLog.IRR_Flight_Ref__c;
            delayInfo.flightId = evtLog.IRR_FlightId__c;
            delayInfo.estimatedTimeOfDepartureLocal = System.now();
            IRR_SVC_CommunicationService.processEvent(eventType, delayInfo);
        }
        Update eventLogMap;
      }

      global override void finishOverridable(Database.BatchableContext bc) {
    }
  
    global void execute(SchedulableContext ctx) {
      SBS_ScheduledBatch processQueuedManual = new IRR_BCH_Scheduled_IcouponEvent();
      ID batchprocessid = Database.executeBatch(processQueuedManual, 1);
    }
}
