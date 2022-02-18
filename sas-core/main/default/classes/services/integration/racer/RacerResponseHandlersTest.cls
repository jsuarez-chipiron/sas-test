@IsTest
public class RacerResponseHandlersTest {
  @IsTest
  public static void successfullL1ResponseShouldMarkSettlementsAsDelivered() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String L1FileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L1|46|ACCEPTED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L1|105|ACCEPTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'CARE_PAINL1_TEST.txt',
      Title = 'CARE_PAINL1_TEST',
      VersionData = Blob.valueOf(L1FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_DONE,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as accepted by Bank because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_DONE,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as accepted by Bank because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be marked as accepted by Bank as it has not been processed.'
    );
  }

  @IsTest
  public static void failedL1ResponseShouldMarkSettlementsAsFailed() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String L1FileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L1|46|REJECTED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L1|105|REJECTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_BANK,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'CARE_PAINL1_TEST.txt',
      Title = 'CARE_PAINL1_TEST',
      VersionData = Blob.valueOf(L1FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_REJECTED_BY_BANK,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as rejected by bank.'
    );
    System.assertEquals(
      Settlements.STATUS_REJECTED_BY_BANK,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as rejected by bank.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be modified as the file has not been processed.'
    );
  }

  @IsTest
  public static void itShouldBeAbleToHandleL2FilesWithSeveralErrors() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String error1 = 'ERR1';
    String error2 = 'ERR2';
    String L2FileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|SEB_L2|ID000/ID000|1114|SAS REF ID000|0000|SAS CRD SE|DK BANK TRANSFER|RJCT|NARR|ErrorOnAllCounterParties|5968|DKK|22-JAN-01|Name Name|RJCT|AC03|' +
      error1 +
      '\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|SEB_L2|ID000/ID000|1114|SAS REF ID000|0000|SAS CRD SE|DK BANK TRANSFER|RJCT|NARR|ErrorOnAllCounterParties|5968|DKK|22-JAN-01|Name Name|RJCT|AC03|' +
      error2;
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_DONE,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'CARE_PAINL2_TEST.txt',
      Title = 'CARE_PAINL2_TEST',
      VersionData = Blob.valueOf(L2FileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Error_Message__c, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as having errors.'
    );
    System.assertEquals(
      Settlements.STATUS_FAILED,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as having errors.'
    );
    System.assertEquals(
      Settlements.STATUS_DONE,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be modified'
    );
    System.assertEquals(
      error1,
      relevantSettlement1Afterwards.Error_Message__c,
      'Settlement 1 should have correct error message.'
    );
    System.assertEquals(
      error2,
      relevantSettlement2Afterwards.Error_Message__c,
      'Settlement 2 should have correct error message.'
    );
    System.assertEquals(
      null,
      irrelevantSettlementAfterwards.Error_Message__c,
      'Settlement 3 should have no error message.'
    );
  }

  @IsTest
  public static void paymulResponseShouldMarkSettlementsAsDelivered() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String PaymulFileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|PAYMUL|368|PROCESSED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|PAYMUL|368|PROCESSED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'CARE_PAYMUL_TEST.txt',
      Title = 'CARE_PAYMUL_TEST',
      VersionData = Blob.valueOf(PaymulFileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as accepted by Racer because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_BANK,
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as accepted by Racer because file has been processed successfully.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be marked as accepted by Racer as it has not been processed.'
    );
  }

  @IsTest
  public static void paymulResponseShouldHandleFailures() {
    // Given
    String paymentFileName1 = 'TestPaymentFile1.txt';
    String paymentFileName2 = 'TestPaymentFile2.txt';
    String PaymulFileContents =
      '01/01/2022 01:00:00|' +
      paymentFileName1 +
      '|PAYMUL|368|REJECTED||ID0000\n' +
      '01/01/2022 01:00:00|' +
      paymentFileName2 +
      '|PAYMUL|368|REJECTED||ID0000';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = Settlements.STATUS_SENT_TO_RACER,
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'CARE_PAYMUL_TEST.txt',
      Title = 'CARE_PAYMUL_TEST',
      VersionData = Blob.valueOf(PaymulFileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      'Rejected by Racer',
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as rejected by Racer.'
    );
    System.assertEquals(
      'Rejected by Racer',
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as rejected by Racer.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be modified as it has not been processed.'
    );
  }

  /*@IsTest
  public static void accounting() {
    // Given
    String accountingFileName1 = 'TestAccountingFile1.caresek';
    String accountingFileName2 = 'TestPaymentFile2.txt';
    String GLFileContents = '12/23/2021 05:23:21|TestAccountingFile1.caresek|RACERGL|63|PROCESSED|Successfull Completion.Data File moved to archive folder.|';
    Settlement__c relevantSettlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = 'Sent to Racer',
      Payment_File_Name__c = paymentFileName1
    );
    Settlement__c relevantSettlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = 'Sent to Racer',
      Payment_File_Name__c = paymentFileName2
    );
    Settlement__c irrelevantSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      IBAN__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      Settlement_Status__c = 'Sent to Racer',
      Payment_File_Name__c = 'DifferentFileName.txt'
    );

    insert new List<SObject>{
      relevantSettlement1,
      relevantSettlement2,
      irrelevantSettlement
    };

    // When
    ContentVersion cv = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = 'CARE_RACERGL_TEST.txt',
      Title = 'CARE_RACERGL_TEST',
      VersionData = Blob.valueOf(GLFileContents)
    );
    Test.startTest();
    insert cv;
    Test.stopTest();

    // Then
    Settlement__c relevantSettlement1Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement1.Id
    ];
    Settlement__c relevantSettlement2Afterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :relevantSettlement2.Id
    ];
    Settlement__c irrelevantSettlementAfterwards = [
      SELECT Id, Settlement_Status__c
      FROM Settlement__c
      WHERE Id = :irrelevantSettlement.Id
    ];

    System.assertEquals(
      'Rejected by Racer',
      relevantSettlement1Afterwards.Settlement_Status__c,
      'Settlement 1 should be marked as rejected by Racer.'
    );
    System.assertEquals(
      'Rejected by Racer',
      relevantSettlement2Afterwards.Settlement_Status__c,
      'Settlement 2 should be marked as rejected by Racer.'
    );
    System.assertEquals(
      'Sent to Racer',
      irrelevantSettlementAfterwards.Settlement_Status__c,
      'Settlement 3 should not be modified as it has not been processed.'
    );
  }*/
}
