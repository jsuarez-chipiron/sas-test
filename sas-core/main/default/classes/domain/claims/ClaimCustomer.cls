public without sharing class ClaimCustomer extends AbstractSObjectWrapper {
  public Customer__c underlyingSObject { get; private set; }

  public Id parentClaimId;
  public String firstName;
  public String lastName;

  public String fullName {
    get {
      return firstName + ' ' + lastName;
    }
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.First_Name__c = this.firstName;
    this.underlyingSObject.Last_Name__c = this.lastName;
    this.underlyingSObject.Claim__c = this.parentClaimId;
  }

  @TestVisible
  private ClaimCustomer() {
    this.underlyingSObject = new Customer__c();
  }

  public ClaimCustomer(Claim parentClaim) {
    this();
    this.parentClaimId = parentClaim.id;
  }

  public ClaimCustomer(Customer__c c) {
    super(c);
    this.underlyingSObject = c;
    this.firstName = c.First_Name__c;
    this.lastName = c.Last_Name__c;
    this.parentClaimId = c.Claim__c;
  }
}
