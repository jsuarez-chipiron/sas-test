public without sharing class LoyaltyService {
  static CLMIntegrationService IntegrationService = (CLMIntegrationService) SAS_Service_Application.Service.newInstance(
    CLMIntegrationService.class
  );

  @future(callout=true)
  public static void addPointsToAccount(
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

    CLMAddPointsResponse resp = IntegrationService.addPointsToUser(
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
}
