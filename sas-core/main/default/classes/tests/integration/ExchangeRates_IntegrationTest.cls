@IsTest
public with sharing class ExchangeRates_IntegrationTest {
  @IsTest
  public static void insertingExchangeRateFileShouldUpdateRates() {
    // Given
    String exchangeRatesFileName = 'PRD_BSR_20220119';
    String exchangeRatesFileContents =
      'SEK,UAH,3.094031,2022-01-19\n' +
      'SEK,EUR,0.09709,2022-01-19\n' +
      'DKK,USD,0.153329,2022-01-19\n' +
      'DKK,UYU,6.783202,2022-01-19';

    Exchange_Rate__c existingDkkUsd = new Exchange_Rate__c(
      From_Currency__c = 'DKK',
      To_Currency__c = 'USD',
      Rate__c = 1.24,
      Date__c = Date.valueOf('2022-01-18'),
      Name = 'DKK-USD'
    );
    insert existingDkkUsd;

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = exchangeRatesFileName + '.csv',
      Title = exchangeRatesFileName,
      VersionData = Blob.valueOf(exchangeRatesFileContents)
    );

    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    List<Exchange_Rate__c> ratesAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
    ];

    Exchange_Rate__c sekEurAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
      WHERE Name = 'SEK-EUR'
    ][0];
    Exchange_Rate__c dkkUsdAfterInsert = [
      SELECT Id, From_Currency__c, To_Currency__c, Rate__c, Date__c
      FROM Exchange_Rate__c
      WHERE Name = 'DKK-USD'
    ][0];

    System.assertEquals(
      2,
      ratesAfterInsert.size(),
      'Only relevant rates should have been inserted.'
    );
    System.assertEquals(
      0.09709,
      sekEurAfterInsert.Rate__c,
      'New rate should have been inserted correctly.'
    );
    System.assertEquals(
      0.153329,
      dkkUsdAfterInsert.Rate__c,
      'Existing rate should have been updated.'
    );
  }
}
