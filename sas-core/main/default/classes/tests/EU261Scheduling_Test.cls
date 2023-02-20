@IsTest
public with sharing class EU261Scheduling_Test {
  private static ClaimsSelector claimsSel = ClaimsSelector.newInstance();
  @IsTest
  static void itIsPossibleToUpdateExternalDataStatus() {
    TestDataFactories.CasesClaims casesWithClaims = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => 'ABC123',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        )
      }
    );
    casesWithClaims.claims[1].Customer_Claim_Type__c = 'Flight cancellation';
    update casesWithClaims.claims[1];

    Test.startTest();
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    System.enqueueJob(
      new Claims.UpdateExternalDataStatusAsync(
        claimsSel.selectUnhandledEU261ClaimsByDataStatus('Not Started'),
        Claim.ExternalDataStatus.InProgress
      )
    );
    Test.stopTest();
    Set<Id> claimIds = new Map<Id, LIA_Claim__c>(casesWithClaims.claims)
      .keySet();
    List<LIA_Claim__c> claimsAfterUpdate = claimsSel.selectById(claimIds);
    System.assertEquals(
      'In Progress',
      claimsAfterUpdate[0].External_Data_Status__c,
      'External Data Status should have been updated'
    );
    System.assertEquals(
      'Not Started',
      claimsAfterUpdate[1].External_Data_Status__c,
      'External Data Status should not have been updated'
    );
  }

  @IsTest
  static void fetchingBookingThatExistsInEDWShouldUpdateDataStatus() {
    TestDataFactories.CasesClaims casesWithClaims = TestDataFactories.createCasesWithClaims(
      1,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => APIMMock.EDW_SINGLE_PNR,
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        ),
        LIA_Claim__c.External_Data_Status__c => 'In Progress'
      }
    );
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Database.executeBatch(new FetchEDWBookingsForEU261ClaimsBatch(), 2);
    Test.stopTest();
    LIA_Claim__c cl = claimsSel.selectById(
      new Set<Id>{ casesWithClaims.claims[0].Id }
    )[0];
    System.assertEquals(
      1,
      cl.External_Data_Retrieve_Count__c,
      'Retrieve Count should be updated'
    );
    System.assertEquals(
      'Completed',
      cl.External_Data_Status__c,
      'External Data Status should have been updated'
    );
  }
  @IsTest
  static void fetchingBookingThatDoesNotExistsInEDWShouldFailGracefully() {
    TestDataFactories.CasesClaims casesWithClaims = TestDataFactories.createCasesWithClaims(
      2,
      null,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Liability_PNR__c => 'ABC123',
        LIA_Claim__c.Flight_Number__c => 'SK1',
        LIA_Claim__c.Flight_Date__c => Date.today(),
        LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
        LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation - compensation',
        LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
          Claim.RecordType.CustomerClaim
        ),
        LIA_Claim__c.External_Data_Status__c => 'In Progress'
      }
    );
    casesWithClaims.claims[1].External_Data_Retrieve_Count__c = 3;
    update casesWithClaims.claims[1];
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Database.executeBatch(new FetchEDWBookingsForEU261ClaimsBatch(), 2);
    Test.stopTest();
    Set<Id> claimIds = new Map<Id, LIA_Claim__c>(casesWithClaims.claims)
      .keySet();
    List<LIA_Claim__c> claimsAfterUpdate = claimsSel.selectById(claimIds);
    System.assertEquals(
      1,
      claimsAfterUpdate[0].External_Data_Retrieve_Count__c,
      'Retrieve Count should be updated'
    );
    System.assertEquals(
      'In Progress',
      claimsAfterUpdate[0].External_Data_Status__c,
      'External Data Status should still be In Progress'
    );
    System.assertEquals(
      4,
      claimsAfterUpdate[1].External_Data_Retrieve_Count__c,
      'Retrieve Count should be updated'
    );
    System.assertEquals(
      'Unavailable',
      claimsAfterUpdate[1].External_Data_Status__c,
      'External Data Status should set to Unavailable'
    );
    System.assertEquals(
      'Unable to handle',
      claimsAfterUpdate[1].EU261_Handling_Status__c,
      'EU261 Handling Status should set to Unable to handle'
    );
  }
}
