/**
    Batch class which ensures that all automated messages are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_BCH_FetchPaxInfoAutomatedMessage extends SBS_ScheduledBatch implements Schedulable {


  /**
        Iterates over all Automatedmessage metadata for Automated communication
        @param bc The batch context
    */

    global Database.QueryLocator start(Database.BatchableContext bc){

        string query =  'SELECT IRR_Departure_Country__c,IRR_Arrival_Country__c,IRR_Duration__c,IRR_Template_Name__c FROM IRR_AutomatedMessage__mdt ';
        this.setUseTransactionControl(false);
        return Database.getQueryLocator(query);

    }

    /**
		Processes the Automatedmessage custom metadata and prepares the Automatedrequest payload
		@param bc The batchable context of the batch job
		@param sObjScope The Automatedmessage custom metadata to process
	*/
	global override void executeScope(Database.BatchableContext bc, SObject [] sObjScope) {
         for (IRR_AutomatedMessage__mdt message : (List<IRR_AutomatedMessage__mdt>)sObjScope) {

            If(message.IRR_Duration__c != null && message.IRR_Departure_Country__c != null){
            
                List<IRR_MOD_PassengerInfo> PaxInfo =  IRR_CON_AutomatedCommunication.getPassengerInfos(message.IRR_Arrival_Country__c,message.IRR_Departure_Country__c,message.IRR_Duration__c);
                IRR_CON_AutomatedCommunication.AutomatedTemplate mp = IRR_CON_AutomatedCommunication.getAutomatedTemplates(message.IRR_Template_Name__c);
                IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
                automatedRequest.passengerInfos = PaxInfo;
                automatedRequest.sendSMSMessages = true;
                automatedRequest.sendEmailMessages = false;
                automatedRequest.emailTemplate = mp.emailTemplate;
                automatedRequest.smsTemplate = mp.smsTemplate;
                IRR_CON_AutomatedCommunication.sendAutomatedCommunication(automatedRequest);
        
            }
        }   
    }
        

    global override void finishOverridable(Database.BatchableContext bc){
        
    }

    global void execute(SchedulableContext ctx) {
        SBS_ScheduledBatch processAutomated = new IRR_BCH_FetchPaxInfoAutomatedMessage ();
        ID batchprocessid = Database.executeBatch(processAutomated,1);
    }
    
}
