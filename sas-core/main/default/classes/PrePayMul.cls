public class PrePayMul {
  public ControlRecord ctrlRecord { get; set; }
  public AccountData accData { get; set; }
  public PaymentData payData { get; set; }
  public SupplierData suplData { get; set; }
  public BankData bnData { get; set; }
  public SupplierSiteData supSiteData { get; set; }
  public InvoiceData incData { get; set; }
  public InvoiceFlexFields incFleFields { get; set; }
  public string currencyType { get; set; }

  public PrePayMul(
    ControlRecord ctrlRecord,
    AccountData accData,
    PaymentData payData,
    SupplierData suplData,
    BankData bnData,
    SupplierSiteData supSiteData,
    InvoiceData incData,
    InvoiceFlexFields incFleFields,
    String currencyType
  ) {
    this.ctrlRecord = ctrlRecord;
    this.accData = accData;
    this.payData = payData;
    this.suplData = suplData;
    this.bnData = bnData;
    this.supSiteData = supSiteData;
    this.incData = incData;
    this.incFleFields = incFleFields;
    this.currencyType = currencyType;
  }

  public class ControlRecord {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String documentType;
    public String documentpurposeCode;
    public String documentCode;
    public String locationCodeText;
    public String description;
    public String referenceExt1;
    public String referenceExt2;
    public String runId;
    public GenericFields genFields;
    public ControlRecord(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String documentType,
      String documentpurposeCode,
      String documentCode,
      String locationCodeText,
      String description,
      String referenceExt1,
      String referenceExt2,
      String runId,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.documentType = documentType;
      this.documentpurposeCode = documentpurposeCode;
      this.documentCode = documentCode;
      this.locationCodeText = locationCodeText;
      this.description = description;
      this.referenceExt1 = referenceExt1;
      this.referenceExt2 = referenceExt2;
      this.runId = runId;
      this.genFields = genFields;
    }
  }
  public class AccountData {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String trxHandlingCodeExt;
    public String checkAmount;
    public String currencyCode;
    public String currencyCodeExt;
    public String ediPaymentMethod;
    public String ediPaymentMethodExt;
    public String ediPaymentFormat;
    public String ediPaymentFormatExt;
    public String bankBranchType;
    public String bankBranchTypeExt;
    public String bankAccountType;
    public String bankAccountTypeExt;
    public String vendorBankBranchType;
    public String vendorBankBranchTypeExt;
    public String vendorBankAccountType;
    public String vendorBankAccountTypeExt;
    public String vendorBankAccountNumber;
    public String eftRequester;
    public GenericFields genFields;

    public AccountData(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String trxHandlingCodeExt,
      String checkAmount,
      String currencyCode,
      String currencyCodeExt,
      String ediPaymentMethod,
      String ediPaymentMethodExt,
      String ediPaymentFormat,
      String ediPaymentFormatExt,
      String bankBranchType,
      String bankBranchTypeExt,
      String bankAccountType,
      String bankAccountTypeExt,
      String vendorBankBranchType,
      String vendorBankBranchTypeExt,
      String vendorBankAccountType,
      String vendorBankAccountTypeExt,
      String vendorBankAccountNumber,
      String eftRequester,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.trxHandlingCodeExt = trxHandlingCodeExt;
      this.checkAmount = checkAmount;
      this.currencyCode = currencyCode;
      this.currencyCodeExt = currencyCodeExt;
      this.ediPaymentMethod = ediPaymentMethod;
      this.ediPaymentMethodExt = ediPaymentMethodExt;
      this.ediPaymentFormat = ediPaymentFormat;
      this.ediPaymentFormatExt = ediPaymentFormatExt;
      this.bankBranchType = bankBranchType;
      this.bankBranchTypeExt = bankBranchTypeExt;
      this.bankAccountType = bankAccountType;
      this.bankAccountTypeExt = bankAccountTypeExt;
      this.vendorBankBranchType = vendorBankBranchType;
      this.vendorBankBranchTypeExt = vendorBankBranchTypeExt;
      this.vendorBankAccountType = vendorBankAccountType;
      this.vendorBankAccountTypeExt = vendorBankAccountTypeExt;
      this.vendorBankAccountNumber = vendorBankAccountNumber;
      this.eftRequester = eftRequester;
      this.genFields = genFields;
    }
  }

  public class PaymentData {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String bankNumber;
    public String vendorBankNumber;
    public String ediRemittanceMethod;
    public String ediRemittanceInstruction;
    public String checkRunName;
    public String checkVoucherNumber;
    public String SelectedCheckId;
    public String checkNumber;
    public String customerNumber;
    public String voidFlag;
    public String voidDate;
    public String supplierBankBranchNumber;
    public String SupplierBankBranchSwiftCode;
    public GenericFields genFields;

    public PaymentData(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String bankNumber,
      String vendorBankNumber,
      String ediRemittanceMethod,
      String ediRemittanceInstruction,
      String checkRunName,
      String checkVoucherNumber,
      String SelectedCheckId,
      String checkNumber,
      String customerNumber,
      String voidFlag,
      String voidDate,
      String supplierBankBranchNumber,
      String SupplierBankBranchSwiftCode,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.bankNumber = bankNumber;
      this.vendorBankNumber = vendorBankNumber;
      this.ediRemittanceMethod = ediRemittanceMethod;
      this.ediRemittanceInstruction = ediRemittanceInstruction;
      this.checkRunName = checkRunName;
      this.checkVoucherNumber = checkVoucherNumber;
      this.SelectedCheckId = SelectedCheckId;
      this.checkNumber = checkNumber;
      this.customerNumber = customerNumber;
      this.voidFlag = voidFlag;
      this.voidDate = voidDate;
      this.supplierBankBranchNumber = supplierBankBranchNumber;
      this.SupplierBankBranchSwiftCode = SupplierBankBranchSwiftCode;
      this.genFields = genFields;
    }
  }
  public class SupplierData {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String vendorNumber;
    public String vendorNumberExt;
    public String vendorEdiIdNumber;
    public String segment2;
    public String segment3;
    public String segment4;
    public String segment5;
    public GenericFields genFields;

    public SupplierData(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String vendorNumber,
      String vendorNumberExt,
      String vendorEdiIdNumber,
      String segment2,
      String segment3,
      String segment4,
      String segment5,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.vendorNumber = vendorNumber;
      this.vendorNumberExt = vendorNumberExt;
      this.vendorEdiIdNumber = vendorEdiIdNumber;
      this.segment2 = segment2;
      this.segment3 = segment3;
      this.segment4 = segment4;
      this.segment5 = segment5;
      this.genFields = genFields;
    }
  }

  public class BankData {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String bankSiteCodeExt;
    public String bankName;
    public String addressLine2;
    public String addressLine3;
    public String addressLine4;
    public String country;
    public String countryExt;
    public String State;
    public String stateExt;
    public String province;
    public String provinceExt;
    public GenericFields genFields;

    public BankData(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String bankSiteCodeExt,
      String bankName,
      String addressLine2,
      String addressLine3,
      String addressLine4,
      String country,
      String countryExt,
      String State,
      String stateExt,
      String province,
      String provinceExt,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.bankSiteCodeExt = bankSiteCodeExt;
      this.bankName = bankName;
      this.addressLine2 = addressLine2;
      this.addressLine3 = addressLine3;
      this.addressLine4 = addressLine4;
      this.country = country;
      this.countryExt = countryExt;
      this.State = state;
      this.stateExt = stateExt;
      this.province = province;
      this.provinceExt = provinceExt;
      this.genFields = genFields;
    }
  }
  public class SupplierSiteData {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String vendorSiteCode;
    public String vendorSiteCodeExt;
    public String vendorName;
    public String addressLine1;
    public String addressLine2;
    public String addressLine3;
    public String addressLine4;
    public String city;
    public String postalCode;
    public String country;
    public String countryExt;
    public String State;
    public String stateExt;
    public String province;
    public String provinceExt;
    public GenericFields genFields;

    public SupplierSiteData(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String vendorSiteCode,
      String vendorSiteCodeExt,
      String vendorName,
      String addressLine1,
      String addressLine2,
      String addressLine3,
      String addressLine4,
      String city,
      String postalCode,
      String country,
      String countryExt,
      String State,
      String stateExt,
      String province,
      String provinceExt,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.vendorSiteCode = vendorSiteCode;
      this.vendorSiteCodeExt = vendorSiteCodeExt;
      this.vendorName = vendorName;
      this.addressLine1 = addressLine1;
      this.addressLine2 = addressLine2;
      this.addressLine3 = addressLine3;
      this.addressLine4 = addressLine4;
      this.city = city;
      this.postalCode = postalCode;
      this.country = country;
      this.countryExt = countryExt;
      this.State = state;
      this.stateExt = stateExt;
      this.province = province;
      this.provinceExt = provinceExt;
      this.genFields = genFields;
    }
  }

  public class InvoiceData {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String checkRunName;
    public String vendorNumber;
    public String invoiceVendorNumberExt;
    public String customerNumber;
    public String invoiceNumber;
    public String invoiceDescription;
    public String paymentAmount;
    public String invoiceAmount;
    public String discountAmount;
    public GenericFields genFields;

    public InvoiceData(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String checkRunName,
      String vendorNumber,
      String invoiceVendorNumberExt,
      String customerNumber,
      String invoiceNumber,
      String invoiceDescription,
      String paymentAmount,
      String invoiceAmount,
      String discountAmount,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.checkRunName = checkRunName;
      this.vendorNumber = vendorNumber;
      this.invoiceVendorNumberExt = invoiceVendorNumberExt;
      this.customerNumber = customerNumber;
      this.invoiceNumber = invoiceNumber;
      this.invoiceDescription = invoiceDescription;
      this.paymentAmount = paymentAmount;
      this.invoiceAmount = invoiceAmount;
      this.discountAmount = discountAmount;
      this.genFields = genFields;
    }
  }

  public class InvoiceFlexFields {
    public String ref1Batch;
    public String ref2Invoice;
    public String ref3Blank;
    public String attributeCategory;
    public String attribute1;
    public String attribute2;
    public String attribute3;
    public String attribute4;
    public String attribute5;
    public GenericFields genFields;

    public InvoiceFlexFields(
      String ref1Batch,
      String ref2Invoice,
      String ref3Blank,
      String attributeCategory,
      String attribute1,
      String attribute2,
      String attribute3,
      String attribute4,
      String attribute5,
      GenericFields genFields
    ) {
      this.ref1Batch = ref1Batch;
      this.ref2Invoice = ref2Invoice;
      this.ref3Blank = ref3Blank;
      this.attributeCategory = attributeCategory;
      this.attribute1 = attribute1;
      this.attribute2 = attribute2;
      this.attribute3 = attribute3;
      this.attribute4 = attribute4;
      this.attribute5 = attribute5;
      this.genFields = genFields;
    }
  }
  public class GenericFields {
    public String recordNumber;
    public String recordLayout;
    public String recordLayoutQualifier;
    public GenericFields(
      String recordNumber,
      String recordLayout,
      String recordLayoutQualifier
    ) {
      this.recordNumber = recordNumber;
      this.recordLayout = recordLayout;
      this.recordLayoutQualifier = recordLayoutQualifier;
    }
  }
}
