@IsTest
private class CaseService_Test {
  @IsTest
  static void inactiveCasesShouldBeReadOnly() {
    Case c = new Case(
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Department__c = 'Customer Claim',
      Team__c = 'Claims',
      Status = Cases.STATUS_CLOSED
    );
    insert c;
    Test.startTest();
    CaseService.setInactiveCasesReadOnly();
    Test.stopTest();
    Case caseAfterUpdate = [
      SELECT Id, IsReadOnly__c
      FROM Case
      WHERE Id = :c.Id
    ][0];
    System.assert(
      caseAfterUpdate.IsReadOnly__c,
      'Case should have been marked read only'
    );
  }
}
