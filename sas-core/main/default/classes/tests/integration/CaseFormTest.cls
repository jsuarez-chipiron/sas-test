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

    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );

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
}
