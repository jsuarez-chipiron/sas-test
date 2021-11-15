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
public without sharing class TEDSIntegrationService {
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_TEDS_Subscription_Key');

  /** Fetches a single booking from TEDS based on the booking reference.
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
  }

  /** Fetches all bookings from TEDS which match the provided query.
   *
   * @param query A map of parameter names to values.
   * Possible keys for query:
   * - bookingReference: 6 character PNR or full identifier in TEDS format
   * - euroBonusNumber: A EuroBonus number in the booking without the EBX part
   *
   * @return List of the found bookings, or an empty list of none were found.
   */
  public List<IRR_MOD_TedsBooking> fetchBookingsByQuery(
    Map<String, String> query
  ) {
    HttpResponse response = makeRequest('GET', '/teds-booking/bookings', query);

    return IRR_MOD_TedsBooking.parseArray(response.getBody());
  }

  /** Fetches all flights from TEDS which match the provided query.
   *
   * @param query A map of parameter names to values.
   * Possible keys for query:
   * - ids: List of full TEDS identifiers for flights. Maximum of 10.
   *
   * @return List of the found flights, or an empty list of none were found.
   */
  public List<TEDSFlight> fetchFlightsByQuery(
    Map<String, String> query
  ) {
    HttpResponse response = makeRequest('GET', '/teds-flight/flights', query);

    return TEDSFlight.parseArray(response.getBody());
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
   * @throws IntegrationException On HTTP status codes larger than 400, other than 404.
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
        response.getStatus()
      );
    }

    return response;
  }
}
