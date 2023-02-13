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
    c.LastModifiedDate = System.now().addDays(-100);
    String caseString = JSON.serialize(c);
    Case deserializedCase = (Case) JSON.deserialize(caseString, Case.class);
    insert deserializedCase;
    Test.startTest();
    ChangeCasesReadOnlyBatchable b = new ChangeCasesReadOnlyBatchable();
    Database.executeBatch(b, 2000);
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
  @IsTest
  public static void caseShouldHaveChatterPost() {
    Case c = new Case(
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Department__c = 'Customer Claim',
      Team__c = 'Claims'
    );
    insert c;
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Test.startTest();
    CaseService.createChatterPost(new List<Case>{ c }, 'test', uow);
    uow.commitWork();
    Test.stopTest();
    List<FeedItem> fiAfterInsert = [
      SELECT Id, Body, ParentId
      FROM FeedItem
      WHERE ParentId = :c.Id
    ];
    System.assertEquals(
      1,
      fiAfterInsert.size(),
      'Chatter Post should have been created for this case'
    );
    System.assertEquals(
      'test',
      fiAfterInsert[0].Body,
      'Body should match the created chatter post'
    );
  }
}
