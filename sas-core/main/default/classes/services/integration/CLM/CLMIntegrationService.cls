/**
 * Service for making requests to Comarch Loyalty Management (CLM) through the Loyalty APIM.
 */
public without sharing class CLMIntegrationService {
  private static final String PARTNER_ID = 'SKSFSC'; // Salesforce Service Cloud
  private static final String API_PATH = 'callout:CLM_APIM';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('CLM').get('CLM_APIM_Subscription_Key');

  public enum POINTS_TYPE {
    BASIC,
    EXTRA
  }

  public static CLMIntegrationService newInstance() {
    return (CLMIntegrationService) SAS_Service_Application.Service.newInstance(
      CLMIntegrationService.class
    );
  }

  public class AddPointsResponse {
    public Boolean isSuccess;
    public CLMAddPointsResponse successResponse;
    public CLMFailureResponse failureResponse;

    AddPointsResponse(CLMAddPointsResponse rawSuccessResponse) {
      this.isSuccess = true;
      this.successResponse = rawSuccessResponse;
    }

    AddPointsResponse(CLMFailureResponse rawFailureResponse) {
      this.isSuccess = false;
      this.failureResponse = rawFailureResponse;
    }
  }

  public class IntegrationException extends Exception {
  }

  /** Attempts to add a number of Extra points to a EuroBonus customer using CLM APIs.
   *
   * @param euroBonusNumber EuroBonus number of the customer for whom points should be added.
   * @param pointsToAdd Number of points to add to the customer.
   * @param ADUserEmail Email address of the user performing the action. Stored in CLM for reference.
   * @param transactionId Unique transaction ID of this points transaction.  Stored in CLM for reference.
   * @param claimId ID of the claim this is related to. Optional.  Stored in CLM for reference.
   * @param reasonForPoints Free text reason for this points transaction. Optional.
   * @param bookingReference A booking reference this points transaction is related to. Optional.
   * @param ticketNumber A ticket number this points transaction is related to. Optional.
   *
   * @throws IntegrationError on failures.
   *
   * @return CLMAddPointsResponse The parsed CLM response on status codes less than 400.
   */
  public AddPointsResponse addPointsToCustomer(
    String euroBonusNumber,
    Integer pointsToAdd,
    String ADUserEmail,
    String transactionId,
    String claimId,
    String reasonForPoints,
    String bookingReference,
    String ticketNumber
  ) {
    if (String.isBlank(ADUserEmail)) {
      C_Log.log(
        C_Log.Severity.Error,
        'Attempted to query CLM without AD User',
        null,
        'CLMIntegration',
        null
      );
      throw new IntegrationException('AD User email cannot be empty.');
    }
    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'AD-User' => ADUserEmail
    };

    String requestBody = constructUpdatePointsBody(
      euroBonusNumber,
      pointsToAdd,
      reasonForPoints,
      transactionId,
      bookingReference,
      ticketNumber,
      claimId
    );

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      '/clm/callcenter/addPoints',
      requestBody,
      null
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    if (response.getStatusCode() >= 400) {
      // Transaction failure
      return new AddPointsResponse(
        CLMFailureResponse.parse(response.getBody())
      );
    }

    return new AddPointsResponse(
      CLMAddPointsResponse.parse(response.getBody())
    );
  }

  /** Attempts to withdraw a number of Extra points from a EuroBonus customer using CLM APIs.
   *
   * @param euroBonusNumber EuroBonus number of the customer from whom points should be withdrawn.
   * @param pointsToWithdraw Number of points to withdraw from the customer.
   * @param ADUserEmail Email address of the user performing the action. Stored in CLM for reference.
   * @param transactionId Unique transaction ID of this points transaction.  Stored in CLM for reference.
   * @param claimId ID of the claim this is related to. Optional.  Stored in CLM for reference.
   * @param reasonForPoints Free text reason for this points transaction. Optional.
   * @param bookingReference A booking reference this points transaction is related to. Optional.
   * @param ticketNumber A ticket number this points transaction is related to. Optional.
   *
   * @throws IntegrationError on failures.
   *
   * @return CLMWithdrawPointsResponse The parsed CLM response on status codes less than 400.
   */
  public CLMWithdrawPointsResponse withdrawPointsFromCustomer(
    String euroBonusNumber,
    Integer pointsToWithdraw,
    String ADUserEmail,
    String transactionId,
    String claimId,
    String reasonForPoints,
    String bookingReference,
    String ticketNumber
  ) {
    if (String.isBlank(ADUserEmail)) {
      C_Log.log(
        C_Log.Severity.Error,
        'Attempted to query CLM without AD User',
        null,
        'CLMIntegration',
        null
      );
      throw new IntegrationException('AD User email cannot be empty.');
    }
    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'AD-User' => ADUserEmail
    };

    String requestBody = constructUpdatePointsBody(
      euroBonusNumber,
      pointsToWithdraw,
      reasonForPoints,
      transactionId,
      bookingReference,
      ticketNumber,
      claimId
    );

    HttpResponse response = makeRequest(
      HttpUtils.HTTP_METHOD.POST,
      '/clm/callcenter/withdrawPoints',
      requestBody,
      null
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return CLMWithdrawPointsResponse.parse(response.getBody());
  }

  private String constructUpdatePointsBody(
    String euroBonusNumber,
    Integer pointsToAdd,
    String reasonForPoints,
    String transactionId,
    String bookingReference,
    String ticketNumber,
    String claimId
  ) {
    Map<String, Object> bodyMap = new Map<String, Object>{
      'ebNumber' => euroBonusNumber,
      'pointType' => String.valueOf(POINTS_TYPE.EXTRA),
      'partnerTrnUid' => transactionId,
      'partnerid' => PARTNER_ID,
      'numPoints' => pointsToAdd
    };

    if (reasonForPoints != null) {
      bodyMap.put('reason', reasonForPoints);
    }
    if (claimId != null) {
      bodyMap.put('claimId', claimId);
    }
    if (ticketNumber != null) {
      bodyMap.put('ticketno', ticketNumber);
    }
    if (bookingReference != null) {
      bodyMap.put('pnr', bookingReference);
    }

    return JSON.Serialize(bodyMap);
  }

  /**
   * Constructs and fires a request to the CLM APIM.
   *
   * Fills in authentication headers.
   *
   * Any extra headers passed will overwrite existing headers with the same name.
   *
   * @param method HTTP method to use. See HttpRequest.setMethod for more info.
   * @param path The endpoint with queryparams to which make the query to, without the base url included in callout.
   * @param body Request body which will be passed directly to HttpRequest.setBody().
   * @param extraHeaders Any additional headers which should be sent along the request as a map from name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private static HttpResponse makeRequest(
    HttpUtils.HTTP_METHOD method,
    String path,
    String body, // Caller is responsible for creating correct object type.
    Map<String, String> extraHeaders
  ) {
    HttpRequest request = new HttpRequest();

    request.setEndpoint(API_PATH + path);
    request.setMethod(String.valueOf(method));

    request.setHeader('Ocp-Apim-Subscription-Key', SUBSCRIPTION_KEY);
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('CLMbase64', ''); // Empty for test. Set for Prod.

    request.setTimeout(120000); // In milliseconds. CLM is sometimes slow.

    if (extraHeaders != null) {
      for (String header : extraHeaders.keySet()) {
        request.setHeader(header, extraHeaders.get(header));
      }
    }

    if (body != null) {
      request.setBody(body);
    }

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 500) {
      // Log and throw again. Typically can't be resolved.
      String message =
        'CLMIntegration query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus();

      C_Log.HttpData httpDataLog = C_Log.generateLogHttpData(request);
      C_Log.log(
        C_Log.Severity.Error,
        message,
        null,
        'CLMIntegration',
        httpDataLog
      );

      throw new IntegrationException(
        'CLMIntegration query failed with: ' +
        response.getStatusCode() +
        ': ' +
        response.getStatus()
      );
    }

    return response;
  }
}
