@IsTest
public with sharing class Settlements_IntegrationTest {
  @IsTest
  public static void accountingFilesShouldBeCreatedCorrectly() {
    // Given
    Racer_Integration_Counter__c counter = new Racer_Integration_Counter__c(
      Accounting_Verification_Number__c = 10000,
      Currency__c = 'SEK',
      Payment_Run_Id__c = 1000
    );
    Settlement__c settlement1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.MONETARY_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c settlement2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.MONETARY_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    insert new List<SObject>{ counter, settlement1, settlement2 };

    Settlement_Item__c settlementItemToInclude1 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement1.Id,
      Status__c = 'Waiting for transfer'
    );
    Settlement_Item__c settlementItemToInclude2 = new Settlement_Item__c(
      Amount__c = 60,
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement1.Id,
      Status__c = 'Waiting for transfer'
    );
    Settlement_Item__c settlementItemToInclude3 = new Settlement_Item__c(
      Amount__c = 70,
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer'
    );
    Settlement_Item__c settlementItemNotToInclude1 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Account__c = '6727',
      Currency__c = 'SEK',
      Settlement__c = settlement1.Id,
      Status__c = 'Pending L1 confirmation'
    );
    Settlement_Item__c settlementItemNotToInclude2 = new Settlement_Item__c(
      Amount__c = 50,
      Cost_Account__c = '6727',
      Currency__c = 'NOK',
      Settlement__c = settlement2.Id,
      Status__c = 'Waiting for transfer'
    );
    insert new List<SObject>{
      settlementItemToInclude1,
      settlementItemToInclude2,
      settlementItemToInclude3,
      settlementItemNotToInclude1,
      settlementItemNotToInclude2
    };

    // When
    Test.startTest();
    SettlementService.createAccountingFile(
      AccountingFileBuilder.PaymentCurrency.SEK
    );
    Test.stopTest();

    //Then
    Settlement_Item__c settlementItemToInclude1Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude1.Id
    ];
    Settlement_Item__c settlementItemToInclude2Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude2.Id
    ];
    Settlement_Item__c settlementItemToInclude3Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemToInclude3.Id
    ];
    Settlement_Item__c settlementItemNotToInclude1Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemNotToInclude1.Id
    ];
    Settlement_Item__c settlementItemNotToInclude2Afterwards = [
      SELECT Id, Status__c, Accounting_File_Name__c, Name
      FROM Settlement_Item__c
      WHERE Id = :settlementItemNotToInclude2.Id
    ];

    String expectedFileTitle =
      'a501' +
      String.valueOf(Date.today().dayOfYear()) +
      '0' +
      Datetime.now().format('yyyyMMdd') +
      '.sfsek';

    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude1Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude2Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );
    System.assertEquals(
      expectedFileTitle,
      settlementItemToInclude3Afterwards.Accounting_File_Name__c,
      'Accounting file name should be stored in settlement items.'
    );

    System.assertEquals(
      'Sent to Racer',
      settlementItemToInclude1Afterwards.Status__c,
      'Settlement item status should be updated to Sent to Racer.'
    );
    System.assertEquals(
      'Sent to Racer',
      settlementItemToInclude2Afterwards.Status__c,
      'Settlement item status should be updated to Sent to Racer.'
    );
    System.assertEquals(
      'Sent to Racer',
      settlementItemToInclude3Afterwards.Status__c,
      'Settlement item status should be updated to Sent to Racer.'
    );

    System.assertEquals(
      'Pending L1 confirmation',
      settlementItemNotToInclude1Afterwards.Status__c,
      'Settlement item not waiting for transfer should not be modified.'
    );
    System.assert(
      String.isEmpty(
        settlementItemNotToInclude1Afterwards.Accounting_File_Name__c
      ),
      'Settlement item not waiting for transfer should not be modified.'
    );
    System.assertEquals(
      'Waiting for transfer',
      settlementItemNotToInclude2Afterwards.Status__c,
      'Settlement item in different currency should not be modified.'
    );
    System.assert(
      String.isEmpty(
        settlementItemNotToInclude2Afterwards.Accounting_File_Name__c
      ),
      'Settlement item in different currency should not be modified.'
    );

    String comparisonText = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'RacerAccountingFileReference'
      ]
      .Body.toString()
      .replace('{-DATE-}', Datetime.now().format('yyyyMMdd'))
      .replace('{PR}', Datetime.now().format('yyMM'))
      .replace('{-S1NAME---}', settlementItemToInclude1Afterwards.Name)
      .replace('{-S2NAME---}', settlementItemToInclude2Afterwards.Name)
      .replace('{-S3NAME---}', settlementItemToInclude3Afterwards.Name);
    /**
     * When the testing option 'Independent Auto-Number Sequence' is enabled, the
     * generated autonumbers for Settlement Items are of format {YYMMDD}{000000}
     * instead of the expected {YYMMDD}{0000}. Thus the placeholder in the
     * template has to be 2 characters longer than expected. Hopefully this
     * doesn't blow up anything else.
     */

    Racer_Integration_Counter__c counterAfterwards = [
      SELECT Id, Accounting_Verification_Number__c, Payment_Run_Id__c
      FROM Racer_Integration_Counter__c
      WHERE Id = :counter.Id
    ];

    System.assertEquals(
      10001,
      counterAfterwards.Accounting_Verification_Number__c,
      'Accounting verification number should be incremented afterwards.'
    );
    System.assertEquals(
      1000,
      counterAfterwards.Payment_Run_Id__c,
      'Run Id should not be incremented after file creation.'
    );
  }

  @IsTest
  public static void paymentFilesShouldBeCreatedCorrectly() {
    // Given
    Racer_Integration_Counter__c counter = new Racer_Integration_Counter__c(
      Accounting_Verification_Number__c = 10000,
      Currency__c = 'SEK',
      Payment_Run_Id__c = 1000
    );
    Settlement__c sekToInclude1 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 400,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'SBANFIHH',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.MONETARY_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c sekToInclude2 = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 500,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.MONETARY_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );
    Settlement__c sekNotToInclude = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 500,
      Bank_Country__c = 'Sweden',
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'SEK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.MONETARY_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS
    );
    Settlement__c nokSettlement = new Settlement__c(
      Address_line_1__c = 'Frösundaviks allé 1',
      Address_line_2__c = 'Line 2',
      Amount__c = 600,
      Bank_Country__c = 'Norway',
      BIC_Swift__c = 'TESTBIC',
      City__c = 'Stockholm',
      Country__c = 'Sweden',
      Currency__c = 'NOK',
      Date_of_Exchange_Calculation__c = Date.today(),
      Bank_Account_Number__c = 'SE0000000000000',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00100',
      RecordTypeId = Settlements.MONETARY_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER
    );

    insert new List<SObject>{
      counter,
      sekToInclude1,
      sekToInclude2,
      sekNotToInclude,
      nokSettlement
    };

    // When
    Test.startTest();
    SettlementService.createPaymentFile(PaymentFileBuilder.PaymentCurrency.SEK);
    Test.stopTest();

    // Then
    Settlement__c sekToInclude1Afterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c, Name
      FROM Settlement__c
      WHERE Id = :sekToInclude1.Id
    ];
    Settlement__c sekToInclude2Afterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c, Name
      FROM Settlement__c
      WHERE Id = :sekToInclude2.Id
    ];
    Settlement__c sekNotToIncludeAfterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c
      FROM Settlement__c
      WHERE Id = :sekNotToInclude.Id
    ];
    Settlement__c nokSettlementAfterwards = [
      SELECT Id, Settlement_Status__c, Payment_File_Name__c
      FROM Settlement__c
      WHERE Id = :nokSettlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_WAITING_FOR_TRANSFER,
      nokSettlementAfterwards.Settlement_Status__c,
      'A settlement in different currency should not have been modified.'
    );
    System.assert(
      String.isEmpty(nokSettlementAfterwards.Payment_File_Name__c),
      'A settlement in different currency should not have been modified.'
    );
    System.assertEquals(
      Settlements.STATUS_IN_PROGRESS,
      sekNotToIncludeAfterwards.Settlement_Status__c,
      'A settlement in same currency but not waiting for transfer should not have been modified.'
    );
    System.assert(
      String.isEmpty(sekNotToIncludeAfterwards.Payment_File_Name__c),
      'A settlement in same currency but not waiting for transfer should not have been modified.'
    );

    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      sekToInclude1Afterwards.Settlement_Status__c,
      'Status of settlements in given currency should be set to Sent to Racer.'
    );
    System.assertEquals(
      Settlements.STATUS_SENT_TO_RACER,
      sekToInclude2Afterwards.Settlement_Status__c,
      'Status of settlements in given currency should be set to Sent to Racer.'
    );

    String expectedFileTitle =
      'SF_SEB_SEK_' +
      Datetime.now().format('yyyyMMdd') +
      counter.Payment_Run_Id__c;

    System.assertEquals(
      expectedFileTitle,
      sekToInclude1Afterwards.Payment_File_Name__c,
      'Payment file name should be stored in settlements.'
    );
    System.assertEquals(
      expectedFileTitle,
      sekToInclude2Afterwards.Payment_File_Name__c,
      'Payment file name should be stored in settlements.'
    );

    ContentVersion createdFile = [
      SELECT Id, Title, VersionData
      FROM ContentVersion
      WHERE Title = :expectedFileTitle
    ];

    String comparisonText = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'RacerPaymentFileReference'
      ]
      .Body.toString()
      .replace('{-DATE-}', Datetime.now().format('yyyyMMdd'))
      .replace('{-S1NAME---}', sekToInclude1Afterwards.Name)
      .replace('{-S2NAME---}', sekToInclude2Afterwards.Name);

    /**
     * When the testing option 'Independent Auto-Number Sequence' is enabled, the
     * generated autonumbers for Settlements are of format {YYMMDD}{000000}
     * instead of the expected {YYMMDD}{0000}. Thus the placeholder in the
     * template has to be 2 characters longer than expected. Hopefully this
     * doesn't blow up anything else.
     */

    System.assertEquals(
      comparisonText,
      createdFile.VersionData.toString(),
      //comparisonText,
      'Created payment file contents should match example file.'
    );

    Racer_Integration_Counter__c counterAfterwards = [
      SELECT Id, Accounting_Verification_Number__c, Payment_Run_Id__c
      FROM Racer_Integration_Counter__c
      WHERE Id = :counter.Id
    ];

    System.assertEquals(
      10000,
      counterAfterwards.Accounting_Verification_Number__c,
      'Accounting verification number should not be incremented afterwards.'
    );
    System.assertEquals(
      1001,
      counterAfterwards.Payment_Run_Id__c,
      'Run Id should be incremented after file creation.'
    );
  }

  @IsTest
  public static void ebSettlementsShouldBeProcessedImmediatelyWhenWaitingForTransfer() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    LIA_Claim__c claim = new LIA_Claim__c(Liability_PNR__c = '0000AA');
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Claim__c = claim.Id,
      EuroBonus_Number__c = '000000000',
      EuroBonus_Points__c = 3000,
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.EUROBONUS_POINTS_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS,
      Submitter__c = settlementSubmitter.Id
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Test.startTest();
    update settlement;
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_DONE,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as done after successfully adding points.'
    );
    System.assertEquals(
      APIMMock.CLM_TRANSACTION_ID,
      settlementAfterProcessing.External_Reference__c,
      'Settlement should external reference set based on response.'
    );
  }

  @IsTest
  public static void ebSettlementProcessingShouldHandleDomainFailuresProperly() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    LIA_Claim__c claim = new LIA_Claim__c(Liability_PNR__c = '0000AA');
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Claim__c = claim.Id,
      EuroBonus_Number__c = APIMMock.EB_NUMBER_NOT_IN_CLM,
      EuroBonus_Points__c = 3000,
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.EUROBONUS_POINTS_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS,
      Submitter__c = settlementSubmitter.Id
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Test.startTest();
    update settlement;
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as denied after failing to add points.'
    );
    System.assertEquals(
      'Customer does not exist.',
      settlementAfterProcessing.Error_Message__c,
      'Settlement should have error detail set to response error.'
    );
  }

  @IsTest
  public static void ebSettlementProcessingShouldHandleServiceFailuresProperly() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    LIA_Claim__c claim = new LIA_Claim__c(Liability_PNR__c = '0000AA');
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Claim__c = claim.Id,
      EuroBonus_Number__c = APIMMock.EB_NUMBER_RETURN_500,
      EuroBonus_Points__c = 3000,
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.EUROBONUS_POINTS_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS,
      Submitter__c = settlementSubmitter.Id
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Test.startTest();
    update settlement;
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as failed after failing to add points.'
    );
    System.assert(
      settlementAfterProcessing.Error_Message__c.contains('500'),
      'Settlement should have error detail set to contain 500 error code.'
    );
  }

  @IsTest
  public static void voucherSettlementsShouldBeProcessedImmediatelyWhenWaitingForTransfer() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    Case c = new Case();
    insert c;

    LIA_Claim__c claim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Case__c = c.Id
    );
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Amount__c = 1,
      Address_line_1__c = 'TestAddress',
      Claim__c = claim.Id,
      City__c = 'Test City',
      Country__c = 'Sweden',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.VOUCHER_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS,
      Submitter__c = settlementSubmitter.Id,
      Voucher_Email__c = 'test@example.com'
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Test.startTest();
    update settlement;
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_DONE,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as done after successfully creating a voucher.'
    );
  }

  @IsTest
  public static void voucherSettlementProcessingShouldHandleServiceFailuresProperly() {
    // Given
    User settlementSubmitter = FCS_TestDataFactory.createUsers(1)[0];
    insert settlementSubmitter;

    Case c = new Case();
    insert c;

    LIA_Claim__c claim = new LIA_Claim__c(
      Liability_PNR__c = '0000AA',
      Case__c = c.Id
    );
    insert claim;

    Settlement__c settlement = new Settlement__c(
      Amount__c = 1,
      Address_line_1__c = 'TestAddress',
      Claim__c = claim.Id,
      City__c = 'Test City',
      Country__c = 'Sweden',
      Payee_Name__c = 'Test Testsson',
      Postal_Code__c = '00000',
      RecordTypeId = Settlements.VOUCHER_RECORD_TYPE_ID,
      Settlement_Status__c = Settlements.STATUS_IN_PROGRESS,
      Submitter__c = settlementSubmitter.Id,
      Voucher_Email__c = APIMMock.VOUCHER_INVALID_EMAIL
    );

    insert settlement;

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    // When
    settlement.Settlement_Status__c = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Test.startTest();
    update settlement;
    Test.stopTest();

    // Then
    Settlement__c settlementAfterProcessing = [
      SELECT Id, Settlement_Status__c, Error_Message__c, External_Reference__c
      FROM Settlement__c
      WHERE Id = :settlement.Id
    ];

    System.assertEquals(
      Settlements.STATUS_FAILED,
      settlementAfterProcessing.Settlement_Status__c,
      'Settlement should be marked as failed after failing to create a voucher.'
    );
    System.assert(
      settlementAfterProcessing.Error_Message__c.contains('400'),
      'Settlement should have error detail set to contain 400 error code as returned from API.'
    );
  }
}
