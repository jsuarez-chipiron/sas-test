@isTest
global class APIMMock implements HttpCalloutMock {
  public static final String INVALID_BOOKING_REFERENCE = 'AAAAAA';
  public static final String EB_NUMBER_WITHOUT_BOOKINGS = 'TEST654321';

  global HttpResponse respond(HttpRequest req) {
    String endpoint = req.getEndpoint();
    HttpResponse res = new HttpResponse();
    res.setStatusCode(200);

    if (endpoint.contains('teds-flight')) {
      res.setHeader('Content-Type', 'application/json');
      res.setBody(APIMMockResponses.FLIGHT_RESPONSE_BODY);
    } else if (endpoint.contains('/teds-booking/bookings/')) {
      res.setHeader('Content-Type', 'application/json');
      // Single booking
      String reference = endpoint.substring(
        endpoint.length() - 6,
        endpoint.length()
      );
      if (reference == INVALID_BOOKING_REFERENCE) {
        res.setStatusCode(404);
        res.setHeader('Content-Type', 'text/plain');
        res.setBody('Not found');
      } else {
        res.setBody(
          APIMMockResponses.SINGLE_BOOKING_RESPONSE_BODY.replace(
            '{bookingReference}',
            reference
          )
        );
      }
    } else if (endpoint.contains('/teds-booking/bookings?')) {
      // Bookings query
      res.setHeader('Content-Type', 'application/json');
      String reference = 'TEST21';

      String euroBonusNumber = endpoint.substringBetween(
        'euroBonusNumber=',
        '&'
      ); // grab EuroBonus queryparam to insert in response
      if (euroBonusNumber == null || euroBonusNumber.length() == 0) {
        // if not found, check if it's the last one
        euroBonusNumber = endpoint.substringAfter('euroBonusNumber=');
        if (euroBonusNumber == null || euroBonusNumber.length() == 0) {
          // doesn't seem to exist
          euroBonusNumber = 'TEST987654';
        }
      }

      if (euroBonusNumber == EB_NUMBER_WITHOUT_BOOKINGS) {
        res.setBody('[]');
      } else {
        res.setBody(
          APIMMockResponses.BOOKINGS_QUERY_RESPONSE_BODY.replace(
              '{bookingReference}',
              reference
            )
            .replace('{euroBonusNumber}', euroBonusNumber)
        );
      }
    } else if (endpoint.contains('csharkservice')) {
      if (
        req.getHeader('SOAPAction') ==
        CSharkIntegrationService.SOAP_ACTION_HEADER_BASE +
        String.valueOf(
          CSharkIntegrationService.OperationName.TPAccountGetTicketless
        )
      ) {
        res.setHeader('Content-Type', 'text/xml');
        res.setBody(APIMMockResponses.TP_ACCOUNT_RESPONSE_BODY);
      } else {
        res.setStatusCode(404);
      }
    } else if (endpoint.contains('voucher')) {
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"link":"test.sas.se", "caseId": "12345678"}');
    } else if (endpoint.contains('customercare')) {
      res.setStatusCode(200);
    } else {
      res.setStatusCode(404);
    }
    return res;
  }
}
