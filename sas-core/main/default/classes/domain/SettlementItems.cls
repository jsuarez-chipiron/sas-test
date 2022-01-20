public without sharing class SettlementItems extends fflib_SObjectDomain {
  public SettlementItems(List<SObject> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new SettlementItems(records);
    }
  }

  public static SettlementItems newInstance(
    List<Settlement_Item__c> sObjectList
  ) {
    return (SettlementItems) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public void markAsReceivedByRacer(
    String accountingStatus,
    String errorMessage
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsReceivedByRacer(accountingStatus, errorMessage, uow);
    uow.commitWork();
  }

  public void markAsReceivedByRacer(
    String accountingStatus,
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    if (accountingStatus == 'PROCESSED') {
      for (Settlement_Item__c s : (List<Settlement_Item__c>) Records) {
        s.Status__c = 'Done';
        uow.registerDirty(s);
      }
    } else {
      for (Settlement_Item__c s : (List<Settlement_Item__c>) Records) {
        s.Status__c = 'Rejected by Racer';
        s.Error_Message__c = errorMessage;
        uow.registerDirty(s);
      }
      C_Log.log(
        C_Log.Severity.Error,
        'Accounting entries rejected by Racer with error: ' + errorMessage,
        null,
        'RACER',
        null
      );
    }
  }

  public void markAsReadyForTransfer() {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsReadyForTransfer(uow);
    uow.commitWork();
  }

  public void markAsReadyForTransfer(fflib_ISObjectUnitOfWork uow) {
    for (Settlement_Item__c s : (List<Settlement_Item__c>) Records) {
      s.Status__c = 'Waiting for transfer';
      uow.registerDirty(s);
    }
  }

  public void markAsSentToRacer(String accountingFilename) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsSentToRacer(accountingFilename, uow);
    uow.commitWork();
  }

  public void markAsSentToRacer(
    String accountingFilename,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement_Item__c s : (List<Settlement_Item__c>) Records) {
      s.Accounting_File_Name__c = accountingFilename;
      s.Status__c = 'Sent to Racer';
      uow.registerDirty(s);
    }
  }
}
