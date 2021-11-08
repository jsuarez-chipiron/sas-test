/**
 * Service for making requests to API Management (APIM).
 */
public without sharing class APIMIntegrationService {
  private static final String SYSTEM_NAME = 'Salesforce';

  public class IntegrationException extends Exception {
  }

  /**
   * Constructs and fires a request to the APIM.
   *
   * Fills in authentication and tracing headers.
   *
   * Any extra headers passed will overwrite existing headers with the same name.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param path The endpoint with queryparams to which make the query to, without the base url included in callout.
   * @param body Request body which will be passed directly to HttpRequest.setBody().
   * @param extraHeaders Any additional headers which should be sent along the request as a map from name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  public static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    String body, // Caller is responsible for creating correct object type.
    Map<String, String> extraHeaders
  ) {
    HttpRequest request = new HttpRequest();

    request.setEndpoint(path);
    request.setMethod(String.valueOf(method));

    request.setHeader('sas-system-name', SYSTEM_NAME);
    request.setHeader('sas-tracking-id', C_Util.generateUUID());

    for (String header : extraHeaders.keySet()) {
      request.setHeader(header, extraHeaders.get(header));
    }

    if (body != null) {
      request.setBody(body);
    }

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 400 && response.getStatusCode() != 404) {
      // Log and throw again. Typically can't be resolved.
      String message =
        'APIM query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus();

      C_Log.HttpData httpDataLog = C_Log.generateLogHttpData(request);
      C_Log.log(C_Log.Severity.Error, message, null, 'APIM', httpDataLog);

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
