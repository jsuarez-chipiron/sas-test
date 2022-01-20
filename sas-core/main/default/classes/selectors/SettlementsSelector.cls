public inherited sharing class SettlementsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Settlement__c.Id,
      Settlement__c.Address_line_1__c,
      Settlement__c.Address_line_2__c,
      Settlement__c.Amount__c,
      Settlement__c.BIC_Swift__c,
      Settlement__c.City__c,
      Settlement__c.Country__c,
      Settlement__c.Currency__c,
      Settlement__c.IBAN__c,
      Settlement__c.Name,
      Settlement__c.Payee_Name__c,
      Settlement__c.Payee_reference__c,
      Settlement__c.Postal_Code__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Settlement__c.SObjectType;
  }

  public static SettlementsSelector newInstance() {
    return (SettlementsSelector) SAS_Service_Application.Selector.newInstance(
      Settlement__c.SObjectType
    );
  }

  public List<Settlement__c> selectById(Set<Id> ids) {
    return (List<Settlement__c>) selectSObjectsById(ids);
  }

  String statusToTake = 'Waiting for transfer';

  public List<Settlement__c> selectWaitingForTransferByCurrency(
    List<String> currencies
  ) {
    return (List<Settlement__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Settlement_Status__c =:statusToTake AND Currency__c in :currencies'
        )
        .toSOQL()
    );
  }

  public List<Settlement__c> selectByPaymentFileName(String paymentFileName) {
    return (List<Settlement__c>) Database.query(
      newQueryFactory()
        .setCondition('Payment_File_Name__c =:paymentFileName')
        .toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
