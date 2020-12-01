/**
    Batch class which ensures that all queued messages are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_ProcessCurfewMessages_Batch extends SBS_ScheduledBatch implements Schedulable {

    // private String eventLogsStatus = 'Queued';
    private String eventType = 'manualCommunication';
   
    

    global IRR_ProcessCurfewMessages_Batch(){
        this.setUseTransactionControl(false);
    }
    /**
        Iterates over all Event Logs in the queued Status
        @param bc The batch context
    */

    global Database.QueryLocator start(Database.BatchableContext bc){

        return IRR_SEL_EventLogsSelector.newInstance().getQueuedCheckinQueryLocator();

    }


    /**
		Processes the Event Logs with queued status
		@param bc The batchable context of the batch job
		@param sObjScope The Queued Event Logs to process
	*/
	global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
         
        for(IRR_EventLog__c so : (List<IRR_EventLog__c>) sObjScope){
            String payloadStr= '';
            payloadStr += ((so.Event_Payload_1__c!=null && so.Event_Payload_1__c!='')?so.Event_Payload_1__c:'');
            payloadStr += ((so.Event_Payload_2__c!=null && so.Event_Payload_2__c!='')?so.Event_Payload_2__c:'');
            payloadStr += ((so.Event_Payload_3__c!=null && so.Event_Payload_3__c!='')?so.Event_Payload_3__c:'');
            payloadStr += ((so.Event_Payload_4__c!=null && so.Event_Payload_4__c!='')?so.Event_Payload_4__c:'');
            IRR_SVC_CommunicationServiceImpl c = new IRR_SVC_CommunicationServiceImpl();
            IRR_MOD_ManualRequest cInfo = (IRR_MOD_ManualRequest)JSON.deserialize(payloadStr, IRR_MOD_ManualRequest.class);
            cInfo.sendMessageTime = null;
            IRR_SVC_CommunicationService.processEvent(eventType, cInfo);
            }
            
         delete sObjScope ;
    }

    global override void finishOverridable(Database.BatchableContext bc){
        
    }

    global void execute(SchedulableContext ctx) {
        SBS_ScheduledBatch processQueuedManual = new IRR_ProcessCurfewMessages_Batch ();
        ID batchprocessid = Database.executeBatch(processQueuedManual,3);
        }
    
}
