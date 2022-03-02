public without sharing class ClaimService {
  private static ClaimsSelector claims = ClaimsSelector.newInstance();

  @future(callout=true)
  public static void checkIfClaimsExistInCARE(
    Id claimId,
    String bookingReference
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    LIA_Claim__c claim = claims.selectById(new Set<Id>{ claimId })[0];
    claim.Claims_Exist_In_CARE_For_PNR__c = ClaimsIntegrationService.checkIfClaimsExistForBookingReference(
      bookingReference
    );
    claim.Last_Checked_Claims_From_CARE__c = Datetime.now();

    uow.registerDirty(claim);
    uow.commitWork();
  }
}
