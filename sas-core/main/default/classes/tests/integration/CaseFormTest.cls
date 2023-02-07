@isTest
private class CaseFormTest {
  @IsTest
  public static void shouldCreateCaseAndAttachments() {
    // Create attachments
    ContentVersion attachment1 = new ContentVersion();
    attachment1.Title = 'Test Document1';
    attachment1.PathOnClient = 'TestDocument1.txt';
    attachment1.VersionData = Blob.valueOf('Test Content1');
    attachment1.IsMajorVersion = true;
    ContentVersion attachment2 = new ContentVersion();
    attachment2.Title = 'Test Document2';
    attachment2.PathOnClient = 'TestDocument2.txt';
    attachment2.VersionData = Blob.valueOf('Test Content2');
    attachment2.IsMajorVersion = true;
    insert attachment1;
    insert attachment2;

    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "bookingReference": "95TEST",' +
      '    "type": "visa-rejection",' +
      '    "contentVersionIds":["' +
      attachment1.Id +
      '","' +
      attachment2.Id +
      '"]' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseForm.createCase(requestBody);
    Test.StopTest();

    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE Initially_Provided_PNR__c = '95TEST'
    ];

    Integer numberOfContentDocumentLinks = [
        SELECT Id, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :c.Id
      ]
      .size();

    System.assertEquals(
      'Form - Visa Rejection DK',
      c.Origin,
      'Case Origin should be set according to market and form type.'
    );

