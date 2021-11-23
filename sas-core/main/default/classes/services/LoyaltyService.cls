public without sharing class LoyaltyService {
  static CLMIntegrationService IntegrationService = (CLMIntegrationService) SAS_Service_Application.Service.newInstance(
    CLMIntegrationService.class
  );

  // TODO: Comments when scope is clear.
  @future(callout=true)
  public static void addPointsToCustomer(
    String euroBonusNumber,
    Integer pointsToAdd,
    String transactionId,
    String claimId,
    String reasonForPoints,
    String bookingReference,
    String ticketNumber
  ) {
    // TODO: Save what happened as some record in Salesforce.
    // TODO: Pass correct incoming data into the
    // TODO: Consider where the logic of figuring out trnId etc. belongs to. Probably to here.
    String userEmail = System.UserInfo.getUserEmail();

    CLMAddPointsResponse resp = IntegrationService.addPointsToCustomer(
      euroBonusNumber,
      pointsToAdd,
      userEmail,
      transactionId,
      claimId,
      reasonForPoints,
      bookingReference,
      ticketNumber
    );
  }

  // TODO: Comments when scope is clear.
  @future(callout=true)
  public static void withdrawPointsFromCustomer(
    String euroBonusNumber,
    Integer pointsToWithdraw,
    String transactionId,
    String claimId,
    String reasonForPoints,
    String bookingReference,
    String ticketNumber
  ) {
    // TODO: Save what happened as some record in Salesforce.
    // TODO: Pass correct incoming data into the
    // TODO: Consider where the logic of figuring out trnId etc. belongs to. Probably to here.
    String userEmail = System.UserInfo.getUserEmail();

    CLMWithdrawPointsResponse resp = IntegrationService.withdrawPointsFromCustomer(
      euroBonusNumber,
      pointsToWithdraw,
      userEmail,
      transactionId,
      claimId,
      reasonForPoints,
      bookingReference,
      ticketNumber
    );

    System.debug(resp);
  }
}
