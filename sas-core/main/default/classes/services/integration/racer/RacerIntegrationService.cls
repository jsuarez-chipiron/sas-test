/**
 * Service for sending files to Racer through SEIP and APIM.
 */
public without sharing class RacerIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM/customercare/';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  public enum FILE_TYPE {
    PAYMENT,
    ACCOUNTING
  }

  private static final Map<FILE_TYPE, String> FILE_TYPE_TO_ENDPOINT = new Map<FILE_TYPE, String>{
    FILE_TYPE.PAYMENT => 'postpaymentfile',
    FILE_TYPE.ACCOUNTING => 'postaccountingfile'
  };

  public class IntegrationException extends Exception {
  }

  /** Attempts to send the given file to Racer.
   * These files will be passed on asynchronously by SEIP to Racer. OK from
   * this call means only that the file was received succesfully by SEIP.
   * A separate return file will be sent to Salesforce to indicate that the
   * file was successfully received and parsed by Racer.
   *
   * See Confluence for more details.
   *
   * @param fileType Whether this is an accounting or a payment file. See FILE_TYPE. Cannot be null.
   * @param fileName Name of the file to be sent. Should include file extension. Cannot be null.
   * @param fileContent Base64 encoded string of file contents to be sent. Cannot be null.
   *
   * @return The parsed response data on success.
   *
   * @throws IntegrationException On any issues.
   */
  public String sendFile(
    FILE_TYPE fileType,
    String fileName,
    String fileContent
  ) {
    if (fileType == null || fileName == null || fileContent == null) {
      throw new IntegrationException(
        'RacerIntegrationService.sendFile# arguments cannot be null.'
      );
    }

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      FILE_TYPE_TO_ENDPOINT.get(fileType),
      fileContent,
      new Map<String, String>{ 'Filename' => fileName }
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return response.getBody();
  }

  /**
   * Constructs and fires the request.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param path The path to make the query to.
   * @param queryParams Query parameters as map of name to value.
   * @param extraHeaders Any additional headers which should be sent along the request as a map from name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    String body,
    Map<String, String> extraHeaders
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'Accept' => 'application/json',
      'api-version' => '1',
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
