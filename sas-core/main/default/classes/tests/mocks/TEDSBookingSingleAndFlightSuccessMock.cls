@isTest
global class TEDSBookingSingleAndFlightSuccessMock implements HttpCalloutMock {
  String bookingResponseBody = '{"id": "{bookingReference}-20201126","reference": "{bookingReference}","type": "RoundTrip","isCancelled": false,"codsId": "TEST1234","travelAdmin": {"codsId": ""},"audit": {"created": {"officeId": "TEST1234","at": "2020-11-26T04:15:00Z"},"updated": {"officeId": "TEST1234","at": "2021-02-19T22:25:00Z"}},"passengers": [{"id": "PT2","title": "MR","firstName": "TEST","lastName": "TESTSSON","contact": {"phone": [{"type": "APH","number": ""},{"type": "APM","number": ""},{"type": "APU","number": ""},{"type": "APH","number": ""},{"type": "APM","number": ""},{"type": "APU","number": ""}],"email": [{"type": "APE","address": "TEST@EXAMPLE.COM"},{"type": "APE","address": "TEST@EXAMPLE.COM"}]},"frequentTraveler": {"euroBonus": [{"segmentIds": [],"carrier": "SK","tier": "EBB","number": "TEST123456"}],"other": []},"specialServiceRequests": [],"segments": [{"segmentId": "ST1","isBoarded": false,"ticket": {"number": "117-TEST123456","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "OSERSM"}},{"segmentId": "ST2","isBoarded": false,"ticket": {"number": "117-TEST123456","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "TSERSM"}}]}],"trips": [{"type": "Outbound","segments": [{"id": "ST1","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK2569-20210410-ARN-CPH","operatingId": "SK2569-20210410-ARN-CPH","operatingCarrier": "SK","operatingFlightNumber": "2569","marketingCarrier": "SK","marketingFlightNumber": "2569","departure": {"station": "ARN","scheduledTime": {"utc": "2021-04-10T07:00:00Z","local": "2021-04-10T09:00:00"},"terminal": "5"},"arrival": {"station": "CPH","scheduledTime": {"utc": "2021-04-10T08:20:00Z","local": "2021-04-10T10:20:00"},"terminal": "3"}},"bookingClass": "O","serviceClass": "M"}]},{"type": "Inbound","segments": [{"id": "ST2","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK0402-20210420-CPH-ARN","operatingId": "SK0402-20210420-CPH-ARN","operatingCarrier": "SK","operatingFlightNumber": "0402","marketingCarrier": "SK","marketingFlightNumber": "0402","departure": {"station": "CPH","scheduledTime": {"utc": "2021-04-20T05:15:00Z","local": "2021-04-20T07:15:00"},"terminal": "3"},"arrival": {"station": "ARN","scheduledTime": {"utc": "2021-04-20T06:30:00Z","local": "2021-04-20T08:30:00"},"terminal": "5"}},"bookingClass": "T","serviceClass": "M"}]}]}';
  String flightResponseBody = '[{"id": "SK2569-20210410-ARN-CPH","departureKey": "20210410ARN","carrier": "SK","flightNumber": "2569","callSign": "SAS909","serviceType": {"code": "J","application": "Scheduled"},"departure": {"scheduledTime": {"utc": "2021-04-10T10:35:00Z","local": "2021-04-10T12:35:00"},"status": "ontime","station": "ARN","stand": "E33","gate": "E135","delayedMinutes": 0},"arrival": {"scheduledTime": {"utc": "2021-04-10T19:05:00Z","local": "2021-04-10T15:05:00"},"status": "ontime","station": "CPH","delayedMinutes": 0},"aircraft": {"type": "350","registration": "SERSB"},"metadata": {"lastReceivedMethod": "GATE","lastReceivedAction": "CHG","isOfficial": false},"passengerCapacity": {"C": 40,"Y": 32,"M": 228}},{"id": "SK0402-20210420-CPH-ARN","departureKey": "20210420CPH","carrier": "SK","flightNumber": "0402","callSign": "SAS909","serviceType": {"code": "J","application": "Scheduled"},"departure": {"scheduledTime": {"utc": "2021-04-20T10:35:00Z","local": "2021-04-20T12:35:00"},"status": "ontime","station": "CPH","stand": "E33","gate": "E135","delayedMinutes": 0},"arrival": {"scheduledTime": {"utc": "2021-04-20T19:05:00Z","local": "2021-04-20T15:05:00"},"status": "ontime","station": "ARN","delayedMinutes": 0},"aircraft": {"type": "350","registration": "SERSB"},"metadata": {"lastReceivedMethod": "GATE","lastReceivedAction": "CHG","isOfficial": false},"passengerCapacity": {"C": 40,"Y": 32,"M": 228}}]';

  global HttpResponse respond(HttpRequest req) {
    String endpoint = req.getEndpoint();

    if (endpoint.contains('teds-flight')) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(flightResponseBody);
      res.setStatusCode(200);
      return res;
    } else if (endpoint.contains('teds-booking')) {
      String reference = endpoint.substring(
        endpoint.length() - 6,
        endpoint.length()
      );
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(bookingResponseBody.replace('{bookingReference}', reference));
      res.setStatusCode(200);
      return res;
    } else {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(404);
      return res;
    }
  }
}
