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
  private static final String API_PATH = 'callout:SAS_APIM_TEDS_FCS';
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
      '/teds-booking/bookings/' + bookingReference,
      null
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
    List<List<String>> query
  ) {
    HttpResponse response = makeRequest('/teds-booking/bookings', query);

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
  public List<TEDSFlight> fetchFlightsByQuery(List<List<String>> query) {
    HttpResponse response = makeRequest('/teds-flight/flights', query);

    return TEDSFlight.parseArray(response.getBody());
  }

  /**
   * Constructs and fires a request to the TEDS API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param path The path to make the query to.
   * @param queryParams Query parameters as map of name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private HttpResponse makeRequest(
    String path,
    List<List<String>> queryParams
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    fullPath += HttpUtils.constructQueryParamString(queryParams);

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'api-version' => 'v2',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      HttpUtils.HTTP_METHOD.GET,
      fullPath,
      null,
      extraRequestHeaders
    );
  }
}
