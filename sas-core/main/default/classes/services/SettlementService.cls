public without sharing class SettlementService {
  private static ContentVersionsSelector contentVersions = ContentVersionsSelector.newInstance();
  private static SettlementsSelector settlementsSel = SettlementsSelector.newInstance();
  private static SettlementItemsSelector settlementItemsSel = SettlementItemsSelector.newInstance();
  private static RacerIntegrationCountersSelector racerIntegrationCounters = RacerIntegrationCountersSelector.newInstance();

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
        'RACER',
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
        'RACER',
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

  private static void sendAccountingFile(Id fileId) {
    RacerIntegrationService.sendFile(
      RacerIntegrationService.FILE_TYPE.ACCOUNTING,
      fileId
    );
  }
  private static void sendPaymentFile(Id fileId) {
    RacerIntegrationService.sendFile(
      RacerIntegrationService.FILE_TYPE.PAYMENT,
      fileId
    );
  }
}
