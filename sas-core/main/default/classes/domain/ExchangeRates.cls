public without sharing class ExchangeRates extends fflib_SObjectDomain {
  public ExchangeRates(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new ExchangeRates(records);
    }
  }

  public static ExchangeRates newInstance(List<Exchange_Rate__c> sObjectList) {
    return (ExchangeRates) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  private static ContentVersionsSelector contentVersionsSel = ContentVersionsSelector.newInstance();
  private static ExchangeRatesSelector exchangeRatesSel = ExchangeRatesSelector.newInstance();

  public static final String CURRENCY_FILE_NAME = 'PRD_BSR_';
  public static final List<String> ACTIVE_CURRENCIES = new List<String>{
    'AUD',
    'AED',
    'CAD',
    'CHF',
    'CZK',
    'DKK',
    'EUR',
    'GBP',
    'HKD',
    'JPY',
    'NOK',
    'NZD',
    'PLN',
    'SEK',
    'SGD',
    'THB',
    'USD'
  };

  public static void handleCurrencyFiles(List<Id> contentVersionIds) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<ContentVersion> cvs = contentVersionsSel.selectById(
      new Set<Id>(contentVersionIds),
      true
    );

    Map<String, Exchange_Rate__c> existingRatesByName = new Map<String, Exchange_Rate__c>();

    List<Exchange_Rate__c> allRates = exchangeRatesSel.selectAll();
    for (Exchange_Rate__c rate : allRates) {
      existingRatesByName.put(rate.Name, rate);
    }

    for (ContentVersion cv : cvs) {
      String fileContents = cv.VersionData.toString();
      List<String> lines = fileContents.split('\n');

      for (String line : lines) {
        // Line format: SEK,EUR,0.09709,2022-01-19
        List<String> dataFields = line.split(',');
        if (
          ACTIVE_CURRENCIES.contains(dataFields[0]) &&
          ACTIVE_CURRENCIES.contains(dataFields[1])
        ) {
          Exchange_Rate__c e = existingRatesByName.get(
            dataFields[0] +
            '-' +
            dataFields[1]
          );
          if (e == null) {
            Exchange_Rate__c newRate = new Exchange_Rate__c(
              From_Currency__c = dataFields[0],
              To_Currency__c = dataFields[1],
              Rate__c = Decimal.valueOf(dataFields[2]),
              Date__c = Date.valueOf(dataFields[3]),
              Name = dataFields[0] + '-' + dataFields[1]
            );
            uow.registerNew(newRate);
          } else {
            e.Rate__c = Decimal.valueOf(dataFields[2]);
            e.Date__c = Date.valueOf(dataFields[3]);
            uow.registerDirty(e);
          }
        }
      }
    }
    uow.commitWork();
  }
}
