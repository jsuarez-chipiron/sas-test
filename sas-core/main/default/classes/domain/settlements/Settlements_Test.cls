@IsTest
private class Settlements_Test {
  @IsTest
  static void itShouldNotBePossibleToUpdateFailedSettlementToDone() {
    Settlement__c s = new Settlement__c(
      Settlement_Status__c = Settlements.STATUS_FAILED
    );
    insert s;
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance(); // needs to be passed in but tests works without committing.
    Settlements.newInstance(new List<Settlement__c>{ s })
      .markAsDone('done', uow);

    System.assertEquals(
      Settlements.STATUS_FAILED,
      s.Settlement_Status__c,
      'Settlement status should not have been updated.'
    );
  }
}
