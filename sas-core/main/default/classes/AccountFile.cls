/**
@author Thippeswamy Aravinda
Date : Dec-23-2021
*/
public class AccountFile {
  public string acc_RecordIdentifier;
  public string acc_Aun;
  public string acc_VerificationNumber;
  public string acc_ConcersationDate;
  public string acc_NeutralAccount;
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
    string acc_RecordIdentifier,
    string acc_Aun,
    string acc_VerificationNumber,
    string acc_ConcersationDate,
    string acc_NeutralAccount,
    string acc_Center,
    string acc_ReconciliationReference,
    string acc_Product,
    string acc_CounterPart,
    string acc_Misc1,
    string acc_Misc2,
    string acc_EntCurrency,
    string acc_DebitOrcredit,
    string acc_Amount,
    string acc_Description,
    string acc_CompanyCode,
    string acc_Period,
    string acc_FeederName,
    string acc_DelivNo
  ) {
    this.acc_RecordIdentifier = acc_RecordIdentifier;
    this.acc_Aun = acc_Aun;
    this.acc_VerificationNumber = acc_VerificationNumber;
    this.acc_ConcersationDate = acc_ConcersationDate;
    this.acc_NeutralAccount = acc_NeutralAccount;
    this.acc_Center = acc_Center;
    this.acc_ReconciliationReference = acc_ReconciliationReference;
    this.acc_Product = acc_Product;
    this.acc_CounterPart = acc_CounterPart;
    this.acc_Misc1 = acc_Misc1;
    this.acc_Misc2 = acc_Misc2;
    this.acc_EntCurrency = acc_EntCurrency;
    this.acc_DebitOrcredit = acc_DebitOrcredit;
    this.acc_Amount = acc_Amount;
    this.acc_Description = acc_Description;
    this.acc_CompanyCode = acc_CompanyCode;
    this.acc_Period = acc_Period;
    this.acc_FeederName = acc_FeederName;
    this.acc_DelivNo = acc_DelivNo;
  }
}
