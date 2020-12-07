/**
    Batch class which ensures that all manual queued messages are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_BCH_ScheduledEvent extends SBS_ScheduledBatch implements Schedulable {

    private String eventType = 'manualCommunication';
    
  /**
        Iterates over all Event Logs in the queued Status for manual communication
        @param bc The batch context
    */

    global Database.QueryLocator start(Database.BatchableContext bc){

        this.setUseTransactionControl(false);
        return IRR_SEL_EventLogsSelector.newInstance().getQueuedManualQueryLocator();

    }


    /**
		Processes the Event Logs for scheduled manual messages
		@param bc The batchable context of the batch job
		@param sObjScope The scheduled Event Logs to process
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
         
        for(IRR_EventLog__c so : (List<IRR_EventLog__c>) sObjScope){
            String payloadStr= '';
            payloadStr += ((so.Event_Payload_1__c!=null && so.Event_Payload_1__c!='')?so.Event_Payload_1__c:'');
            payloadStr += ((so.Event_Payload_2__c!=null && so.Event_Payload_2__c!='')?so.Event_Payload_2__c:'');
            payloadStr += ((so.Event_Payload_3__c!=null && so.Event_Payload_3__c!='')?so.Event_Payload_3__c:'');
            payloadStr += ((so.Event_Payload_4__c!=null && so.Event_Payload_4__c!='')?so.Event_Payload_4__c:'');
            IRR_MOD_ManualRequest cInfo = (IRR_MOD_ManualRequest)JSON.deserialize(payloadStr, IRR_MOD_ManualRequest.class);
            cInfo.sendMessageTime = null;
            IRR_SVC_CommunicationService.processEvent(eventType, cInfo);
        }
            delete sObjScope ;
    }

    global override void finishOverridable(Database.BatchableContext bc){
        
    }

    global void execute(SchedulableContext ctx) {
        SBS_ScheduledBatch processQueuedManual = new IRR_BCH_ScheduledEvent ();
        ID batchprocessid = Database.executeBatch(processQueuedManual,3);
    }
    
}
