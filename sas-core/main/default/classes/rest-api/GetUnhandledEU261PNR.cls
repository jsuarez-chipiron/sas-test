@RestResource(urlMapping='/get-eu261claim-pnr/')
global without sharing class GetUnhandledEU261PNR {
  @HttpGet
  global static EU261ClaimPNRResponse getPnrs() {
    List<LIA_Claim__c> eu261Claims = ClaimsSelector.newInstance()
      .selectUnhandledEU261ClaimsByDataStatus('Not Started');
    if (eu261Claims.size() > 0) {
      System.enqueueJob(
        new Claims.UpdateExternalDataStatusAsync(
          eu261Claims,
          Claim.ExternalDataStatus.InProgress
        )
      );
    }
    return new EU261ClaimPNRResponse(eu261Claims);
  }
}
