/**
 * Service for fetching booking and flight data from the TEDS API.
 *
 * For the time being this duplicates some functionality from the IRR TEDS integration code.
 * This is intentional to not couple the teams' workflows. Let's look into a way to merge
 * these in future.
 *
 * For more information see:
 *   https://sas-digital.atlassian.net/wiki/spaces/CSSolutions/pages/2342289428/Planned%2BTEDS%2BAPI
 */
public with sharing class TEDSIntegrationService {
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_TEDS_Subscription_Key');

  /** TODO: Implement me
   *
   * @param bookingReference Either 6 character PNR or full booking identifier.
   *
   * @return The parsed booking data as IRR_MOD_TedsBooking if one was found, null otherwise.
   */
  public IRR_MOD_TedsBooking fetchBookingByReference(String bookingReference) {
    HttpResponse response = makeRequest(
      'GET',
      '/teds-booking/bookings/' + bookingReference
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return IRR_MOD_TedsBooking.parse(response.getBody());
    // return new List<IRR_MOD_TedsBooking>();

    /* String jsonn = '{"id": "VKQLKR-20201126","reference": "VKQLKR","type": "RoundTrip","isCancelled": false,"codsId": "000364992","travelAdmin": {"codsId": ""},"audit": {"created": {"officeId": "STOSK08RV","at": "2020-11-26T04:15:00Z"},"updated": {"officeId": "NCESK0553","at": "2021-02-19T22:25:00Z"}},"passengers": [{"id": "PT2","title": "MR","firstName": "GUSTAF","lastName": "DOUGLAS","contact": {"phone": [{"type": "APH","number": "+33492943368"},{"type": "APM","number": "+33492943368"},{"type": "APU","number": "+33492943368"},{"type": "APH","number": "+3312345879"},{"type": "APM","number": "+334647681157"},{"type": "APU","number": "+33123456897"}],"email": [{"type": "APE","address": "NO-REPLY_RECEIPT@AMADEUS.COM"},{"type": "APE","address": "NO-REPLY@AMADEUS.COM"}]},"frequentTraveler": {"euroBonus": [{"segmentIds": [],"carrier": "SK","tier": "EBB","number": "000364992"}],"other": []},"specialServiceRequests": [],"segments": [{"segmentId": "ST1","isBoarded": false,"ticket": {"number": "117-2472136245","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "OSERSM"}},{"segmentId": "ST2","isBoarded": false,"ticket": {"number": "117-2472136245","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "TSERSM"}}]}],"trips": [{"type": "Outbound","segments": [{"id": "ST1","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK2569-20210410-ARN-CPH","operatingId": "SK2569-20210410-ARN-CPH","operatingCarrier": "SK","operatingFlightNumber": "2569","marketingCarrier": "SK","marketingFlightNumber": "2569","departure": {"station": "ARN","scheduledTime": {"utc": "2021-04-10T07:00:00Z","local": "2021-04-10T09:00:00"},"terminal": "5"},"arrival": {"station": "CPH","scheduledTime": {"utc": "2021-04-10T08:20:00Z","local": "2021-04-10T10:20:00"},"terminal": "3"}},"bookingClass": "O","serviceClass": "M"}]},{"type": "Inbound","segments": [{"id": "ST2","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK0402-20210420-CPH-ARN","operatingId": "SK0402-20210420-CPH-ARN","operatingCarrier": "SK","operatingFlightNumber": "0402","marketingCarrier": "SK","marketingFlightNumber": "0402","departure": {"station": "CPH","scheduledTime": {"utc": "2021-04-20T05:15:00Z","local": "2021-04-20T07:15:00"},"terminal": "3"},"arrival": {"station": "ARN","scheduledTime": {"utc": "2021-04-20T06:30:00Z","local": "2021-04-20T08:30:00"},"terminal": "5"}},"bookingClass": "T","serviceClass": "M"}]}]}';
        List<IRR_MOD_TedsBooking> toReturn = new List<IRR_MOD_TedsBooking>();
        toReturn.add(IRR_MOD_TedsBooking.parse(jsonn));
        return toReturn;*/
  }

  /** TODO: Implement me
   *
   * Possible keys:
   * - bookingReference: 6 character PNR or full identifier in TEDS format
   * - euroBonusNumber:
   *
   * @return List of the found bookings, or an empty list of none were found.
   */
  public List<IRR_MOD_TedsBooking> fetchBookingsByQuery(
    Map<String, String> query
  ) {
    HttpResponse response = makeRequest('GET', '/teds-booking/bookings', query);

    return IRR_MOD_TedsBooking.parseArray(response.getBody());
  }

  public class IntegrationException extends Exception {
  }

  /**
   * Constructs and fires a request to the TEDS API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param endPoint The endpoint to make the query to, without the base url included in callout.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private HttpResponse makeRequest(String method, String endPoint) {
    return makeRequest(method, endPoint, null);
  }

  /**
   * Constructs and fires a request to the TEDS API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param endPoint The endpoint to make the query to, without the base url included in callout.
   * @param queryParams Query parameters as map of name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private HttpResponse makeRequest(
    String method,
    String endPoint,
    Map<String, String> queryParams
  ) {
    HttpRequest request = new HttpRequest();

    String path = endPoint;

    if (queryParams != null) {
      path += '?';
      Boolean isFirst = true;
      for (String param : queryParams.keySet()) {
        if (isFirst) {
          path += param + '=' + queryParams.get(param);
          isFirst = false;
        } else {
          path += '&' + param + '=' + queryParams.get(param);
        }
      }
    }

    request.setEndpoint('callout:SAS_APIM_TEDS_FCS' + path);
    request.setMethod(method);

    request.setHeader('api-version', 'v2');
    request.setHeader('sas-system-name', 'Salesforce');
    request.setHeader('sas-tracking-id', C_Util.generateUUID());
    request.setHeader('Ocp-Apim-Subscription-Key', SUBSCRIPTION_KEY);

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 400 && response.getStatusCode() != 404) {
      throw new TEDSIntegrationService.IntegrationException(
        'TEDS query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus() +
        ' // Query: ' +
        request.getEndpoint() +
        ' // Headers: ' +
        request.getHeader('Ocp-Apim-Subscription-Key')
      );
    }

    return response;
  }
}
