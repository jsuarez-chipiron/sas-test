/**
 * Service for making requests to the voucher API.
 */
public without sharing class VoucherIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM_VOUCHER/vouchers/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Voucher_Subscription_Key');

  /** Attempts to create a voucher with the given information.
   *
   * @param voucherToCreate Details for the voucher.
   *
   * @return The parsed response data as VoucherCreateResponse on success.
   */
  public VoucherCreateResponse createVoucher(
    VoucherCreateRequest voucherToCreate
  ) {
    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      '',
      JSON.serialize(voucherToCreate)
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return VoucherCreateResponse.parse(response.getBody());
  }

  /**
   * Constructs and fires a request to the Voucher API.
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
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    String body
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Accept' => 'application/json',
      'api-version' => '1',
      'Content-Type' => 'application/json',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      method,
      fullPath,
      body,
      extraRequestHeaders
    );
  }
}