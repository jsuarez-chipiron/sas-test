/**
 * Represents an individual claim with one-to-one mapping to the underlying
 * sObject.
 */
public without sharing class Customer extends AbstractSObjectWrapper {
  public Customer__c underlyingSObject { get; private set; }

  public Id parentClaimId;
  public String firstName;
  public String lastName;

  public override void updateSObjectFields() {
    this.underlyingSObject.First_Name__c = this.firstName;
    this.underlyingSObject.Last_Name__c = this.lastName;
    this.underlyingSObject.Claim__c = this.parentClaimId;
  }
  private Customer() {
    this.underlyingSObject = new Customer__c();
  }

  public Customer(Claim parentClaim) {
    this();
    this.parentClaimId = parentClaim.id;
  }

  public Customer(Customer__c c) {
    super(c);
    this.firstName = c.First_Name__c;
    this.lastName = c.Last_Name__c;
    this.parentClaimId = c.Claim__c;
  }
}
