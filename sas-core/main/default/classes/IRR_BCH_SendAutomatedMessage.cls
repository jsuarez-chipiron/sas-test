/**
    Batch class which ensures that all automated messages are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_BCH_SendAutomatedMessage extends SBS_ScheduledBatch implements Schedulable {
  /**
   overriding the absract method to set batch class Params
   */
  global override void setVariables(
    String obj,
    Integer wipingPeriod,
    string caseField,
    string caseType,
    string batchName
  ) {
  }
  /**
        Iterates over all Automatedmessage metadata for Automated communication
        @param bc The batch context
    */

  global Database.QueryLocator start(Database.BatchableContext bc) {
    // string query =  'SELECT IRR_Departure_Country__c,IRR_Arrival_Country__c,IRR_Duration__c,IRR_Template_Name__c FROM IRR_AutomatedMessage__mdt ';
    this.setUseTransactionControl(false);
    // return Database.getQueryLocator(query);
    return IRR_SEL_AutomatedMessagesSelector.newInstance()
      .selectAutomatedMessages();
  }

  /**
        Processes the Automatedmessage custom metadata and prepares the Automatedrequest payload
        @param bc The batchable context of the batch job
        @param sObjScope The Automatedmessage custom metadata to process
    */
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    for (
      IRR_AutomatedMessage__mdt message : (List<IRR_AutomatedMessage__mdt>) sObjScope
    ) {
      if (
        message.IRR_Duration__c != null &&
        message.IRR_Departure_Country__c != null
      ) {
        List<IRR_MOD_PassengerInfo> PaxInfo = IRR_CON_AutomatedCommunication.getPassengerInfos(
          message.IRR_Departure_Country__c,
          message.IRR_Arrival_Country__c,
          message.IRR_Duration__c
        );
        IRR_CON_AutomatedCommunication.ManualTemplate mp = IRR_CON_AutomatedCommunication.getManualTemplates(
          message.IRR_Template_Name__c
        );
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        automatedRequest.passengerInfos = PaxInfo;
        automatedRequest.sendSMSMessages = message.IRR_Template_Name__c.contains('sms')?true:false;
        automatedRequest.sendEmailMessages = message.IRR_Template_Name__c.contains('email')?true:false;
        automatedRequest.emailTemplate = mp.emailTemplate;
        automatedRequest.smsTemplate = mp.smsTemplate;
        IRR_CON_AutomatedCommunication.sendAutomatedCommunication(
          automatedRequest
        );
      }
    }
  }

  global override void finishOverridable(Database.BatchableContext bc) {
  }

  global void execute(SchedulableContext ctx) {
    SBS_ScheduledBatch processAutomated = new IRR_BCH_SendAutomatedMessage();
    ID batchprocessid = Database.executeBatch(processAutomated, 1);
  }
}
