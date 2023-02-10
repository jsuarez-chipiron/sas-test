global with sharing class EU261ClaimPNRResponse {
  global List<EU261ClaimInfo> pnrList;
  public EU261ClaimPNRResponse(List<LIA_Claim__c> toReturn) {
    this.pnrList = new List<EU261ClaimInfo>();
    for (LIA_Claim__c cl : toReturn) {
      this.pnrList.add(new EU261ClaimInfo(cl));
    }
  }

  global class EU261ClaimInfo {
    global Id claimId;
    global String pnr;
    global String flightNumber;
    global Date flightDate;
    public EU261ClaimInfo(LIA_Claim__c claim) {
      this.claimId = claim.Id;
      this.pnr = claim.Liability_PNR__c;
      this.flightNumber = claim.Flight_Number__c;
      this.flightDate = claim.Flight_Date__c;
    }
  }
}
