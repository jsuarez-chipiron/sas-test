@isTest
private class GroupTravelRequestTest {
  static testMethod void testCreateGroupTravelForm() {
    String json =
      '{ ' +
      '  \"formData\": {' +
      '    \"groupName\": \"Sweden\",' +
      '    \"email\": \"example@example.com\",' +
      '    \"phone\": \"000000000000\",' +
      '   \"haveCompanyCode\":true,' +
      '    \"companyCode\": \"Ind\",' +
      '    \"firstName\": \"test\",' +
      '    \"lastName\": \"test1\",' +
      '   \"city\": \"Challakere\",' +
      '    \"tripType\": \"Round Trip\",' +
      '    \"groupType\": \"Youth\",' +
      '    \"fromAirport\": \"Bng\",' +
      '   \"toAirport\": \"Sth\",' +
      '    \"differentReturnCityAirport\": \"Hyd\",' +
      '    \"departureTime\": \"Morning\",' +
      '    \"departureDate\": \"2021-09-21T18:25:43-05:00\",' +
      '   \"returnTime\": \"Morning\",' +
      '    \"returnDate\": \"2012-09-23T18:25:43-05:00\",' +
      '   \"alternativeDates\":true,' +
      '    \"alternateDepartureTime\": \"Midmorning\",' +
      '   \"alternateDepartureDate\": \"2021-09-25T18:25:43-05:00\",' +
      '   \"alternateReturnTime\": \"Midmorning\",' +
      '   \"alternateReturnDate\": \"2021-09-26T18:25:43-05:00\",' +
      '   \"proposeAlternativeDestinations\": false,' +
      '   \"otherDestinationsOfInterest\": \"testtetetsstst\",' +
      '   \"numberOfAdults\": 2,' +
      '   \"numberOfChildren\": 1,' +
      '   \"numberOfInfants\": 0,' +
      '   \"travelClass\": \"SAS Plus\",' +
      '   \"extraBags\": true,' +
      '   \"numberOfExtraBags\": 2,' +
      '   \"specialBaggage\": false,' +
      '   \"numberOfSpecialBaggage\": 0,  ' +
      '   \"specialBaggageNote\": \" \",' +
      '   \"wheelchairs\": true,' +
      '   \"numberOfWheelchairs\": 1, ' +
      '   \"visualOrHearingAssistance\": true,' +
      '   \"formOfPayment\": \" SAS Invoice\",' +
      '   \"invoiceAgreementWithSAS\": true,' +
      '   \"comments\": \"teststestst\"' +
      '  },' +
      '  \"metaData\": {' +
      '    \"market\": \"se-sv\"' +
      '  }' +
      '}';

    Test.startTest();
    RestRequest request = new RestRequest();
    request.requestUri = '/services/apexrest/GroupTravelForm';
    request.httpMethod = 'POST';
    RestContext.request = request;
    GroupTravelJsonToApex obj = GroupTravelJsonToApex.parse(json);
    GroupTravelRequestForm.groupTravelForm(obj);
    Test.StopTest();
  }
}
