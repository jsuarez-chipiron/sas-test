@IsTest
private class GroupTravelRequestTest {
  @IsTest
  public static void shouldCreateGroupTravelRequests() {
    GroupTravelJsonToApex requestBody = GroupTravelJsonToApex.parse(
      '{ ' +
      '  "formData": {' +
      '    "groupName": "Group Travel Group",' +
      '    "email": "example@example.com",' +
      '    "phone": "110000000000",' +
      '    "haveCompanyCode":true,' +
      '    "companyCode": "123456A",' +
      '    "firstName": "test",' +
      '    "lastName": "test1",' +
      '    "city": "Test",' +
      '    "tripType": "round-trip",' +
      '    "groupType": "youth",' +
      '    "fromAirport": "BNG",' +
      '    "toAirport": "ARN",' +
      '    "differentReturnCityAirport": "HYH",' +
      '    "departureTime": "evening",' +
      '    "departureDate": "2021-09-21",' +
      '    "returnTime": "morning",' +
      '    "returnDate": "2012-09-23",' +
      '    "alternativeDates":true,' +
      '    "alternateDepartureTime": "midmorning",' +
      '    "alternateReturnTime": "any-time",' +
      '    "alternateReturnDate": "2021-09-26",' +
      '    "proposeAlternativeDestinations": false,' +
      '    "otherDestinationsOfInterest": "testtetetsstst",' +
      '    "numberOfAdults": 2,' +
      '    "numberOfChildren": 1,' +
      '    "numberOfInfants": 0,' +
      '    "travelClass": "sas-plus",' +
      '    "wheelchairs": true,' +
      '    "numberOfWheelchairs": 1, ' +
      '    "visualOrHearingAssistance": true,' +
      '    "formOfPayment": "sas-invoice",' +
      '    "invoiceAgreementWithSAS": true,' +
      '    "comments": "teststestst"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "fr-fr"' +
      '  }' +
      '}'
    );

    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    GroupTravelRequestForm.createGroupTravelRequest(requestBody);
    Test.StopTest();

    Group_Travel_Request__c req = [
      SELECT Id, Departure_Date__c, Invoice_Agreement_With_SAS__c
      FROM Group_Travel_Request__c
      WHERE Phone__c = '110000000000'
    ];
    Case c = [
      SELECT Id, Department__c, Origin
      FROM Case
      WHERE Group_Travel_Request__c = :req.Id
    ];

    System.assertEquals(
      true,
      req.Invoice_Agreement_With_SAS__c,
      'Form data should be parsed correctly into picklists.'
    );

    System.assertEquals(
      Date.valueOf('2021-09-21'),
      req.Departure_Date__c,
      'Form data should be parsed correctly into dates.'
    );

    System.assertEquals(
      'Form - Group Travel FR',
      c.Origin,
      'Case Origin should be set according to market and form type.'
    );

    System.assertEquals(
      'Group Sales',
      c.Department__c,
      'Case Department should be set by Case Origin to refunds.'
    );
  }
}
