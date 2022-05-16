public without sharing class Settlements extends fflib_SObjectDomain {
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();
  private static ExchangeRatesSelector exchangeRatesSel = ExchangeRatesSelector.newInstance();

  public Settlements(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Settlement__c>) Records;
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

  private List<Settlement__c> instanceRecords;

  public enum RecordType {
    Cheque,
    EBPoints,
    Monetary,
    Voucher
  }

  public static Map<RecordType, String> recordTypeToDeveloperName = new Map<RecordType, String>{
    RecordType.Cheque => 'Cheque',
    RecordType.EBPoints => 'EB points',
    RecordType.Monetary => 'Monetary',
    RecordType.Voucher => 'Voucher'
  };

  private static Map<RecordType, Id> recordTypeToId = new Map<RecordType, String>();

  public static Id getRecordTypeId(RecordType rt) {
    Id rtId = recordTypeToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.Settlement__c.getRecordTypeInfosByName()
        .get(recordTypeToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeToId.put(rt, rtId);
    }
    return rtId;
  }

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
  public static final String STATUS_FAILED_PROCESSED = 'Failed - Processed';

  private static final Integer INSURANCE_DEDUCTIBLE_BAGGAGE = 1250;
  private static final Integer INSURANCE_DEDUCTIBLE_PERSONAL_INJURY = 0;

  private static final Set<String> COST_ACCOUNTS_BAGGAGE = new Set<String>{
    '6741',
    '6742',
    '6743'
  };

  public static final String COST_ACCOUNT_CREDIT = '1654';
  public static final String COST_ACCOUNT_INSURANCE = '1662';
  public static final String COST_ACCOUNT_LIABILITY_OTHER = '6735';

  public static final String COST_CENTER_DEBITS = '90801';

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    processPayableVoucherAndEuroBonusSettlements();
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
    Set<Id> settlementIds = new Set<Id>();
    for (Settlement__c s : instanceRecords) {
      s.Payment_File_Name__c = paymentFilename;
      s.Settlement_Status__c = STATUS_SENT_TO_RACER;
      uow.registerDirty(s);
      settlementIds.add(s.Id);
    }

    List<Settlement_Item__c> correspondingSettlements = settlementItemsSel.selectBySettlementIds(
      settlementIds
    );

    SettlementItems.newInstance(correspondingSettlements)
      .markAsPendingL1Confirmation(uow);
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

      for (Settlement__c s : instanceRecords) {
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
      for (Settlement__c s : instanceRecords) {
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
      for (Settlement__c s : instanceRecords) {
        s.Settlement_Status__c = STATUS_SENT_TO_BANK;
        uow.registerDirty(s);
      }
    } else {
      for (Settlement__c s : instanceRecords) {
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

  public void markAsFailedPayment(
    Map<Id, String> settlementIdsToErrorMessages
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsFailedPayment(settlementIdsToErrorMessages, uow);
    uow.commitWork();
  }

  /**
   * Marks the given settlements as failed due to an L2 failure.
   *
   * If a settlement fails at L2 level, it should not be reprocessed. Instead a
   * new settlement needs to be created.
   *
   * Settlement items should be changed to "Settlement failed" status if they
   * are still in Draft status.
   *
   * Expected to be used when we receive an L2 file from Racer.
   */
  public void markAsFailedPayment(
    Map<Id, String> settlementIdsToErrorMessages,
    fflib_ISObjectUnitOfWork uow
  ) {
    for (Settlement__c s : instanceRecords) {
      s.Settlement_Status__c = STATUS_FAILED;
      s.Error_Message__c = settlementIdsToErrorMessages.get(s.Id);
      uow.registerDirty(s);

      C_Log.log(
        C_Log.Severity.Warning,
        'Settlement ' +
        s.Name +
        ' was rejected by bank with error: ' +
        settlementIdsToErrorMessages.get(s.Id),
        null,
        'Settlements',
        null
      );
    }

    List<Settlement_Item__c> correspondingSettlementItems = settlementItemsSel.selectBySettlementIds(
      settlementIdsToErrorMessages.keySet()
    );

    SettlementItems.newInstance(correspondingSettlementItems)
      .markAsSettlementFailed(uow);
  }

  public void markAsDone(String reference) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsDone(reference, uow);
    uow.commitWork();
  }

  public void markAsDone(String reference, fflib_ISObjectUnitOfWork uow) {
    for (Settlement__c s : instanceRecords) {
      if (
        s.Settlement_Status__c != STATUS_FAILED &&
        s.Settlement_Status__c != STATUS_FAILED_PROCESSED
      ) {
        // Failed settlements should never be reprocessed. At least payment
        // acceptance files can be received out of order so that we first
        // receive the L2 failure for a settlement and after that the
        // acceptance file. Even this order should leave the settlements as
        // failed.

        s.Settlement_Status__c = STATUS_DONE;
        s.External_Reference__c = reference;
        uow.registerDirty(s);
      }
    }
  }

  public void markAsFailed(String errorMessage) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    markAsFailed(errorMessage, uow);
    uow.commitWork();
  }

  public void markAsFailed(String errorMessage, fflib_ISObjectUnitOfWork uow) {
    for (Settlement__c s : instanceRecords) {
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
   * Locks a list of settlements.
   *
   * Locks also all settlement items related to this settlement.
   */
  public void lock() {
    List<Settlement_Item__c> settlementItemsForInstanceRecords = settlementItemsSel.selectBySettlementIds(
      (new Map<Id, Settlement__c>(instanceRecords)).keySet()
    );
    Approval.lock(instanceRecords);
    Approval.lock(settlementItemsForInstanceRecords);
  }

  /**
   * Unlocks a list of settlements.
   *
   * Unlocks also all settlement items related to this settlement.
   */
  public void unlock() {
    List<Settlement_Item__c> settlementItemsForInstanceRecords = settlementItemsSel.selectBySettlementIds(
      (new Map<Id, Settlement__c>(instanceRecords)).keySet()
    );
    Approval.unlock(instanceRecords);
    Approval.unlock(settlementItemsForInstanceRecords);
  }

  public class UpdateSettlementException extends Exception {
  }

  /**
   * Updates the list of settlement items for this settlement. Upserts the
   * given items and removes all settlement items related to the settlement,
   * but not included in the given items.
   *
   * Also updates the settlement total and currency conversion calculations.
   *
   * @param itemsToUpsert Full list of settlement items this settlement should have the operation.
   */
  public Map<Id, List<Settlement_Item__c>> updateSettlementItems(
    Map<Id, List<Settlement_Item__c>> itemsToUpsert,
    fflib_ISObjectUnitOfWork uow
  ) {
    Set<Id> parentClaimIds = new Set<Id>();
    for (Settlement__c settlement : instanceRecords) {
      if (
        settlement.RecordTypeId !=
        getRecordTypeId(Settlements.RecordType.EBPoints) &&
        settlement.Currency__c == null
      ) {
        throw new UpdateSettlementException(
          'Set currency before trying to update settlement items.'
        );
      }

      Boolean canBeModified =
        settlement.Settlement_Status__c == STATUS_IN_PROGRESS ||
        settlement.Settlement_Status__c == STATUS_DENIED;

      if (!canBeModified) {
        throw new UpdateSettlementException(
          'Settlement status must be in progress or denied to update settlement items.'
        );
      }
      parentClaimIds.add(settlement.Claim__c);
    }

    Map<Id, LIA_Claim__c> parentClaimsById = new Map<Id, LIA_Claim__c>(
      ClaimsSelector.newInstance().selectById(parentClaimIds)
    );
    Map<String, Exchange_Rate__c> exchangeRatesToSEK = new Map<String, Exchange_Rate__c>();
    Map<String, Exchange_Rate__c> exchangeRatesFromUSD = new Map<String, Exchange_Rate__c>();

    for (Exchange_Rate__c er : exchangeRatesSel.selectByToCurrency('SEK')) {
      exchangeRatesToSEK.put(er.From_Currency__c, er);
    }

    for (Exchange_Rate__c er : exchangeRatesSel.selectByFromCurrency('USD')) {
      exchangeRatesFromUSD.put(er.To_Currency__c, er);
    }

    markRemovedSettlementItemsForDeletion(itemsToUpsert, uow);

    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Id != null) {
        uow.registerDirty(settlement);
      }

      Decimal sumOfLineItems = 0;

      for (Settlement_Item__c item : itemsToUpsert.get(settlement.Id)) {
        if (item.Id == null) {
          uow.registerNew(item, Settlement_Item__c.Settlement__c, settlement);
        } else {
          uow.registerDirty(item);
        }

        item.Cost_Center__c = COST_CENTER_DEBITS;
        item.Currency__c = settlement.Currency__c;
        item.Status__c = SettlementItems.STATUS_DRAFT;

        if (
          settlement.RecordTypeId ==
          getRecordTypeId(Settlements.RecordType.Voucher)
        ) {
          // Voucher cost accounts can be set automatically based on voucher type.
          item.Cost_Account__c = voucherTypeToCostAccount.get(
            settlement.Voucher_Type__c
          );
        }

        sumOfLineItems += item.Amount__c;
      }

      updateInsuranceForSettlementItems(
        itemsToUpsert.get(settlement.id),
        settlement,
        parentClaimsById.get(settlement.Claim__c),
        exchangeRatesFromUSD
      );

      updateSettlementTotal(settlement, sumOfLineItems, exchangeRatesToSEK);
    }

    return itemsToUpsert;
  }

  /**
   * Given a list of new settlement items, marks all settlements items for
   * instance records for deletion if they do not exist in the given
   * itemsToUpsert.
   */
  private void markRemovedSettlementItemsForDeletion(
    Map<Id, List<Settlement_Item__c>> itemsToUpsert,
    fflib_ISObjectUnitOfWork uow
  ) {
    Set<Id> settlementIds = new Set<Id>();
    for (Settlement__c s : instanceRecords) {
      if (s.Id != null) {
        settlementIds.add(s.Id);
      }
    }
    if (settlementIds.size() == 0) {
      // Nothing to remove if the settlements don't exist yet.
      return;
    }

    List<Settlement_Item__c> allExistingSettlementItems = settlementItemsSel.selectBySettlementIds(
      settlementIds
    );

    Map<Id, List<Settlement_Item__c>> existingSettlementItemsBySettlement = new Map<Id, List<Settlement_Item__c>>();

    for (Settlement_Item__c si : allExistingSettlementItems) {
      List<Settlement_Item__c> existing = existingSettlementItemsBySettlement.get(
        si.Settlement__c
      );
      if (existing == null) {
        existingSettlementItemsBySettlement.put(
          si.Settlement__c,
          new List<Settlement_Item__c>{ si }
        );
      } else {
        existing.add(si);
      }
    }
    for (Id settlementId : settlementIds) {
      // If we have an existing settlement, we need to check if any of the
      // existing settlements should be deleted and mark them for deletion if
      // so.
      List<Settlement_Item__c> existingItems = settlementItemsSel.selectBySettlementIds(
        new Set<Id>{ settlementId }
      );

      for (Settlement_Item__c existingItem : existingItems) {
        Boolean found = false;
        for (Settlement_Item__c newItem : itemsToUpsert.get(settlementId)) {
          if (newItem.Id == existingItem.Id) {
            found = true;
            break;
          }
        }
        if (!found) {
          uow.registerDeleted(existingItem);
        }
      }
    }
  }

  /**
   * Updates the settlement amount fields for the given settlement based on the
   * given sum of line items. Handles currency conversion calculation to SEK
   * for Settlement_amount_in_SEK__c field.
   */
  private void updateSettlementTotal(
    Settlement__c settlement,
    Decimal sumOfLineItems,
    Map<String, Exchange_Rate__c> exchangeRatesToSEK
  ) {
    if (
      settlement.RecordTypeId ==
      getRecordTypeId(Settlements.RecordType.EBPoints)
    ) {
      settlement.EuroBonus_Points__c = sumOfLineItems;
    } else {
      settlement.Amount__c = sumOfLineItems;
      if (settlement.Currency__c == 'SEK') {
        settlement.Settlement_amount_in_SEK__c = sumOfLineItems;
        settlement.Date_of_Exchange_Calculation__c = Date.today();
      } else {
        Exchange_Rate__c exchangeRateToSEK = exchangeRatesToSEK.get(
          settlement.Currency__c
        );

        if (exchangeRateToSEK != null) {
          // There should always be exactly one, but just in case we lose exchange rate data, let's check.
          settlement.Settlement_amount_in_SEK__c =
            sumOfLineItems * exchangeRateToSEK.Rate__c;
          settlement.Date_of_Exchange_Calculation__c = exchangeRateToSEK
            .Date__c;
        }
      }
    }
  }

  /**
   * Marks the settlement item as insured and calculates the claimable amount
   * from SAS's insurance company after deductible. Updates the record which
   * was passed in.
   *
   * @return The same list with the updated settlement items.
   */
  private List<Settlement_Item__c> updateInsuranceForSettlementItems(
    List<Settlement_Item__c> items,
    Settlement__c settlement,
    LIA_Claim__c claim,
    Map<String, Exchange_Rate__c> exchangeRatesFromUSD
  ) {
    Boolean isAMonetaryClaim =
      Settlement.RecordTypeId ==
      getRecordTypeId(Settlements.RecordType.Cheque) ||
      settlement.RecordTypeId ==
      getRecordTypeId(Settlements.RecordType.Monetary);

    Boolean isAnInsuredClaimType = isAMonetaryClaim;
    // Only monetary payments are claimed from insurance.
    if (!isAnInsuredClaimType) {
      return items;
    }

    // We're making an assumption here that there is never a settlement which contains
    // both baggage and personal injure claims.
    Decimal deductible;

    Boolean isPersonalInjuryClaim =
      claim.Customer_Claim_Type__c == 'Personal injury';

    if (isPersonalInjuryClaim) {
      deductible = INSURANCE_DEDUCTIBLE_PERSONAL_INJURY;
    } else {
      deductible = INSURANCE_DEDUCTIBLE_BAGGAGE;
    }

    Map<String, List<Settlement_Item__c>> customerNamesToSettlementItems = new Map<String, List<Settlement_Item__c>>();
    for (Settlement_Item__c item : items) {
      // Group settlement items by customer as deductible is by customer.
      List<Settlement_Item__c> existingItemsForCustomer = customerNamesToSettlementItems.get(
        item.Customer_Name__c
      );
      if (existingItemsForCustomer == null) {
        customerNamesToSettlementItems.put(
          item.Customer_Name__c,
          new List<Settlement_Item__c>{ item }
        );
      } else {
        existingItemsForCustomer.add(item);
      }
    }

    if (settlement.Currency__c != 'USD') {
      // Deductible amounts are defined in USD so we need to convert them to
      // settlement currency if it isn't USD.
      Exchange_Rate__c exchangeRateFromUSD = exchangeRatesFromUSD.get(
        settlement.Currency__c
      );
      if (exchangeRateFromUSD != null) {
        deductible = (deductible * exchangeRateFromUSD.Rate__c).setScale(2);
      } else {
        C_Log.log(
          C_Log.Severity.Error,
          'Failed to fetch exchange rate from: ' +
          settlement.Currency__c +
          ' to USD.',
          null,
          'Settlements',
          null
        );
      }
    }

    for (String c : customerNamesToSettlementItems.keySet()) {
      // Deductible is per customer.
      Decimal totalDeductionForThisCustomer = 0;

      for (Settlement_Item__c item : customerNamesToSettlementItems.get(c)) {
        Boolean isPersonalInjuryClaimAndAccount =
          isPersonalInjuryClaim &&
          item.Cost_Account__c == COST_ACCOUNT_LIABILITY_OTHER;
        Boolean isBaggageAccount = COST_ACCOUNTS_BAGGAGE.contains(
          item.Cost_Account__c
        );
        Boolean isInsured = isBaggageAccount || isPersonalInjuryClaimAndAccount;
        if (isInsured) {
          item.Is_Insured__c = true;

          Decimal maximumDeductionLeft =
            deductible - totalDeductionForThisCustomer;
          Decimal toDeduct = Math.min(maximumDeductionLeft, item.Amount__c);

          item.Net_Amount_After_Deductible__c = item.Amount__c - toDeduct;
          totalDeductionForThisCustomer += toDeduct;
        }
      }
    }

    return items;
  }

  private void processPayableVoucherAndEuroBonusSettlements() {
    for (Settlement__c settlement : instanceRecords) {
      if (settlement.Settlement_Status__c == STATUS_WAITING_FOR_TRANSFER) {
        if (
          settlement.RecordTypeId ==
          getRecordTypeId(Settlements.RecordType.EBPoints)
        ) {
          SettlementService.sendEuroBonusPoints(settlement.Id);
        } else if (
          settlement.RecordTypeId ==
          getRecordTypeId(Settlements.RecordType.Voucher)
        ) {
          SettlementService.createAndSendVoucher(settlement.Id);
        }
      }
    }
  }
}
