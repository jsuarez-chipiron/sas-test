@RestResource(urlMapping='/get-eu261claim-pnr/')
global with sharing class GetUnhandledEU261PNR {
  @HttpGet
  global static EU261ClaimPNRResponse getPnrs() {
    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectUnhandledClaimsToFetchBookingData();
    return new EU261ClaimPNRResponse(claims);
  }
}
