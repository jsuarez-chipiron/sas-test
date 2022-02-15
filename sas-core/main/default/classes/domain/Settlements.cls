public without sharing class Settlements extends fflib_SObjectDomain {
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();

  public Settlements(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Settlement__c>) Records;
  }

  private List<Settlement__c> instanceRecords;
  public static final Id VOUCHER_RECORD_TYPE_ID = Schema.SObjectType.Settlement__c.getRecordTypeInfosByName()
    .get('Voucher')
    .getRecordTypeId();
  public static final Id EUROBONUS_POINTS_RECORD_TYPE_ID = Schema.SObjectType.Settlement__c.getRecordTypeInfosByName()
    .get('EB points')
    .getRecordTypeId();

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Settlements(records);
    }
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    processPayableVoucherAndEuroBonusSettlements();
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
        'Settlements',
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
        'Settlements',
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
      'Settlements',
      null
    );
  }

  public void markAsDone(String reference) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsDone(reference, uow);
    uow.commitWork();
  }

  public void markAsDone(String reference, fflib_ISObjectUnitOfWork uow) {
    for (Settlement__c s : (List<Settlement__c>) Records) {
      s.Settlement_Status__c = 'Done';
      s.External_Reference__c = reference;
      uow.registerDirty(s);
    }
  }

  public void markAsFailed(String errorMessage) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsFailed(errorMessage, uow);
    uow.commitWork();
  }

  public void markAsFailed(String errorMessage, fflib_ISObjectUnitOfWork uow) {
    for (Settlement__c s : (List<Settlement__c>) Records) {
      s.Settlement_Status__c = 'Failed';
      s.Error_Message__c = errorMessage;
      uow.registerDirty(s);
    }
    C_Log.log(
      C_Log.Severity.Error,
      'Settlement denied: ' + errorMessage,
      null,
      'Settlements',
      null
    );
  }

  private void processPayableVoucherAndEuroBonusSettlements() {
    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Settlement_Status__c == 'Waiting for transfer') {
        if (settlement.RecordTypeId == EUROBONUS_POINTS_RECORD_TYPE_ID) {
          // future eb request
          SettlementService.sendEuroBonusPoints(settlement.Id);
        } else if (settlement.RecordTypeId == VOUCHER_RECORD_TYPE_ID) {
          // future voucher request
          SettlementService.createAndSendVoucher(settlement.Id);
        }
      }
    }
  }
}
