@isTest
global class TEDSBookingQueryNFMock implements HttpCalloutMock {
  String responseBody = '[]';

  global HttpResponse respond(HttpRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(responseBody);
    res.setStatusCode(200);
    return res;
  }
}
