/**
    Batch class which ensures that all manual queued messages are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_BCH_ScheduledEvent extends SBS_ScheduledBatch implements Schedulable {
  private String eventType = 'manualCommunication';
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
      .getQueuedManualQueryLocator();
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
    Map<Id, String> bodyAsStringByLinkedEntityId = IRR_SVC_LogsService.getFilesforEventLogs(
      sObjScope
    );
    for (Id evId : bodyAsStringByLinkedEntityId.keySet()) {
      String payload = bodyAsStringByLinkedEntityId.get(evId);
      IRR_MOD_ManualRequest cInfo = (IRR_MOD_ManualRequest) JSON.deserialize(
        payload,
        IRR_MOD_ManualRequest.class
      );
      cInfo.sendMessageTime = null;
      IRR_SVC_CommunicationService.processEvent(eventType, cInfo);
    }

    delete sObjScope;
  }

  global override void finishOverridable(Database.BatchableContext bc) {
  }

  global void execute(SchedulableContext ctx) {
    SBS_ScheduledBatch processQueuedManual = new IRR_BCH_ScheduledEvent();
    ID batchprocessid = Database.executeBatch(processQueuedManual, 1);
  }
}