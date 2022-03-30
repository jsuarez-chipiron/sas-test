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
  public static void shouldCreateFeedbackCasesWithAllFields() {
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "feedback",' +
      '    "comment": "comment field",' +
      '    "email": "test@example.com",' +
      '    "firstName": "Test",' +
      '    "lastName": "Testsson",' +
      '    "feedbackCategory": "category",' +
      '    "feedbackType": "type",' +
      '    "flightDate": "2022-03-02",' +
      '    "flightNumber": "SK1234",' +
      '    "bookingReference": "TEST12"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "en-us"' +
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
    // TODO: Check all fields correctly when it's possible.
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Feedback International',
      c.Origin,
      'Origin should be set correctly for unknown origins.'
    );
    System.assertEquals(
      'Customer Claim',
      c.Department__c,
      'Department should be set correctly for unknown origins.'
    );
  }

  @IsTest
  public static void shouldCreateFeedbackCasesWithMinimalFields() {
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "feedback",' +
      '    "comment": "",' +
      '    "email": "test@example.com",' +
      '    "feedbackCategory": "category",' +
      '    "feedbackType": "type"' +
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
    System.assertNotEquals(
      null,
      c,
      'Should have found a case with the case number returned from create case.'
    );
    System.assertEquals(
      'Form - Feedback DK',
      c.Origin,
      'Origin should be set correctly for Denmark.'
    );
  }

  @IsTest
  public static void shouldCreateClaimCasesWithAllFields() {
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
      boardingPassFile2
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
      SELECT Amount__c, Currency__c, Type__c
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
      '    "flightDate": "2022-03-02",' +
      '    "flightNumber": "SK1234",' +
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
}
