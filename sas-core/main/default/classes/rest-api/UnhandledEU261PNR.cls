@RestResource(urlMapping='/claim/eu261')
global without sharing class UnhandledEU261PNR {
  private static ClaimsSelector claimsSel = ClaimsSelector.newInstance();

  @HttpGet
  global static EU261ClaimPNRResponse doGet() {
    List<LIA_Claim__c> eu261Claims = claimsSel
      .selectUnhandledEU261ClaimsByDataStatus('Not Started');
    return new EU261ClaimPNRResponse(eu261Claims);
  }

  @HttpPut
  global static void doPut(List<String> processedClaimIds) {
    RestResponse res = RestContext.response;
    Set<Id> claimIds = new Set<Id>((List<Id>) processedClaimIds);
    List<LIA_Claim__c> eu261Claims = claimsSel.selectById(claimIds);

    try {
      if (eu261Claims.size() == 0) {
        C_RestUtil.badRequest('Invalid list of claim Ids');
      }
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      Claims claimsDomain = Claims.newInstance(eu261Claims);
      claimsDomain.updateExternalDataStatus(
        Claim.ExternalDataStatus.InProgress,
        uow
      );
      uow.commitWork();
      res.statusCode = 204;
    } catch (Exception e) {
      C_RestUtil.handleException(e);
    }
  }
}
