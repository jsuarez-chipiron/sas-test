public without sharing class Settlements extends fflib_SObjectDomain {
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();

  public Settlements(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Settlement__c>) Records;
  }

  private List<Settlement__c> instanceRecords;

  private static final Map<String, String> voucherTypeToCostAccount = new Map<String, String>{
    '6721 - Denied boarding involuntary voucher' => '6721',
    '6721 - Denied boarding voluntary voucher' => '6721',
    '6722 - Downgrading involuntary voucher' => '6722',
    '6722 - Downgrading voluntary voucher' => '6722',
    '6727 - EU261 voucher' => '6727',
    '6738 - Care voucher' => '6738',
    '6741 - Damaged baggage voucher' => '6741',
    '6742 - Delayed baggage voucher' => '6742',
    '6733 - Goodwill voucher' => '6733',
    '6743 - Pilfered baggage voucher' => '6743'
  };

  public static final Map<String, VoucherIntegrationService.VoucherSubType> VOUCHER_TYPE_STRING_TO_VOUCHER_SUBTYPE = new Map<String, VoucherIntegrationService.VoucherSubType>{
    '6721 - Denied boarding involuntary voucher' => VoucherIntegrationService.VoucherSubType.IDBCOMP,
    '6721 - Denied boarding voluntary voucher' => VoucherIntegrationService.VoucherSubType.VDBCOMP,
    '6722 - Downgrading involuntary voucher' => VoucherIntegrationService.VoucherSubType.IDGCOMP,
    '6722 - Downgrading voluntary voucher' => VoucherIntegrationService.VoucherSubType.VDGCOMP,
    '6727 - EU261 voucher' => VoucherIntegrationService.VoucherSubType.EU261,
    '6738 - Care voucher' => VoucherIntegrationService.VoucherSubType.CARE,
    '6741 - Damaged baggage voucher' => VoucherIntegrationService.VoucherSubType.DAMAGEBAG,
    '6742 - Delayed baggage voucher' => VoucherIntegrationService.VoucherSubType.DELAYEDBAG,
    '6733 - Goodwill voucher' => VoucherIntegrationService.VoucherSubType.GOODWILL,
    '6743 - Pilfered baggage voucher' => VoucherIntegrationService.VoucherSubType.PILFBAG
  };

  public static final String STATUS_IN_PROGRESS = 'In progress';
  public static final String STATUS_WAITING_FOR_APPROVAL = 'Waiting for approval';
  public static final String STATUS_WAITING_FOR_CONTROL = 'Waiting for control';
  public static final String STATUS_DENIED = 'Denied';
  public static final String STATUS_WAITING_FOR_TRANSFER = 'Waiting for transfer';
  public static final String STATUS_SENT_TO_RACER = 'Sent to Racer';
  public static final String STATUS_REJECTED_BY_RACER = 'Rejected by Racer';
  public static final String STATUS_SENT_TO_BANK = 'Sent to bank';
  public static final String STATUS_REJECTED_BY_BANK = 'Rejected by bank';
  public static final String STATUS_DONE = 'Done';
  public static final String STATUS_FAILED = 'Failed';

  public static final Id VOUCHER_RECORD_TYPE_ID = Schema.SObjectType.Settlement__c.getRecordTypeInfosByName()
    .get('Voucher')
    .getRecordTypeId();
  public static final Id EUROBONUS_POINTS_RECORD_TYPE_ID = Schema.SObjectType.Settlement__c.getRecordTypeInfosByName()
    .get('EB points')
    .getRecordTypeId();

  private static ExchangeRatesSelector exchangeRatesSel = ExchangeRatesSelector.newInstance();

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
      s.Settlement_Status__c = STATUS_SENT_TO_RACER;
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
        s.Settlement_Status__c = STATUS_DONE;
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
        s.Settlement_Status__c = STATUS_REJECTED_BY_BANK;
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
        s.Settlement_Status__c = STATUS_SENT_TO_BANK;
        uow.registerDirty(s);
      }
    } else {
      for (Settlement__c s : (List<Settlement__c>) Records) {
        s.Settlement_Status__c = STATUS_REJECTED_BY_RACER;
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
      s.Settlement_Status__c = STATUS_FAILED;
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
      s.Settlement_Status__c = STATUS_DONE;
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
      s.Settlement_Status__c = STATUS_FAILED;
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

  /**
   * Updates the list of settlement items for this settlement. Upserts the
   * given items and removes all settlement items not list in the given
   * items.
   *
   * Also updates the settlement total and currency conversion calculations.
   *
   * @param itemsToUpsert Full list of settlement items this settlement should have the operation.
   */
  public Boolean updateSettlementItems(List<Settlement_Item__c> itemsToUpsert) {
    if (instanceRecords.size() > 1) {
      return false;
    }
    Settlement__c settlement = instanceRecords[0];

    // TODO: Verify that settlement can be updated. (Not locked and status is good to go, maybe?)
    // TODO: Do we need to check locked status also here? Probably yes.
    Boolean canBeModified =
      settlement.Settlement_Status__c == STATUS_IN_PROGRESS;
    if (canBeModified) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

      List<Settlement_Item__c> existingItems = settlementItemsSel.selectBySettlementIds(
        new Set<Id>{ settlement.Id }
      );

      for (Settlement_Item__c existingItem : existingItems) {
        Boolean found = false;
        for (Settlement_Item__c newItem : itemsToUpsert) {
          if (newItem.Id == existingItem.Id) {
            found = true;
          }
        }
        if (!found) {
          uow.registerDeleted(existingItem);
        }
      }

      Decimal settlementTotal = 0;
      for (Settlement_Item__c item : itemsToUpsert) {
        item.Cost_Center__c = '90801';
        item.Currency__c = settlement.Currency__c;
        item.Status__c = SettlementItems.STATUS_DRAFT;
        item.Settlement__c = settlement.Id;

        if (settlement.RecordTypeId == VOUCHER_RECORD_TYPE_ID) {
          // Voucher cost accounts can be set automatically based on voucher type.
          item.Cost_Account__c = voucherTypeToCostAccount.get(
            settlement.Voucher_Type__c
          );
        }

        settlementTotal += item.Amount__c;
      }
      uow.registerUpsert(itemsToUpsert);

      Exchange_Rate__c exchangeRateToSEK = exchangeRatesSel.selectByCurrency(
        settlement.Currency__c,
        'SEK'
      )[0];

      if (settlement.RecordTypeId == EUROBONUS_POINTS_RECORD_TYPE_ID) {
        settlement.EuroBonus_Points__c = settlementTotal;
      } else {
        settlement.Amount__c = settlementTotal;
        settlement.Settlement_amount_in_SEK__c =
          settlementTotal * exchangeRateToSEK.Rate__c;
      }
      settlement.Date_of_Exchange_Calculation__c = exchangeRateToSEK.Date__c;
      uow.registerDirty(settlement);
      uow.commitWork();
      return true;
    }

    return false;
  }

  private void processPayableVoucherAndEuroBonusSettlements() {
    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Settlement_Status__c == STATUS_WAITING_FOR_TRANSFER) {
        if (settlement.RecordTypeId == EUROBONUS_POINTS_RECORD_TYPE_ID) {
          SettlementService.sendEuroBonusPoints(settlement.Id);
        } else if (settlement.RecordTypeId == VOUCHER_RECORD_TYPE_ID) {
          SettlementService.createAndSendVoucher(settlement.Id);
        }
      }
    }
  }
}
