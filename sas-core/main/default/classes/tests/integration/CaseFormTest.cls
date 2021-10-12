@isTest
private class CaseFormTest {
  static testMethod void testCreateCaseForm() {
    //Create Document
    ContentVersion cv = new ContentVersion();
    cv.Title = 'Test Document';
    cv.PathOnClient = 'TestDocument.pdf';
    cv.VersionData = Blob.valueOf('Test Content');
    cv.IsMajorVersion = true;
    insert cv;

    String json =
      '{ ' +
      '  \"formData\": {' +
      '    \"bookingReference\": \"123456\",' +
      '    \"contentVersionIds\":["' +
      cv.Id +
      '"]' +
      '  },' +
      '  \"metaData\": {' +
      '    \"market\": \"se-sv\"' +
      '  }' +
      '}';

    Test.startTest();
    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );
    RestRequest request = new RestRequest();
    request.requestUri = '/services/apexrest/CaseForm';
    request.httpMethod = 'POST';
    RestContext.request = request;
    CaseFormJSON2Apex obj = CaseFormJSON2Apex.parse(json);
    string caseId = CaseForm.CaseForm(obj);
    Test.StopTest();
    System.assertEquals('500', caseId.substring(0, 3));
    Integer contentDocument = [
        SELECT Id, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :caseId
      ]
      .size();
    System.assertEquals(1, contentDocument);
  }
}
