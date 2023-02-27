@RestResource(urlMapping='/eu261claim-pnr/')
global without sharing class GetUnhandledEU261PNR {
  private static ClaimsSelector claimsSel = ClaimsSelector.newInstance();

  @HttpGet
  global static EU261ClaimPNRResponse getPnrs() {
    List<LIA_Claim__c> eu261Claims = claimsSel
      .selectUnhandledEU261ClaimsByDataStatus('Not Started');
    return new EU261ClaimPNRResponse(eu261Claims);
  }

  @HttpPost
  global static void updatePnrs(List<String> processedClaimIds) {
    RestResponse res = RestContext.response;
    String responseText;
    Set<Id> claimIds = new Set<Id>((List<Id>) processedClaimIds);
    List<LIA_Claim__c> eu261Claims = claimsSel.selectById(claimIds);
    if (eu261Claims.size() == 0) {
      res.statusCode = 404;
      responseText = 'Could not find records to update';
    } else {
      try {
        fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
        Claims claimsDomain = Claims.newInstance(eu261Claims);
        claimsDomain.updateExternalDataStatus(
          Claim.ExternalDataStatus.InProgress,
          uow
        );
        uow.commitWork();
        responseText = 'Successfully updated records';
      } catch (Exception e) {
        res.statusCode = 500;
        responseText = 'Could not update records';
      }
    }
    res.responseBody = Blob.valueOf(responseText);
  }
}
