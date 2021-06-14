@isTest
global class TEDSBookingSingle404Mock implements HttpCalloutMock {
  String responseBody = 'Not found';

  global HttpResponse respond(HttpRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'text/plain');
    res.setBody(responseBody);
    res.setStatusCode(404);
    return res;
  }
}
