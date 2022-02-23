public without sharing class SettlementsController {
  private static SettlementsSelector settlements = SettlementsSelector.newInstance();
  private static ExchangeRatesSelector exchangeRates = ExchangeRatesSelector.newInstance();

  @AuraEnabled
  public static void addSettlementsItemsToSettlement(
    Id settlementId,
    List<Settlement_Item__c> settlementItems
  ) {
    SettlementService.addItemsToSettlement(settlementId, settlementItems);
  }

  @AuraEnabled(cacheable=true)
  public static List<Settlement__c> getSettlement(String settlementId) {
    return settlements.selectByIdWithSettlementItems(
      new Set<Id>{ settlementId }
    );
  }

  @AuraEnabled(cacheable=true)
  public static List<Exchange_Rate__c> getExchangeRates(String fromCurrency) {
    if (fromCurrency == null) {
      return new List<Exchange_Rate__c>();
    } else {
      return exchangeRates.selectByCurrency(fromCurrency);
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Customer__c> getPassengers(String settlementId) {
    // TODO: Create proper selector for me.
    Settlement__c s = [
      SELECT Id, Claim__c
      FROM Settlement__c
      WHERE Id = :settlementId
    ][0];
    return [SELECT Id, Name FROM Customer__c WHERE Claim__c = :s.Claim__c];
  }
}
