@IsTest
public with sharing class CLMIntegrationServiceTest {
  public static String ebNumber = 'TEST123456';
  public static String transactionId = 'TEST123456';
  public static String bookingReference = 'TEST12';
  public static String claimId = 'TEST23';
  public static String reasonForPoints = 'TEST';
  public static String ticketNumber = '117-1234567890';
  public static String testEmail = 'test@example.com';

  static CLMIntegrationService IntegrationService = (CLMIntegrationService) SAS_Service_Application.Service.newInstance(
    CLMIntegrationService.class
  );

  @IsTest
  public static void itsPossibleToAddPointsWithMinimalData() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CLMAddPointsResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    CLMAddPointsResponse resp = IntegrationService.addPointsToCustomer(
      ebNumber,
      100,
      testEmail,
      transactionId,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      'operation completed succesfully',
      resp.transactionStatus,
      'It should be possible to add points with minimal provided data set.'
    );
  }

  @IsTest
  public static void itsPossibleToAddPointsWithFullData() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CLMAddPointsResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    CLMAddPointsResponse resp = IntegrationService.addPointsToCustomer(
      ebNumber,
      100,
      testEmail,
      transactionId,
      claimId,
      reasonForPoints,
      bookingReference,
      ticketNumber
    );
    Test.stopTest();

    System.assertEquals(
      'operation completed succesfully',
      resp.transactionStatus,
      'It should be possible to add points with full provided data set.'
    );
  }

  @IsTest
  public static void itsPossibleToWithdrawPointsWithMinimalData() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CLMWithdrawPointsResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    CLMWithdrawPointsResponse resp = IntegrationService.withdrawPointsFromCustomer(
      ebNumber,
      100,
      testEmail,
      transactionId,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      'operation completed succesfully',
      resp.transactionStatus,
      'It should be possible to withdraw points with minimal provided data set.'
    );
  }

  @IsTest
  public static void itsPossibleToWithdrawPointsWithFullData() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CLMWithdrawPointsResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    CLMWithdrawPointsResponse resp = IntegrationService.withdrawPointsFromCustomer(
      ebNumber,
      100,
      testEmail,
      transactionId,
      claimId,
      reasonForPoints,
      bookingReference,
      ticketNumber
    );
    Test.stopTest();

    System.assertEquals(
      'operation completed succesfully',
      resp.transactionStatus,
      'It should be possible to withdraw points with full provided data set.'
    );
  }

  @IsTest
  public static void itsNotPossibleToPerformCLMActionsWithoutEmail() {
    try {
      IntegrationService.addPointsToCustomer(
        ebNumber,
        100,
        null,
        transactionId,
        null,
        null,
        null,
        null
      );
    } catch (Exception e) {
      System.assertEquals(
        'AD User email cannot be empty.',
        e.getMessage(),
        'Attempting to add points without an email should fail with an exception.'
      );
    }
    try {
      IntegrationService.withdrawPointsFromCustomer(
        ebNumber,
        100,
        null,
        transactionId,
        null,
        null,
        null,
        null
      );
    } catch (Exception e) {
      System.assertEquals(
        'AD User email cannot be empty.',
        e.getMessage(),
        'Attempting to add points without an email should fail with an exception.'
      );
    }
  }

  @IsTest
  public static void itThrowsIntegrationExceptionOnUpstreamErrors() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CLMFailureResponse');
    mock.setStatusCode(500);
    mock.setHeader('Content-Type', 'text/plain');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    try {
      IntegrationService.addPointsToCustomer(
        ebNumber,
        100,
        testEmail,
        transactionId,
        null,
        null,
        null,
        null
      );
      System.assert(false, 'Should have thrown an error earlier.');
    } catch (Exception e) {
      System.assert(
        e.getMessage().contains('CLMIntegration'),
        'Caught error should be a CLM integration error.'
      );
    }
    Test.stopTest();
  }
}
