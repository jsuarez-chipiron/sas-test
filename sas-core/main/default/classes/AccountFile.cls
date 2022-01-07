/**
@author Thippeswamy Aravinda
Date : Dec-23-2021
*/
public class AccountFile {
  public string acc_RecordIdentifier;
  public string acc_Aun;
  public string acc_VerificationNumber;
  public Date acc_ConversationDate;
  public string acc_NaturalAccount;
  public string acc_Center;
  public string acc_ReconciliationReference;
  public string acc_Product;
  public string acc_CounterPart;
  public string acc_Misc1;
  public string acc_Misc2;
  public string acc_EntCurrency;
  public string acc_DebitOrcredit;
  public string acc_Amount;
  public string acc_Description;
  public string acc_CompanyCode;
  public string acc_Period;
  public string acc_FeederName;
  public string acc_DelivNo;

  public AccountFile(
    Date acc_ConversationDate,
    string acc_NaturalAccount,
    string acc_ReconciliationReference,
    string acc_EntCurrency,
    string acc_Amount
  ) {
    this.acc_ConversationDate = acc_ConversationDate;
    this.acc_NaturalAccount = acc_NaturalAccount;
    this.acc_ReconciliationReference = acc_ReconciliationReference;
    this.acc_EntCurrency = acc_EntCurrency;
    this.acc_Amount = acc_Amount;
  }
}
