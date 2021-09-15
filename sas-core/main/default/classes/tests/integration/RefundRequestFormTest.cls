@isTest
private class RefundRequestFormTest {
  static testMethod void testCreateRefundForm() {
    String json =
      '{  ' +
      '  "formData": {' +
      '    "countryOfPurchase": "Sweden",' +
      '    "email": "example@example.com",' +
      '    "phone": "000000000000",' +
      '    "passengerNames": [' +
      '      "Example Examplesson", ' +
      '      "Example Examplesdottir"' +
      '    ],' +
      '    "cancelEntireBooking": "Yes",' +
      '    "cancelAllPassengers": "No",' +
      '    "cancelDirection": "Inbound",' +
      '    "bookedTripVia": "Website",' +
      '    "pnr":" ",' +
      '    "ticketNumber": "123-1234567890"' +
      '  },' +
      '  "metaData": {' +
      '    "siteUrl": "sas.se"' +
      '  }' +
      '}';
    Test.setMock(HttpCalloutMock.class, new TEDSBookingSingleSuccessMock());
    Test.startTest();
    RestRequest request = new RestRequest();
    request.requestUri = '/services/apexrest/RefundForm';
    request.httpMethod = 'POST';
    RestContext.request = request;
    RefundJsonToApex obj = RefundJsonToApex.parse(json);
    RefundRequestForm.refundForm(obj);
    Test.StopTest();
  }
}
