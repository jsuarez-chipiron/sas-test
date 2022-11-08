public without sharing class SettlementItem extends AbstractSObjectWrapper {
  public Settlement_Item__c underlyingSObject { get; private set; }

  public Id parentSettlementId;
  public String accountingFileName;
  public Decimal amount;
  public Decimal amountInSEK;
  public String comments;
  public CostAccount costAccount;
  public CostCenter costCenter;
  public Money.CurrencyCode itemCurrency;
  public String customerName;
  public Date dateOfExchangeCalculation;
  public Decimal deductibleInsuranceAmount;
  public String errorMessage;
  public Boolean isInsured = false;
  public Decimal netAmountAfterDeductible;
  public Status status;

  public enum CostAccount {
    CA6721,
    CA6722,
    CA6727,
    CA6733,
    CA6735,
    CA6737,
    CA6738,
    CA6741,
    CA6742,
    CA6743
  }

  public enum CostCenter {
    CC90801
  }

  public enum Status {
    Draft,
    PendingL1Confirmation,
    WaitingForTransfer,
    SentToRacer,
    RejectedByRacer,
    Done,
    SettlementFailed
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Accounting_File_Name__c = this.accountingFileName;
    this.underlyingSObject.Amount__c = this.amount;
    this.underlyingSObject.Amount_in_SEK__c = this.amountInSEK;
    this.underlyingSObject.Comments__c = this.comments;
    this.underlyingSObject.Cost_Account__c = COST_ACCOUNT_ENUM_TO_PICKLIST_VALUE.get(
      this.costAccount
    );
    this.underlyingSObject.Cost_Center__c = COST_CENTER_ENUM_TO_PICKLIST_VALUE.get(
      this.costCenter
    );
    this.underlyingSObject.Currency__c = Money.CURRENCY_ENUM_TO_PICKLIST_VALUE.get(
      this.itemCurrency
    );
    this.underlyingSObject.Customer_Name__c = this.customerName;
    this.underlyingSObject.Date_of_Exchange_Calculation__c = this.dateOfExchangeCalculation;
    this.underlyingSObject.Deductible_Insurance_Amount__c = this.deductibleInsuranceAmount;
    this.underlyingSObject.Error_Message__c = this.errorMessage;
    this.underlyingSObject.Is_Insured__c = this.isInsured;
    this.underlyingSObject.Net_Amount_After_Deductible__c = this.netAmountAfterDeductible;
    this.underlyingSObject.Settlement__c = this.parentSettlementId;
    this.underlyingSObject.Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.status
    );
  }

  public SettlementItem() {
    this.underlyingSObject = new Settlement_Item__c();
  }

  public SettlementItem(Settlement_Item__c si) {
    this.underlyingSObject = si;
    this.accountingFileName = si.Accounting_File_Name__c;
    this.amount = si.Amount__c;
    this.amountInSEK = si.Amount_in_SEK__c;
    this.comments = si.Comments__c;
    this.costAccount = COST_ACCOUNT_PICKLIST_VALUE_TO_ENUM.get(
      si.Cost_Account__c
    );
    this.costCenter = COST_CENTER_PICKLIST_VALUE_TO_ENUM.get(si.Cost_Center__c);
    this.itemCurrency = Money.CURRENCY_PICKLIST_VALUE_TO_ENUM.get(
      si.Currency__c
    );
    this.customerName = si.Customer_Name__c;
    this.dateOfExchangeCalculation = si.Date_of_Exchange_Calculation__c;
    this.deductibleInsuranceAmount = si.Deductible_Insurance_Amount__c;
    this.errorMessage = si.Error_Message__c;
    this.isInsured = si.Is_Insured__c;
    this.netAmountAfterDeductible = si.Net_Amount_After_Deductible__c;
    this.parentSettlementId = si.Settlement__c;
    this.status = STATUS_PICKLIST_VALUE_TO_ENUM.get(si.Status__c);
  }

  /**
   * Sets the currency and amount of this item based on the given money instance.
   */
  public void setValue(Money value) {
    this.itemCurrency = value.CurrencyCode;
    this.amount = value.amount;
  }

  private static final Map<String, CostAccount> COST_ACCOUNT_PICKLIST_VALUE_TO_ENUM = new Map<String, CostAccount>{
    '6721' => CostAccount.CA6721,
    '6722' => CostAccount.CA6722,
    '6727' => CostAccount.CA6727,
    '6733' => CostAccount.CA6733,
    '6735' => CostAccount.CA6735,
    '6737' => CostAccount.CA6737,
    '6738' => CostAccount.CA6738,
    '6741' => CostAccount.CA6741,
    '6742' => CostAccount.CA6742,
    '6743' => CostAccount.CA6743
  };

  private static final Map<CostAccount, String> COST_ACCOUNT_ENUM_TO_PICKLIST_VALUE = new Map<CostAccount, String>{
    CostAccount.CA6721 => '6721',
    CostAccount.CA6722 => '6722',
    CostAccount.CA6727 => '6727',
    CostAccount.CA6733 => '6733',
    CostAccount.CA6735 => '6735',
    CostAccount.CA6737 => '6737',
    CostAccount.CA6738 => '6738',
    CostAccount.CA6741 => '6741',
    CostAccount.CA6742 => '6742',
    CostAccount.CA6743 => '6743'
  };

  private static final Map<String, CostCenter> COST_CENTER_PICKLIST_VALUE_TO_ENUM = new Map<String, CostCenter>{
    '90801' => CostCenter.CC90801
  };

  private static final Map<CostCenter, String> COST_CENTER_ENUM_TO_PICKLIST_VALUE = new Map<CostCenter, String>{
    CostCenter.CC90801 => '90801'
  };

  private static final Map<String, Status> STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, Status>{
    'Draft' => Status.Draft,
    'Pending L1 confirmation' => Status.PendingL1Confirmation,
    'Waiting for transfer' => Status.WaitingForTransfer,
    'Sent to Racer' => Status.SentToRacer,
    'Rejected by Racer' => Status.RejectedByRacer,
    'Done' => Status.Done,
    'Settlement failed' => Status.SettlementFailed
  };

  private static final Map<Status, String> STATUS_ENUM_TO_PICKLIST_VALUE = new Map<Status, String>{
    Status.Draft => 'Draft',
    Status.PendingL1Confirmation => 'Pending L1 confirmation',
    Status.WaitingForTransfer => 'Waiting for transfer',
    Status.SentToRacer => 'Sent to Racer',
    Status.RejectedByRacer => 'Rejected by Racer',
    Status.Done => 'Done',
    Status.SettlementFailed => 'Settlement failed'
  };
}
