public without sharing class Settlements extends fflib_SObjectDomain {
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();

  public Settlements(List<SObject> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Settlements(records);
    }
  }

  public static Settlements newInstance(List<Settlement__c> sObjectList) {
    return (Settlements) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public void markAsSentToRacer(String paymentFilename) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsSentToRacer(paymentFilename, uow);
    uow.commitWork();
  }

  public void markAsSentToRacer(
    String paymentFilename,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement__c s : (List<Settlement__c>) Records) {
      s.Payment_File_Name__c = paymentFilename;
      s.Settlement_Status__c = 'Sent to Racer';
      uow.registerDirty(s);
    }
  }

  public void markAsReceivedByBank(String bankStatus, String errorMessage) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsReceivedByBank(bankStatus, errorMessage, uow);
    uow.commitWork();
  }

  public void markAsReceivedByBank(
    String bankStatus,
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    if (bankStatus == 'ACCEPTED') {
      Set<Id> acceptedSettlementIds = new Set<Id>();

      for (Settlement__c s : (List<Settlement__c>) Records) {
        s.Settlement_Status__c = 'Accepted by Bank/Done';
        uow.registerDirty(s);
        acceptedSettlementIds.add(s.Id);
      }

      List<Settlement_Item__c> correspondingSettlements = settlementItemsSel.selectBySettlementIds(
        acceptedSettlementIds
      );
      SettlementItems.newInstance(correspondingSettlements)
        .markAsReadyForTransfer(uow);
    } else {
      for (Settlement__c s : (List<Settlement__c>) Records) {
        s.Settlement_Status__c = 'Rejected by Bank';
        s.Error_Message__c = errorMessage;
        uow.registerDirty(s);
      }
      C_Log.log(
        C_Log.Severity.Error,
        'Settlements rejected by bank with error: ' + errorMessage,
        null,
        'RACER',
        null
      );
    }
  }

  public void markAsReceivedByRacer(String racerStatus, String errorMessage) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsReceivedByRacer(racerStatus, errorMessage, uow);
    uow.commitWork();
  }

  public void markAsReceivedByRacer(
    String racerStatus,
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    if (racerStatus == 'PROCESSED') {
      for (Settlement__c s : (List<Settlement__c>) Records) {
        s.Settlement_Status__c = 'Accepted by Racer';
        uow.registerDirty(s);
      }
    } else {
      for (Settlement__c s : (List<Settlement__c>) Records) {
        s.Settlement_Status__c = 'Rejected by Racer';
        s.Error_Message__c = errorMessage;
        uow.registerDirty(s);
      }
      C_Log.log(
        C_Log.Severity.Error,
        'Settlements rejected by Racer: ' + errorMessage,
        null,
        'RACER',
        null
      );
    }
  }

  public void markAsFailedPayment(String errorMessage) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsFailedPayment(errorMessage, uow);
    uow.commitWork();
  }

  public void markAsFailedPayment(
    String errorMessage,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement__c s : (List<Settlement__c>) Records) {
      s.Settlement_Status__c = 'L2 errors by Bank';
      s.Error_Message__c = errorMessage;
      uow.registerDirty(s);
    }
    C_Log.log(
      C_Log.Severity.Error,
      'Rejected by bank with error: ' + errorMessage,
      null,
      'RACER',
      null
    );
  }
}
