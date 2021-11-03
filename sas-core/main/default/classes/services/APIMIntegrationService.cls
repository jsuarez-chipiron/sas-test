/**
 * Service for making requests to API Management (APIM).
 */
public without sharing class APIMIntegrationService {
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_Subscription_Key');

  private static final String ENDPOINT = 'callout:SAS_APIM';

  public class IntegrationException extends Exception {
  }

  public enum HTTP_METHOD {
    GET,
    POST
  }

  /*private HttpResponse makeRequest(HTTP_METHOD method, String endPoint) {
    return;
  }*/

  /**
   * Constructs and fires a request to the APIM.
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
  public static HttpResponse makeRequest(
    HTTP_METHOD method,
    String endPoint,
    Map<String, String> queryParams,
    String body, // Caller is responsible for creating correct object type.
    Map<String, String> extraHeaders
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

    request.setEndpoint(ENDPOINT + path);
    request.setMethod(String.valueOf(method));

    request.setHeader('api-version', 'v2');
    request.setHeader('sas-system-name', 'Salesforce');
    request.setHeader('sas-tracking-id', C_Util.generateUUID());
    request.setHeader('Ocp-Apim-Subscription-Key', SUBSCRIPTION_KEY);

    if (body != null) {
      request.setBody(body);
    }

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 400 && response.getStatusCode() != 404) {
      throw new IntegrationException(
        'APIM query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus()
      );
    }

    return response;
  }
}
