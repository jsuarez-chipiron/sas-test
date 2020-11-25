/**
    Batch class which ensures that all Checkin queued messages are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_ProcessCurfewMessages_Batch extends SBS_ScheduledBatch implements Schedulable {

    private String eventLogsStatus = 'Queued';
    private String eventType = 'manualCommunication';
   
    

    global IRR_ProcessCurfewMessages_Batch(){
        this.setUseTransactionControl(false);
    }
    /**
        Iterates over all Event Logs in the queued Status
        @param bc The batch context
    */

    global Database.QueryLocator start(Database.BatchableContext bc){

        return IRR_SEL_EventLogsSelector.newInstance().getQueuedCheckinQueryLocator(eventLogsStatus);

    }


    /**
		Processes the Event Logs with queued status
		@param bc The batchable context of the batch job
		@param sObjScope The Queued Event Logs to process
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
         for(IRR_EventLog__c so : (List<IRR_EventLog__c>) sObjScope){
            IRR_SVC_CommunicationServiceImpl c = new IRR_SVC_CommunicationServiceImpl();
            IRR_MOD_ManualRequest cInfo = (IRR_MOD_ManualRequest)JSON.deserialize(so.IRR_EventPayload__c, IRR_MOD_ManualRequest.class);
            cInfo.sendMessageTime = null;
            //cInfo.eventTime= Datetime.now();
            //String payloadJSON = JSON.serialize(cInfo);
            IRR_SVC_CommunicationService.processEvent(eventType, cInfo);
         }
         delete sObjScope ;
    }

    global override void finishOverridable(Database.BatchableContext bc){
        String scheduleTime = C_Settings.getSettings('IRR_Checkin').get('ScheduleTime');
        System.debug(scheduleTime);
        System.schedule('ProcessQueuedCheckin'+Datetime.Now(), scheduleTime, new IRR_ProcessCurfewMessages_Batch());
        
    }

    global void execute(SchedulableContext ctx) {
        SBS_ScheduledBatch processQueuedCheckin = new IRR_ProcessCurfewMessages_Batch ();
        ID batchprocessid = Database.executeBatch(processQueuedCheckin,3);
        }
    
}
