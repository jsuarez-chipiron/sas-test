@RestResource(urlMapping='/get-eu261claim-pnr/')
global without sharing class GetUnhandledEU261PNR {
  @HttpGet
  global static EU261ClaimPNRResponse getPnrs() {
    List<LIA_Claim__c> eu261Claims = ClaimsSelector.newInstance()
      .selectUnhandledEU261ClaimsByDataStatus('Not Started');

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Claims claimsDomain = Claims.newInstance(eu261Claims);
    claimsDomain.updateExternalDataStatus(
      Claim.ExternalDataStatus.InProgress,
      uow
    );
    uow.commitWork();
    return new EU261ClaimPNRResponse(eu261Claims);
  }
}
