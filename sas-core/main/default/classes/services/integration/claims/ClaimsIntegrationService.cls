/**
 * Service for making requests to the voucher API.
 */
public without sharing class ClaimsIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM/claim/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  public static ClaimsIntegrationService newInstance() {
    return (ClaimsIntegrationService) SAS_Service_Application.Service.newInstance(
      ClaimsIntegrationService.class
    );
  }

  /** Checks whether a claim exists in CARE data in EDW for the given booking
   * reference. Returns true if one was found, false otherwise.
   *
   * @param bookingReference Booking reference to search for.
   *
   * @return Whether claims exist in EDW for the given booking reference.
   */
  public static Boolean checkIfClaimsExistForBookingReference(
    String bookingReference
  ) {
    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.GET,
      'claim' +
      '?pnr=' +
      bookingReference
    );

    if (response.getStatusCode() == 404) {
      return false;
    }

    return ClaimsCheckCAREResponse.parse(response.getBody()).claimsfound;
  }

  /**
   * Constructs and fires a request to the Claims API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use.
   * @param path The path to make the query to.
   * @param queryParams Query parameters as map of name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Accept' => 'application/json',
      'api-version' => 'v1',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      method,
      fullPath,
      null,
      extraRequestHeaders
    );
  }
}
