public without sharing class SettlementService {
  private static ContentVersionsSelector contentVersions = ContentVersionsSelector.newInstance();
  private static SettlementsSelector settlementsSel = SettlementsSelector.newInstance();
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();
  private static RacerIntegrationCountersSelector racerIntegrationCounters = RacerIntegrationCountersSelector.newInstance();
  private static CLMIntegrationService IntegrationService = CLMIntegrationService.newInstance();
  private static VoucherIntegrationService VouchersService = VoucherIntegrationService.newInstance();

  public class SettlementsException extends Exception {
  }

  /**
   * Create a batch file from all settlements waiting for transfer to Racer
   * for the given currency.
   */
  public static void createPaymentFile(
    PaymentFileBuilder.PaymentCurrency fileCurrency
  ) {
    List<String> currencies;
    if (fileCurrency != PaymentFileBuilder.PaymentCurrency.OTH) {
      currencies = new List<String>{ fileCurrency.name() };
    } else {
      currencies = new List<String>{
        'AUD',
        'EUR',
        'GBP',
        'CAD',
        'CZK',
        'HKD',
        'JPY',
        'NZD',
        'PLN',
        'SGD',
        'CHF'
      };
    }
    List<Settlement__c> settlementsToSend = settlementsSel.selectWaitingForTransferByCurrency(
      currencies
    );

    if (settlementsToSend.isEmpty()) {
      // Nothing to process. Let's log so we know we tried and do nothing else.
      C_Log.log(
        C_Log.Severity.Info,
        'SettlementService.createPaymentFile# No settlements found for: ' +
        fileCurrency.name(),
        null,
        'Settlements',
        null
      );
      return;
    }

    List<PaymentEntry> paymentEntries = new List<PaymentEntry>();
    Racer_Integration_Counter__c counter = racerIntegrationCounters.selectByCurrency(
      fileCurrency.name()
    )[0];

    for (Settlement__c s : settlementsToSend) {
      paymentEntries.add(new PaymentEntry(s));
    }
    Id textFileHandle = PaymentFileBuilder.create(
      paymentEntries,
      fileCurrency,
      counter.Payment_Run_Id__c
    );

    ContentVersion paymentFile = contentVersions.selectById(
      new Set<Id>{ textFileHandle }
    )[0];

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    Settlements.newInstance(settlementsToSend) // TODO: Think about if this should be moved to the sending functions.
      .markAsSentToRacer(paymentFile.Title, uow);

    counter.Payment_Run_Id__c += 1;
    uow.registerDirty(counter);
    uow.commitWork();
  }

  /**
   * Creates a batch file for all settlement items waiting to be sent to
   * Racer for the given currency.
   */
  public static void createAccountingFile(
    AccountingFileBuilder.PaymentCurrency fileCurrency
  ) {
    Racer_Integration_Counter__c counter = racerIntegrationCounters.selectByCurrency(
      fileCurrency.name()
    )[0];

    List<String> currencies;
    if (fileCurrency != AccountingFileBuilder.PaymentCurrency.OTH) {
      currencies = new List<String>{ fileCurrency.name() };
    } else {
      currencies = new List<String>{
        'AUD',
        'EUR',
        'GBP',
        'CAD',
        'CZK',
        'HKD',
        'JPY',
        'NZD',
        'PLN',
        'SGD',
        'CHF',
        'USD'
      };
    }

    List<Settlement_Item__c> settlementItemsToSend = settlementItemsSel.selectWaitingForTransferByCurrency(
      currencies
    );

    if (settlementItemsToSend.isEmpty()) {
      // Nothing to process. Let's log so we know we tried and do nothing else.
      C_Log.log(
        C_Log.Severity.Info,
        'SettlementService.createAccountingFile# No settlement items found for: ' +
        fileCurrency.name(),
        null,
        'Settlements',
        null
      );
      return;
    }

    List<AccountingEntry> accountingEntries = new List<AccountingEntry>();

    for (Settlement_Item__c s : settlementItemsToSend) {
      accountingEntries.add(new AccountingEntry(s));
    }

    Id textFileHandle = AccountingFileBuilder.create(
      accountingEntries,
      fileCurrency,
      counter.Accounting_Verification_Number__c
    );

    ContentVersion accountingFile = contentVersions.selectById(
      new Set<Id>{ textFileHandle }
    )[0];

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    SettlementItems.newInstance(settlementItemsToSend) // TODO: Think about if this should be moved to the sending functions.
      .markAsSentToRacer(accountingFile.Title, uow);

    counter.Accounting_Verification_Number__c += 1;
    uow.registerDirty(counter);
    uow.commitWork();
  }

  public static void sendAccountingFile(Id fileId) {
    RacerIntegrationService.sendFile(
      RacerIntegrationService.FILE_TYPE.ACCOUNTING,
      fileId
    );
  }
  public static void sendPaymentFile(Id fileId) {
    RacerIntegrationService.sendFile(
      RacerIntegrationService.FILE_TYPE.PAYMENT,
      fileId
    );
  }

  /**
   * Tries to process the given settlement as a EuroBonus points payment and
   * add the points to the user's account by calling out to CLM. Marks the
   * settlements as either done or failed depending on the results of the
   * operation.
   */
  @future(callout=true)
  public static void sendEuroBonusPoints(Id settlementId) {
    // TODO: Should this be in the domain class?
    Settlement__c settlement = settlementsSel.selectByIdWithClaimFields(
      new Set<Id>{ settlementId }
    )[0];
    if (
      settlement.Settlement_Status__c != Settlements.STATUS_WAITING_FOR_TRANSFER
    ) {
      throw new SettlementsException(
        'Settlement should be waiting for transfer.'
      );
    }
    // TODO: We should check that we have all necessary data.

    try {
      CLMIntegrationService.AddPointsResponse resp = IntegrationService.addPointsToCustomer(
        settlement.EuroBonus_Number__c,
        settlement.EuroBonus_Points__c.intValue(),
        settlement.Submitter__r.Email,
        settlement.Name,
        settlement.Claim__r.Name,
        'Claim', // TODO: Should we add something more detailed in here? Request.reasonForPoints
        settlement.Claim__r.Liability_PNR__c == null
          ? ''
          : settlement.Claim__r.Liability_PNR__c,
        '' // TODO: Add ticketNumber if we have it.
      );
      if (resp.isSuccess) {
        // Points added
        Settlements.newInstance(new List<Settlement__c>{ settlement })
          .markAsDone(resp.successResponse.clmTransactionId);
      } else {
        // Domain failure, e.g. invalid EB number.
        Settlements.newInstance(new List<Settlement__c>{ settlement })
          .markAsFailed(resp.failureResponse.message);
      }
    } catch (Exception e) {
      // Service failure, e.g. something 5xx.
      Settlements.newInstance(new List<Settlement__c>{ settlement })
        .markAsFailed(e.getMessage());

      C_Log.log(
        C_Log.Severity.Error,
        'SettlementService.sendEuroBonusPoints# Failed to send points for settlement: ' +
        settlement.Name,
        null,
        'Settlements',
        null
      );
    }
  }

  /**
   * Tries to process the given settlement as a voucher payment and create
   * and send a voucher for the customer. Marks the settlements as either
   * done or failed depending on the results of the operation.
   */
  @future(callout=true)
  public static void createAndSendVoucher(Id settlementId) {
    // TODO: Should this be in the domain class?
    Settlement__c settlement = settlementsSel.selectByIdWithClaimFields(
      new Set<Id>{ settlementId }
    )[0];
    if (
      settlement.Settlement_Status__c != Settlements.STATUS_WAITING_FOR_TRANSFER
    ) {
      throw new SettlementsException(
        'Settlement should be waiting for transfer.'
      );
    }
    // TODO: We should check that we have all necessary data.

    VoucherCreateRequest voucherToCreate = new VoucherCreateRequest(
      VoucherIntegrationService.VoucherType.COMP,
      Settlements.VOUCHER_TYPE_STRING_TO_VOUCHER_SUBTYPE.get(
        settlement.Voucher_Type__c
      ),
      settlement.Currency__c,
      settlement.Amount__c.intValue(),
      settlement.Payee_Name__c, //firstName, TODO: Separate out
      settlement.Payee_Name__c, //lastName, TODO: Separate out
      settlement.Voucher_Email__c,
      settlement.Claim__r.Case__r.CaseNumber,
      settlement.Address_line_1__c,
      settlement.Postal_Code__c,
      settlement.City__c,
      settlement.Country__c
    );

    try {
      VoucherCreateResponse resp = VouchersService.createVoucher(
        voucherToCreate
      );
      // Voucher created successfully.
      Settlements.newInstance(new List<Settlement__c>{ settlement })
        .markAsDone('');
    } catch (Exception e) {
      Settlements.newInstance(new List<Settlement__c>{ settlement })
        .markAsFailed(e.getMessage());

      C_Log.log(
        C_Log.Severity.Error,
        'SettlementService.createAndSendVoucher# Failed to create and send voucher for settlement: ' +
        settlement.Name,
        null,
        'Settlements',
        null
      );
    }
  }

  public static Boolean addItemsToSettlement(
    Id settlementId,
    List<Settlement_Item__c> itemsToAdd
  ) {
    Settlement__c settlement = settlementsSel.selectById(
      new Set<Id>{ settlementId }
    )[0];
    return Settlements.newInstance(new List<Settlement__c>{ settlement })
      .updateSettlementItems(itemsToAdd);
  }
}
