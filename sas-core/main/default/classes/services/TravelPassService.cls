public without sharing class TravelPassService {
  static TravelPassProductsSelector travelPassProducts = (TravelPassProductsSelector) SAS_Service_Application.Selector.newInstance(
    Travel_Pass_Product__c.SObjectType
  );

  /**
   * Fetches travel pass account information from C-Shark, creates travel pass products
   * and associates them with the corresponding account in SF.
   */
  @future(callout=true)
  public static void fetchTravelPassAccount(
    String tpAccountNumber,
    Id accountId
  ) {
    TPAccount tpAccount = CSharkIntegrationService.getTPAccount(
      tpAccountNumber
    );

    if (
      tpAccount == null ||
      tpAccount.products == null ||
      tpAccount.products.size() == 0
    ) {
      return;
    }

    List<Travel_Pass_Product__c> oldProductsToDelete = travelPassProducts.selectByAccountId(
      new Set<Id>{ accountId }
    );
    List<Travel_Pass_Product__c> productsToInsert = new List<Travel_Pass_Product__c>();

    // Get existing products and remove them.

    for (TPAccount.Product product : tpAccount.products) {
      productsToInsert.add(
        new Travel_Pass_Product__c(
          Account__c = accountId,
          Category_Code__c = product.categoryCode,
          Category_Name__c = product.categoryName,
          External_Name__c = product.externalName,
          Internal_Name__c = product.internalName,
          Name = product.externalName,
          Type_Code__c = product.typeCode,
          Type_Name__c = product.typeName
        )
      );
    }

    if (oldProductsToDelete != null && oldProductsToDelete.size() > 0) {
      delete oldProductsToDelete;
    }

    insert productsToInsert;
  }
}
