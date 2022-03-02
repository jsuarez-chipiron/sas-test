@IsTest
public with sharing class Claims_IntegrationTest {
  @IsTest
  public static void creatingAClaimWithPNRShouldCheckIfItExistsInCARE() {
    // Given
    LIA_Claim__c claim1 = new LIA_Claim__c(
      Liability_PNR__c = APIMMock.PNR_FOR_WHICH_CLAIMS_EXIST
    );
    LIA_Claim__c claim2 = new LIA_Claim__c(
      Liability_PNR__c = APIMMock.PNR_FOR_WHICH_CLAIMS_DO_NOT_EXIST
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    insert new List<LIA_Claim__c>{ claim1, claim2 };
    Test.stopTest();

    // Then
    LIA_Claim__c claim1AfterInsert = [
      SELECT
        Id,
        Claims_Exist_In_CARE_For_PNR__c,
        Last_Checked_Claims_From_CARE__c
      FROM LIA_Claim__c
      WHERE Id = :claim1.Id
    ];
    LIA_Claim__c claim2AfterInsert = [
      SELECT
        Id,
        Claims_Exist_In_CARE_For_PNR__c,
        Last_Checked_Claims_From_CARE__c
      FROM LIA_Claim__c
      WHERE Id = :claim2.Id
    ];

    System.assert(
      claim1AfterInsert.Claims_Exist_In_CARE_For_PNR__c,
      'Claim 1 should have found claims in CARE.'
    );
    System.assertNotEquals(
      null,
      claim1AfterInsert.Last_Checked_Claims_From_CARE__c,
      'Claim 1 should have checked for claims.'
    );
    System.assert(
      !claim2AfterInsert.Claims_Exist_In_CARE_For_PNR__c,
      'Claim 2 should not have found claims in CARE.'
    );
    System.assertNotEquals(
      null,
      claim2AfterInsert.Last_Checked_Claims_From_CARE__c,
      'Claim 2 should have checked for claims.'
    );
  }

  @IsTest
  public static void updatingAClaimWithPNRShouldCheckIfNewOneExistsInCARE() {
    // Given
    LIA_Claim__c claim1 = new LIA_Claim__c(
      Liability_PNR__c = APIMMock.PNR_FOR_WHICH_CLAIMS_EXIST
    );
    LIA_Claim__c claim2 = new LIA_Claim__c(
      Liability_PNR__c = APIMMock.PNR_FOR_WHICH_CLAIMS_DO_NOT_EXIST
    );
    insert new List<LIA_Claim__c>{ claim1, claim2 };

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    Test.startTest();
    claim1.Liability_PNR__c = null;
    claim2.Liability_PNR__c = APIMMock.PNR_FOR_WHICH_CLAIMS_EXIST;
    update new List<LIA_Claim__c>{ claim1, claim2 };
    Test.stopTest();

    // Then
    LIA_Claim__c claim1AfterUpdate = [
      SELECT
        Id,
        Claims_Exist_In_CARE_For_PNR__c,
        Last_Checked_Claims_From_CARE__c
      FROM LIA_Claim__c
      WHERE Id = :claim1.Id
    ];
    LIA_Claim__c claim2AfterUpdate = [
      SELECT
        Id,
        Claims_Exist_In_CARE_For_PNR__c,
        Last_Checked_Claims_From_CARE__c
      FROM LIA_Claim__c
      WHERE Id = :claim2.Id
    ];

    System.assert(
      !claim1AfterUpdate.Claims_Exist_In_CARE_For_PNR__c,
      'Claim 1 should have not found claims in CARE after PNR has been removed.'
    );
    System.assert(
      claim2AfterUpdate.Claims_Exist_In_CARE_For_PNR__c,
      'Claim 2 should have found claims in CARE after a PNR was added.'
    );
  }
}
