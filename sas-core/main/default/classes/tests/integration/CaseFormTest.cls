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
    String response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin, Department__c
      FROM Case
      WHERE CaseNumber = :response
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
    String response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [SELECT Id, Origin FROM Case WHERE CaseNumber = :response];
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
    CaseFormJSON2Apex requestBody = CaseFormJSON2Apex.parse(
      '{ ' +
      '  "formData\": {' +
      '    "type": "claim",' +
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
      '    "market": "dk-da"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    String response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [
      SELECT Id, Origin, Department__c
      FROM Case
      WHERE CaseNumber = :response
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
      '    "country": "Sweden",' +
      '    "contactType": "private",' +
      '    "claimCategory": "category",' +
      '    "claimType": "type",' +
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
    String response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [SELECT Id, Origin FROM Case WHERE CaseNumber = :response];
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
    String response = CaseForm.createCase(requestBody);
    Test.StopTest();
    Case c = [SELECT Id, Origin FROM Case WHERE CaseNumber = :response];
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
}