    System.assertEquals(
      2,
      numberOfContentDocumentLinks,
      'There should exist two linked attachments to the case.'
    );
  }

  @IsTest
  public static void shouldCreateClaimCasesWithAllFields() {
    // Add exchange rate for claim expense calculations
    Decimal rate = 10.3;
    Exchange_Rate__c newRate = new Exchange_Rate__c(
      From_Currency__c = 'USD',
      To_Currency__c = 'SEK',
      Rate__c = rate,
      Date__c = Date.valueOf('2022-08-02'),
      Name = 'USD-SEK'
    );

    // Create attachments
    ContentVersion powerOfAttorneyFile = new ContentVersion(
      Title = 'Power of attorney',
      PathOnClient = 'Power of attorney.txt',
      VersionData = Blob.valueOf('Test Content 1'),
      IsMajorVersion = true
    );
    ContentVersion receiptFile1 = new ContentVersion(
      Title = 'Receipt',
      PathOnClient = 'Receipt 1.txt',
      VersionData = Blob.valueOf('Test Content 2'),
      IsMajorVersion = true
    );
    ContentVersion receiptFile2 = new ContentVersion(
      Title = 'Receipt',
      PathOnClient = 'Receipt 2.txt',
      VersionData = Blob.valueOf('Test Content 3'),
      IsMajorVersion = true
    );
    ContentVersion boardingPassFile1 = new ContentVersion(
      Title = 'Boarding pass',
      PathOnClient = 'Boarding pass 1.txt',
      VersionData = Blob.valueOf('Test Content 4'),
      IsMajorVersion = true
    );
    ContentVersion boardingPassFile2 = new ContentVersion(
      Title = 'Boarding pass',
      PathOnClient = 'Boarding pass 2.txt',
      VersionData = Blob.valueOf('Test Content 5'),
      IsMajorVersion = true
    );
    insert new List<SObject>{
      powerOfAttorneyFile,
      receiptFile1,
      receiptFile2,
      boardingPassFile1,
      boardingPassFile2,
      newRate
    };
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData": {' +
      '    "type": "claim",' +
      '    "claimCategory": "flight-disruptions",' +
      '    "claimType": "flight-delay",' +
      //
      '    "contactType": "private",' +
      '    "email": "test@example.com",' +
      '    "phone": "000000000",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "address": "Frösundaviks allé 1",' +
      '    "postalCode":"16970",' +
      '    "city": "Solna",' +
      '    "country": "SE",' +
      '    "euroBonusNumber": "000000000",' +
      '    "companyCode": "ABC",' +
      '    "companyName": "Test Aktiebolag",' +
      '    "referenceNumber": "1234567890",' +
      //
      '    "bankAccountHolderName": "Test Testsson",' +
      '    "bankAccountNumber": "FI0000000000000000",' +
      '    "bankCountry": "FI",' +
      '    "bankName": "S-Pankki",' +
      '    "bankBic": "SBANFIHH",' +
      //
      '    "unaccompaniedMinor": true,' +
      '    "personWithReducedMobility": true,' +
      //
      '    "comment": "An angry comment.",' +
      '    "contentVersionIds": ["' +
      powerOfAttorneyFile.Id +
      '"],' +
      //
      '    "delayLength": "2-3",' +
      '    "preferredCurrency": "EUR",' +
      '    "preferredCompensationMethod": "eurobonus",' +
      '    "preferredReimbursementMethod": "monetary",' +
      //
      '    "departureDate": "2022-03-02",' +
      '    "flightNumber": "SK1234",' +
      '    "bookingReference": "TEST12",' +
      '    "passengerIrregularityReportNumber": "TEST13",' +
      //
      '    "expenses": [' +
      '      { "expenseType": "food", "expenseCurrency": "NOK", "amount": 250.55, "receiptFileId": ["' +
      receiptFile1.Id +
      '"] },' +
      '      { "expenseType": "transportation", "expenseCurrency": "USD", "amount": 399, "receiptFileId": ["' +
      receiptFile2.Id +
      '"] }' +
      '    ],' +
      '    "travelers": [' +
      '      { "firstName": "Test", "lastName": "Testsson"},' +
      '      { "firstName": "Test", "lastName": "Testsdottir"}' +
      '    ],' +
      '    "rebookedFlights": [' +
      '      { "departureDate": "2022-02-20", "flightNumber": "SK1", "boardingPassFileId": ["' +
      boardingPassFile1.Id +
      '"] },' +
      '      { "departureDate": "2022-02-22", "flightNumber": "SK1000", "boardingPassFileId": ["' +
      boardingPassFile2.Id +
      '"] }' +
      '    ]' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormResponse response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin, Department__c
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];

    LIA_Claim__c cl = [
      SELECT
        Id,
        Bank_Country__c,
        Country__c,
        Concerns_a_person_with_reduced_mobility__c,
        Concerns_an_unaccompanied_minor__c,
        Currency__c,
        Liability_PNR__c,
        Preferred_Compensation_Method__c,
        Preferred_Reimbursement_Method__c,
        Flight_Date__c,
        Flight_Number__c
      FROM LIA_Claim__c
      WHERE Case__c = :c.Id
    ];

    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertEquals(
      'Customer Claim',
      c.Department__c,
      'Department should be set correctly for Denmark.'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
    System.assertEquals(
      'Finland',
      cl.Bank_Country__c,
      'Should have set bank country correctly.'
    );
    System.assertEquals(
      'Sweden',
      cl.Country__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      true,
      cl.Concerns_a_person_with_reduced_mobility__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      true,
      cl.Concerns_an_unaccompanied_minor__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'EUR',
      cl.Currency__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'TEST12',
      cl.Liability_PNR__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'EuroBonus Points',
      cl.Preferred_Compensation_Method__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'Monetary',
      cl.Preferred_Reimbursement_Method__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      Date.parse('2022-03-02'),
      cl.Flight_Date__c,
      'Should have set contact country correctly.'
    );
    System.assertEquals(
      'SK1234',
      cl.Flight_Number__c,
      'Should have set contact country correctly.'
    );

    List<Claim_Expense__c> expenses = [
      SELECT Amount__c, Currency__c, Type__c, Claim_Expense_Amount_In_SEK__c
      FROM Claim_Expense__c
      WHERE Claim__c = :cl.Id
    ];

    System.assertEquals(
      2,
      expenses.size(),
      'There should be 2 expenses linked to the claim.'
    );

    for (Claim_Expense__c e : expenses) {
      if (e.Type__c == 'transportation') {
        System.assertEquals('USD', e.Currency__c);
        System.assertEquals(399, e.Amount__c);
        System.assertEquals(399 * rate, e.Claim_Expense_Amount_In_SEK__c);
      } else {
        System.assertEquals('NOK', e.Currency__c);
        System.assertEquals(250.55, e.Amount__c);
      }
    }

    List<Customer__c> travellers = [
      SELECT First_Name__c, Last_Name__c
      FROM Customer__c
      WHERE Claim__c = :cl.Id
    ];

    System.assertEquals(
      2,
      travellers.size(),
      'There should be 2 travellers linked to the claim.'
    );

    for (Customer__c cust : travellers) {
      System.assertEquals('Test', cust.First_Name__c);
    }

    List<Claim_Rebooked_Flight__c> rebookedFlights = [
      SELECT Departure_Date__c, Flight_Number__c
      FROM Claim_Rebooked_Flight__c
      WHERE Claim__c = :cl.Id
    ];

    for (Claim_Rebooked_Flight__c f : rebookedFlights) {
      if (f.Flight_Number__c == 'SK1') {
        System.assertEquals(f.Departure_Date__c, Date.parse('2022-02-20'));
      } else {
        System.assertEquals(f.Departure_Date__c, Date.parse('2022-02-22'));
      }
    }

    System.assertEquals(
      2,
      travellers.size(),
      'There should be 2 rebooked flights linked to the claim.'
    );

    List<ContentDocumentLink> linksToClaim = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :cl.Id
    ];
    System.assertEquals(
      5,
      linksToClaim.size(),
      'There should be 5 files linked to the claim.'
    );

    List<ContentDocumentLink> linksToExpense = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :expenses[0].Id
    ];
    System.assertEquals(
      1,
      linksToExpense.size(),
      'There should be 1 file linked to each expense.'
    );

    List<ContentDocumentLink> linksToRebookedFlight = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :rebookedFlights[0].Id
    ];
    System.assertEquals(
      1,
      linksToRebookedFlight.size(),
      'There should be 1 file linked to each rebooked flight.'
    );

    List<ContentVersion> expenseFileFromQuery = [
      SELECT Title
      FROM ContentVersion
      WHERE ContentDocumentId = :linksToExpense[0].ContentDocumentId
    ];
    System.assertEquals(
      'Receipt',
      expenseFileFromQuery[0].Title,
      'Title for linked file to expense should match receipt file.'
    );

    List<ContentVersion> boardingPassFileFromQuery = [
      SELECT Title
      FROM ContentVersion
      WHERE ContentDocumentId = :linksToRebookedFlight[0].ContentDocumentId
    ];
    System.assertEquals(
      'Boarding pass',
      boardingPassFileFromQuery[0].Title,
      'Title for linked file to rebooked flight should match boarding pass file.'
    );
  }

  @IsTest
  public static void shouldCreateClaimCasesWithMinimalFields() {
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "claim",' +
      '    "email": "test@example.com",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "phone": "000000000",' +
      '    "address": "Frösundavik\'s allé 1",' +
      '    "postalCode": "000000",' +
      '    "city": "Stockholm",' +
      '    "country": "SE",' +
      '    "contactType": "private",' +
      '    "claimCategory": "accident-and-injury",' +
      '    "claimType": "other",' +
      '    "preferredCompensationMethod": "voucher",' +
      '    "bookingReference": "TEST12",' +
      '    "departureDate": "2022-03-02",' +
      '    "flightNumber": "SK1234"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormResponse response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];
    // TODO: Check all fields correctly when it's possible.
    LIA_Claim__c cl = [SELECT Id FROM LIA_Claim__c WHERE Case__c = :c.Id];
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
  }

  @IsTest
  public static void shouldCreateEBClaimCases() {
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "claim",' +
      '    "email": "test@example.com",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "phone": "000000000",' +
      '    "contactType": "type",' +
      '    "departureDate": "2022-03-02",' +
      '    "flightNumber": "SK1234",' +
      '    "claimCategory": "flight-disruptions",' +
      '    "bookingReference": "TEST12"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormResponse response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];

    LIA_Claim__c cl = [SELECT Id FROM LIA_Claim__c WHERE Case__c = :c.Id];
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
  }

  @IsTest
  public static void shouldCreateBaggageClaimCases() {
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "claim",' +
      '    "email": "test@example.com",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "phone": "000000000",' +
      '    "address": "Frösundavik\'s allé 1",' +
      '    "postalCode": "000000",' +
      '    "city": "Stockholm",' +
      '    "country": "SE",' +
      '    "contactType": "private",' +
      '    "claimCategory": "baggage",' +
      '    "claimType": "baggage-delayed",' +
      '    "passengerIrregularityReportNumber": "ARNSK12345",' +
      '    "baggageDelayTime": "less-than-21-days",' +
      '    "baggagePurchasePrice": 500,' +
      '    "baggagePurchaseYear": 2021,' +
      '    "preferredCompensationMethod": "voucher",' +
      '    "bookingReference": "TEST12"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormResponse response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];
    LIA_Claim__c cl = [
      SELECT
        Id,
        Customer_Claim_Type__c,
        Delay_Length__c,
        Purchase_Price__c,
        Purchase_Year__c
      FROM LIA_Claim__c
      WHERE Case__c = :c.Id
    ];
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Claims DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
    System.assertNotEquals(
      null,
      cl,
      'Should have found a claim linked to the case.'
    );
    System.assertEquals(
      'Baggage delayed/lost',
      cl.Customer_Claim_Type__c,
      'Should have set claim type correctly.'
    );
    System.assertEquals(
      'Less than 21 days',
      cl.Delay_Length__c,
      'Should have set delay length correctly.'
    );
    System.assertEquals(
      500,
      cl.Purchase_Price__c,
      'Should have set purchase price correctly.'
    );
    System.assertEquals(
      2021,
      cl.Purchase_Year__c,
      'Should have set purchase year correctly.'
    );
  }

  @IsTest
  public static void shouldCreateCompensationCardClaims() {
    // Given
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        ClaimService.COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        ClaimService.COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME
      }
    );

    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "compensation-card",' +
      '    "email": "test@example.com",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "phone": "000000000",' +
      '    "address": "Frösundavik\'s allé 1",' +
      '    "postalCode": "000000",' +
      '    "city": "Stockholm",' +
      '    "country": "SE",' +
      '    "contactType": "private",' +
      '    "compensationCardId": "SK12345678",' +
      '    "preferredCompensationMethod": "voucher",' +
      '    "bookingReference": "TEST12"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormResponse response = CaseForm.createCase(requestBody);
    Test.StopTest();

    Case c = [
      SELECT Id, Status
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ];
    LIA_Claim__c cl = [
      SELECT
        Id,
        RecordTypeId,
        Customer_Claim_Type__c,
        Delay_Length__c,
        Purchase_Price__c,
        Purchase_Year__c
      FROM LIA_Claim__c
      WHERE Case__c = :c.Id
    ];

    System.assertEquals(
      Claim.getRecordTypeIdByEnum(Claim.RecordType.CompensationCard),
      cl.RecordTypeId,
      'Record type should be set to compensation card.'
    );

    System.assertEquals(
      Cases.STATUS_CLOSED,
      c.Status,
      'Case should have been set to closed.'
    );
  }

  @IsTest
  public static void shouldCreateAndPrioritiseCasesCorrectly() {
    //Given
    // Create EB accounts
    List<Account> newAccounts = FCS_TestDataFactory.createFrequentFlyers(5);
    List<Account> newAccountsWithCorrectEBLevel = new List<Account>{};
    List<String> EBLevels = new List<String>{ 'B', 'D', 'P', 'B', 'B' };
    List<CaseFormJSON2Apex> requestBodies = new List<CaseFormJSON2Apex>{};

    for (Integer i = 0; i < newAccounts.size(); i++) {
      Account a = newAccounts[i];
      String EBLevel = EBLevels[i];
      String email = i + 'test@test.com';
      String firstName = i + 'testFirst';
      String lastName = i + 'testLast';
      String phone = i + '0000000';
      String EBNumber = a.FCS_EBNumber__c;
      a.PersonEmail = email;
      a.FirstName = firstName;
      a.LastName = lastName;
      a.Phone = phone;
      a.FCS_EBLevel__c = EBLevel;
      newAccountsWithCorrectEBLevel.add(a);
      String isMinor = 'false';
      String hasReducedMobility = 'false';

      if (i == 3) {
        isMinor = 'true';
      }
      if (i == 4) {
        hasReducedMobility = 'true';
      }

      requestBodies.add(
        CaseFormJSON2Apex.parse(
          '{ ' +
          '  "formData\": {' +
          '    "type": "claim",' +
          '    "email": "' +
          email +
          '",' +
          '    "firstName": "' +
          firstName +
          '",' +
          '    "lastName": "' +
          lastName +
          '",' +
          '    "phone": "' +
          phone +
          '",' +
          '    "address": "Testway",' +
          '    "postalCode": "00000",' +
          '    "city": "Stockholm",' +
          '    "country": "SE",' +
          '    "euroBonusNumber": "' +
          EBNumber +
          '",' +
          '    "contactType": "private",' +
          '    "claimCategory": "accident-and-injury",' +
          '    "claimType": "other",' +
          '    "preferredCompensationMethod": "voucher",' +
          '    "unaccompaniedMinor": ' +
          isMinor +
          ',' +
          '    "personWithReducedMobility": ' +
          hasReducedMobility +
          ',' +
          '    "bookingReference": "' +
          EBLevel +
          '12",' +
          '    "departureDate": "2022-03-02",' +
          '    "flightNumber": "S' +
          i +
          '123' +
          i +
          '"' +
          '  },' +
          '  "metaData": {' +
          '    "market": "dk-da"' +
          '  }' +
          '}'
        )
      );
    }

    insert newAccountsWithCorrectEBLevel;

    Map<Id, String> accountToPriority = new Map<Id, String>{
      newAccountsWithCorrectEBLevel[0].Id => 'Medium',
      newAccountsWithCorrectEBLevel[1].Id => 'Medium', //EBG/EBD priority for now
      newAccountsWithCorrectEBLevel[2].Id => 'Medium',
      newAccountsWithCorrectEBLevel[3].Id => 'Medium',
      newAccountsWithCorrectEBLevel[4].Id => 'High' //Priority for Disabled
    };

    // When
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    Set<String> responseCaseNumbers = new Set<String>{};
    for (CaseFormJSON2Apex formData : requestBodies) {
      responseCaseNumbers.add(CaseForm.createCase(formData).caseNumber);
    }
    Test.StopTest();

    // Then
    List<Case> cases = [
      SELECT Id, FCS_EBNumber__c, FCS_EBLevel__c, Priority, AccountId
      FROM Case
      WHERE CaseNumber IN :responseCaseNumbers
    ];

    Set<Id> caseIds = new Set<Id>{};
    for (Case newCase : cases) {
      caseIds.add(newCase.Id);
    }

    for (Account a : newAccounts) {
      Case newCase;
      for (Case c : cases) {
        if (c.AccountId == a.Id) {
          newCase = c;
        }
      }

      System.assertEquals(
        accountToPriority.get(a.Id),
        newCase.Priority,
        'Should assign the correct priority to cases.'
      );
    }
  }

  @IsTest
  public static void shouldCreateAndRouteCasesCorrectly() {
    //Given
    // Create EB accounts
    List<Account> newAccounts = FCS_TestDataFactory.createFrequentFlyers(4);
    List<Account> newAccountsWithCorrectEBLevel = new List<Account>{};
    List<String> EBLevels = new List<String>{ 'B', 'G', 'D', 'P' };
    List<String> claimCategories = new List<String>{
      'flight-disruptions',
      'baggage',
      'accident-and-injury',
      'flight-disruptions'
    };

    List<String> claimTypes = new List<String>{
      'flight-delay',
      'baggage-delayed',
      'other',
      'flight-delay'
    };
    List<CaseFormJSON2Apex> requestBodies = new List<CaseFormJSON2Apex>{};
    String baggageJson =
      '    "passengerIrregularityReportNumber": "ARNSK12345",' +
      '    "baggageDelayTime": "less-than-21-days",' +
      '    "baggagePurchasePrice": 500,' +
      '    "baggagePurchaseYear": 2021,';

    for (Integer i = 0; i < newAccounts.size(); i++) {
      Account a = newAccounts[i];
      String EBLevel = EBLevels[i];
      String email = i + 'test@test.com';
      String firstName = i + 'testFirst';
      String lastName = i + 'testLast';
      String phone = i + '0000000';
      String EBNumber = a.FCS_EBNumber__c;
      a.PersonEmail = email;
      a.FirstName = firstName;
      a.LastName = lastName;
      a.Phone = phone;
      a.FCS_EBLevel__c = EBLevel;
      newAccountsWithCorrectEBLevel.add(a);
      String jsonContent =
        '{ ' +
        '  "formData\": {' +
        '    "type": "claim",' +
        '    "email": "' +
        email +
        '",' +
        '    "firstName": "' +
        firstName +
        '",' +
        '    "lastName": "' +
        lastName +
        '",' +
        '    "phone": "' +
        phone +
        '",' +
        '    "address": "Testway",' +
        '    "postalCode": "00000",' +
        '    "city": "Stockholm",' +
        '    "country": "SE",' +
        '    "euroBonusNumber": "' +
        EBNumber +
        '",' +
        '    "contactType": "private",' +
        '    "claimCategory": "' +
        claimCategories[i] +
        '",' +
        '    "claimType": "' +
        claimTypes[i] +
        '",' +
        (claimCategories[i] == 'baggage' ? baggageJson : '') +
        '    "preferredCompensationMethod": "voucher",' +
        '    "bookingReference": "' +
        EBLevel +
        '12",' +
        '    "departureDate": "2022-03-02",' +
        '    "flightNumber": "S' +
        i +
        '123' +
        i +
        '"' +
        '  },' +
        '  "metaData": {' +
        '    "market": "dk-da"' +
        '  }' +
        '}';

      requestBodies.add(CaseFormJSON2Apex.parse(jsonContent));
    }

    insert newAccountsWithCorrectEBLevel;

    // When
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    Set<String> responseCaseNumbers = new Set<String>{};
    for (CaseFormJSON2Apex formData : requestBodies) {
      responseCaseNumbers.add(CaseForm.createCase(formData).caseNumber);
    }
    Test.StopTest();

    List<String> groupNames = new List<String>{
      'Claims - Flight Disruptions',
      'Claims - Baggage',
      'Claims - Other',
      'Claims - High Priority'
    };
    List<Group> groups = [SELECT Id, Name FROM Group WHERE Name IN :groupNames];

    Group disruptionGroup;
    Group baggageGroup;
    Group otherGroup;
    Group highPriorityGroup;

    for (Group g : groups) {
      switch on groupNames.indexOf(g.Name) {
        when 0 {
          disruptionGroup = g;
        }
        when 1 {
          baggageGroup = g;
        }
        when 2 {
          otherGroup = g;
        }
        when 3 {
          highPriorityGroup = g;
        }
        when else {
          System.debug(
            'Error. Group should have a name from the groupNames list.'
          );
        }
      }
    }

    Map<Id, String> accountToGroupName = new Map<Id, String>{
      newAccounts[0].Id => disruptionGroup.Name,
      newAccounts[1].Id => baggageGroup.Name,
      newAccounts[2].Id => otherGroup.Name,
      newAccounts[3].Id => highPriorityGroup.Name
    };

    // Then
    List<Case> cases = [
      SELECT Id, OwnerId, AccountId
      FROM Case
      WHERE CaseNumber IN :responseCaseNumbers
    ];

    Set<Id> caseIds = new Set<Id>{};
    Set<Id> caseOwnerIds = new Set<Id>{};
    for (Case newCase : cases) {
      caseIds.add(newCase.Id);
      caseOwnerIds.add(newCase.OwnerId);
    }

    List<Group> queueGroups = [
      SELECT Name, Id
      FROM Group
      WHERE Id IN :caseOwnerIds
    ];

    System.assertEquals(
      4,
      newAccounts.size(),
      'Accounts were not correctly created'
    );
    for (Account a : newAccounts) {
      LIA_Claim__c claim;
      Case newCase;
      for (Case c : cases) {
        if (c.AccountId == a.Id) {
          newCase = c;
        }
      }

      Boolean hasGroup = false;
      for (Group g : queueGroups) {
        if (g.Id == newCase.OwnerId) {
          System.assertEquals(
            accountToGroupName.get(a.Id),
            g.Name,
            'Should assign the cases to the correct queues.'
          );
          hasGroup = true;
        }
      }
      System.assert(hasGroup, 'Every case should have a group.');
    }
  }

  @isTest
  static void shouldRouteClaimsWithFlightDisruptionsExpensesToSpecialQueue() {
    ContentVersion receiptFile = new ContentVersion(
      Title = 'Receipt',
      PathOnClient = 'Receipt 1.txt',
      VersionData = Blob.valueOf('Test Content 2'),
      IsMajorVersion = true
    );

    insert new List<SObject>{ receiptFile };

    List<Account> newAccounts = FCS_TestDataFactory.createFrequentFlyers(1);
    List<Account> newAccountsWithCorrectEBLevel = new List<Account>{};
    List<String> EBLevels = new List<String>{ 'B' };
    List<CaseFormJSON2Apex> requestBodies = new List<CaseFormJSON2Apex>{};

    for (Integer i = 0; i < newAccounts.size(); i++) {
      Account a = newAccounts[i];
      String EBLevel = EBLevels[i];
      String EBNumber = a.FCS_EBNumber__c;
      a.FCS_EBLevel__c = EBLevel;
      newAccountsWithCorrectEBLevel.add(a);
      requestBodies.add(
        CaseFormJSON2Apex.parse(
          '{ ' +
          '  "formData": {' +
          '    "type": "claim",' +
          '    "claimCategory": "flight-disruptions",' +
          '    "claimType": "flight-delay",' +
          //
          '    "contactType": "private",' +
          '    "email": "test@example.com",' +
          '    "phone": "000000000",' +
          '    "firstName": "Test",' +
          '    "lastName": "Testsson",' +
          '    "address": "Frösundaviks allé 1",' +
          '    "postalCode":"16970",' +
          '    "city": "Solna",' +
          '    "country": "SE",' +
          '    "euroBonusNumber": "' +
          EBNumber +
          '",' +
          '    "companyCode": "ABC",' +
          '    "companyName": "Test Aktiebolag",' +
          '    "referenceNumber": "1234567890",' +
          //
          '    "bankAccountHolderName": "Test Testsson",' +
          '    "bankAccountNumber": "FI0000000000000000",' +
          '    "bankCountry": "FI",' +
          '    "bankName": "S-Pankki",' +
          '    "bankBic": "SBANFIHH",' +
          //
          '    "unaccompaniedMinor": true,' +
          '    "personWithReducedMobility": true,' +
          //
          '    "comment": "An angry comment.",' +
          //
          '    "delayLength": "2-3",' +
          '    "preferredCurrency": "EUR",' +
          '    "preferredCompensationMethod": "eurobonus",' +
          '    "preferredReimbursementMethod": "monetary",' +
          //
          '    "departureDate": "2022-03-02",' +
          '    "flightNumber": "SK1234",' +
          '    "bookingReference": "TEST12",' +
          '    "passengerIrregularityReportNumber": "TEST13",' +
          //
          '    "expenses": [' +
          '      { "expenseType": "food", "expenseCurrency": "SEK", "amount": 30000, "receiptFileId": ["' +
          receiptFile.Id +
          '"] }],' +
          '    "travelers": [' +
          '      { "firstName": "Test", "lastName": "Testsson"},' +
          '      { "firstName": "Test", "lastName": "Testsdottir"}' +
          '    ]' +
          '  },' +
          '  "metaData": {' +
          '    "market": "dk-da"' +
          '  }' +
          '}'
        )
      );
    }

    insert newAccountsWithCorrectEBLevel;

    // When
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    Set<String> responseCaseNumbers = new Set<String>{};
    for (
      CaseFormJSON2Apex formData : new List<CaseFormJSON2Apex>{
        requestBodies[0]
      }
    ) {
      responseCaseNumbers.add(CaseForm.createCase(formData).caseNumber);
    }
    Test.StopTest();

    Group correctGroup = [
      SELECT Id, Name
      FROM Group
      WHERE Name = 'Claims - Flight Disruptions Expenses'
    ][0];

    // Then
    List<Case> cases = [
      SELECT Id, OwnerId, AccountId
      FROM Case
      WHERE CaseNumber IN :responseCaseNumbers
    ];

    Group assignedQueueGroup = [
      SELECT Name, Id
      FROM Group
      WHERE Id = :cases[0].OwnerId
    ][0];

    System.assertEquals(
      1,
      newAccounts.size(),
      'Accounts were not correctly created'
    );
    for (Account a : newAccounts) {
      LIA_Claim__c claim;
      Case newCase;
      for (Case c : cases) {
        if (c.AccountId == a.Id) {
          newCase = c;
        }
      }

      System.assertEquals(
        correctGroup.Name,
        assignedQueueGroup.Name,
        'Should assign a case with high claim costs to a special queue (' +
        correctGroup.Name +
        ').'
      );
    }
  }

  @isTest
  public static void shouldRouteClaimsWithCompensationCardToSpecialQueue() {
    // Given
    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        ClaimService.COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        ClaimService.COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME
      }
    );

    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "compensation-card",' +
      '    "email": "test@example.com",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "phone": "000000000",' +
      '    "address": "Frösundavik\'s allé 1",' +
      '    "postalCode": "000000",' +
      '    "city": "Stockholm",' +
      '    "country": "SE",' +
      '    "contactType": "private",' +
      '    "compensationCardId": "SK12345678",' +
      '    "preferredCompensationMethod": "voucher",' +
      '    "bookingReference": "TEST12"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    CaseFormResponse response = CaseForm.createCase(requestBody);
    Case caseToRoute = [
      SELECT Id
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ][0];
    CaseService.assignPriorityAndRouteToQueue(new Set<Id>{ caseToRoute.Id });
    Test.StopTest();

    Case cases = [
      SELECT Id, Status, OwnerId
      FROM Case
      WHERE CaseNumber = :response.caseNumber
    ][0];

    Group correctGroup = [
      SELECT Id, Name
      FROM Group
      WHERE Name = 'Claims - Compensation Card'
    ][0];

    Group assignedQueueGroup = [
      SELECT Name, Id
      FROM Group
      WHERE Id = :cases.OwnerId
    ][0];

    System.assertEquals(
      correctGroup.Name,
      assignedQueueGroup.Name,
      'Should assign a case with high claim costs to a special queue (' +
      correctGroup.Name +
      ').'
    );
  }
}
