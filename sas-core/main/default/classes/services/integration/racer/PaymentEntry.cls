/**
 * This file includes mostly data parameters for creating the payment files.
 *
 * See ConstructPaymentFile more details.
 *
 * Check the class constructor for the building logic.
 */

public class PaymentEntry {
  // Defines the field lengths in columns for all fields in all records.
  public static final Map<String, Map<String, Integer>> FIELD_LENGTHS = new Map<String, Map<String, Integer>>{
    'controlRecord' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'communicationMethod' => 2,
      'testFlag' => 1,
      'documentId' => 6,
      'documentType' => 5,
      'documentPurposeCode' => 2,
      'documentCode' => 35,
      'translatorCode' => 30,
      'locationCodeExt' => 35,
      'description' => 74,
      'referenceExt1' => 80,
      'referenceExt2' => 80,
      'transactionDate' => 15,
      'runId' => 15,
      'documentStandard' => 10
    },
    'accountData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'transactionHandlingCode' => 25,
      'trxHandlingCodeExt' => 3,
      'checkAmount' => 22,
      'currencyCode' => 15,
      'currencyCodeExt' => 3,
      'EDIPaymentMethod' => 25,
      'EDIPaymentMethodExt' => 3,
      'EDIPaymentFormat' => 25,
      'EDIPaymentFormatExt' => 10,
      'bankBranchType' => 25,
      'bankBranchTypeExt' => 10,
      'bankAccountType' => 25,
      'bankAccountTypeExt' => 10,
      'bankAccountNumber' => 30,
      'bankEDIIDNumber' => 30,
      'vendorBankBranchType' => 25,
      'vendorBankBranchTypeExt' => 10,
      'vendorBankAccountType' => 25,
      'vendorBankAccountTypeExt' => 10,
      'vendorBankAccountNumber' => 35,
      'paymentDate' => 15,
      'accountHolderName' => 15,
      'EFTRequester' => 15
    },
    'paymentData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'bankNumber' => 25,
      'vendorBankNumber' => 25,
      'EDIRemittanceMethod' => 25,
      'EDIRemittanceInstruction' => 80,
      'checkrunName' => 30,
      'checkVoucherNumber' => 22,
      'selectedCheckId' => 15,
      'checkNumber' => 22,
      'customerNumber' => 25,
      'voidFlag' => 1,
      'voidDate' => 15,
      'supplierBankBranchNumber' => 25,
      'supplierBankBranchSWIFTCode' => 12
    },
    'supplierData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'vendorNumber' => 30,
      'vendorNumberExt' => 30,
      'vendorEDIIDNumber' => 30,
      'Segment2' => 30,
      'Segment3' => 30,
      'Segment4' => 30,
      'Segment5' => 30
    },
    'bankData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'bankSiteCode' => 20,
      'bankSiteCodeExt' => 20,
      'bankName' => 60,
      'addressLine1' => 35,
      'addressLine2' => 35,
      'addressLine3' => 35,
      'addressLine4' => 35,
      'city' => 30,
      'postalCode' => 15,
      'country' => 20,
      'countryExt' => 3,
      'state' => 20,
      'stateExt' => 10,
      'province' => 20,
      'provinceExt' => 10
    },
    'supplierSiteData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'vendorSiteCode' => 20,
      'vendorSiteCodeExt' => 20,
      'vendorName' => 60,
      'addressLine1' => 35,
      'addressLine2' => 35,
      'addressLine3' => 35,
      'addressLine4' => 35,
      'city' => 30,
      'postalCode' => 15,
      'country' => 20,
      'countryExt' => 3,
      'state' => 20,
      'stateExt' => 10,
      'province' => 20,
      'provinceExt' => 10
    },
    'invoiceData' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'checkrunName' => 30,
      'vendorNumber' => 30,
      'vendorNumberExt' => 20,
      'customerNumber' => 25,
      'invoiceNumber' => 50,
      'invoiceDate' => 15,
      'invoiceDescription' => 50,
      'paymentAmount' => 22,
      'invoiceAmount' => 22,
      'discountAmount' => 22
    },
    'invoiceFlexfields' => new Map<String, Integer>{
      'tradingPartnerCode' => 25,
      'ref1Batch' => 22,
      'ref2Invoice' => 22,
      'ref3Blank' => 22,
      'recordNumber' => 4,
      'recordLayout' => 2,
      'recordLayoutQualifier' => 3,
      'attributeCategory' => 30,
      'attribute1' => 80,
      'attribute2' => 80,
      'attribute3' => 80,
      'attribute4' => 80,
      'attribute5' => 30
    }
  };

  // Defines the order fields should be for a given record.
  public static final Map<String, List<String>> FIELDS_IN_ORDER_BY_RECORD = new Map<String, List<String>>{
    'controlRecord' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'communicationMethod',
      'testFlag',
      'documentId',
      'documentType',
      'documentPurposeCode',
      'documentCode',
      'translatorCode',
      'locationCodeExt',
      'description',
      'referenceExt1',
      'referenceExt2',
      'transactionDate',
      'runId',
      'documentStandard'
    },
    'accountData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'transactionHandlingCode',
      'trxHandlingCodeExt',
      'checkAmount',
      'currencyCode',
      'currencyCodeExt',
      'EDIPaymentMethod',
      'EDIPaymentMethodExt',
      'EDIPaymentFormat',
      'EDIPaymentFormatExt',
      'bankBranchType',
      'bankBranchTypeExt',
      'bankAccountType',
      'bankAccountTypeExt',
      'bankAccountNumber',
      'bankEDIIDNumber',
      'vendorBankBranchType',
      'vendorBankBranchTypeExt',
      'vendorBankAccountType',
      'vendorBankAccountTypeExt',
      'vendorBankAccountNumber',
      'paymentDate',
      'accountHolderName',
      'EFTRequester'
    },
    'paymentData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'bankNumber',
      'vendorBankNumber',
      'EDIRemittanceMethod',
      'EDIRemittanceInstruction',
      'checkrunName',
      'checkVoucherNumber',
      'selectedCheckId',
      'checkNumber',
      'customerNumber',
      'voidFlag',
      'voidDate',
      'supplierBankBranchNumber',
      'supplierBankBranchSWIFTCode'
    },
    'supplierData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'vendorNumber',
      'vendorNumberExt',
      'vendorEDIIDNumber',
      'Segment2',
      'Segment3',
      'Segment4',
      'Segment5'
    },
    'bankData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'bankSiteCode',
      'bankSiteCodeExt',
      'bankName',
      'addressLine1',
      'addressLine2',
      'addressLine3',
      'addressLine4',
      'city',
      'postalCode',
      'country',
      'countryExt',
      'state',
      'stateExt',
      'province',
      'provinceExt'
    },
    'supplierSiteData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'vendorSiteCode',
      'vendorSiteCodeExt',
      'vendorName',
      'addressLine1',
      'addressLine2',
      'addressLine3',
      'addressLine4',
      'city',
      'postalCode',
      'country',
      'countryExt',
      'state',
      'stateExt',
      'province',
      'provinceExt'
    },
    'invoiceData' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'checkrunName',
      'vendorNumber',
      'vendorNumberExt',
      'customerNumber',
      'invoiceNumber',
      'invoiceDate',
      'invoiceDescription',
      'paymentAmount',
      'invoiceAmount',
      'discountAmount'
    },
    'invoiceFlexfields' => new List<String>{
      'tradingPartnerCode',
      'ref1Batch',
      'ref2Invoice',
      'ref3Blank',
      'recordNumber',
      'recordLayout',
      'recordLayoutQualifier',
      'attributeCategory',
      'attribute1',
      'attribute2',
      'attribute3',
      'attribute4',
      'attribute5'
    }
  };

  // Constant fields for records across batches and settlements.
  // If a field is an empty string here, it should always be blank.
  public static final Map<String, Map<String, String>> CONSTANT_FIELDS_BY_RECORD = new Map<String, Map<String, String>>{
    'controlRecord' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '0010',
      'recordLayout' => 'CT',
      'recordLayoutQualifier' => 'CTL',
      'communicationMethod' => 'ED',
      'testFlag' => 'T', // TODO: Figure out this test flag setup.
      'documentId' => 'PYO',
      'documentType' => '',
      'documentPurposeCode' => '',
      'locationCodeExt' => '',
      'description' => '',
      'referenceExt1' => '',
      'referenceExt2' => '',
      'documentStandard' => 'EDIFACT'
    },
    'accountData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1000',
      'recordLayout' => 'BK',
      'recordLayoutQualifier' => 'BK1',
      'transactionHandlingCode' => 'D',
      'trxHandlingCodeExt' => '',
      'currencyCodeExt' => '',
      'EDIPaymentMethodExt' => '',
      'EDIPaymentFormat' => '',
      'EDIPaymentFormatExt' => '',
      'bankBranchType' => '',
      'bankBranchTypeExt' => '',
      'bankAccountType' => '',
      'bankAccountTypeExt' => '',
      'vendorBankBranchType' => '',
      'vendorBankBranchTypeExt' => '',
      'vendorBankAccountType' => '',
      'vendorBankAccountTypeExt' => ''
    },
    'paymentData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1010',
      'recordLayout' => 'PY',
      'recordLayoutQualifier' => 'PAY',
      'bankNumber' => '',
      'vendorBankNumber' => '',
      'EDIRemittanceMethod' => 'EDI to payer\'s bank',
      'checkVoucherNumber' => '',
      'customerNumber' => '',
      'voidFlag' => '',
      'voidDate' => '',
      'supplierBankBranchSWIFTCode' => ''
    },
    'supplierData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1020',
      'recordLayout' => 'VN',
      'recordLayoutQualifier' => 'VN1',
      'vendorNumber' => '',
      'vendorNumberExt' => '',
      'vendorEDIIDNumber' => '',
      'Segment2' => '',
      'Segment3' => '',
      'Segment4' => '',
      'Segment5' => ''
    },
    'bankData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1030',
      'recordLayout' => 'AD',
      'recordLayoutQualifier' => 'BK1',
      'bankSiteCodeExt' => '',
      'bankName' => '',
      'countryExt' => '',
      'stateExt' => '',
      'provinceExt' => ''
    },
    'supplierSiteData' => new Map<String, String>{
      'ref2Invoice' => '',
      'ref3Blank' => '',
      'recordNumber' => '1050',
      'recordLayout' => 'AD',
      'recordLayoutQualifier' => 'VS1',
      'vendorSiteCodeExt' => '',
      'addressLine3' => '',
      'addressLine4' => '',
      'countryExt' => '',
      'state' => '',
      'stateExt' => '',
      'province' => '',
      'provinceExt' => ''
    },
    'invoiceData' => new Map<String, String>{
      'ref3Blank' => '',
      'recordNumber' => '2000',
      'recordLayout' => 'IV',
      'recordLayoutQualifier' => 'INV',
      'vendorNumber' => '',
      'vendorNumberExt' => '',
      'customerNumber' => '',
      'invoiceDescription' => '',
      'discountAmount' => '0'
    },
    'invoiceFlexfields' => new Map<String, String>{
      'ref3Blank' => '',
      'recordNumber' => '2010',
      'recordLayout' => 'A1',
      'recordLayoutQualifier' => 'RE1',
      'attributeCategory' => '',
      'attribute2' => '',
      'attribute3' => '',
      'attribute4' => '',
      'attribute5' => ''
    }
  };

  /*public static final Map<String, Map<String, String>> CURRENCY_DEPENDENT_FIELDS = new Map<String, Map<String, String>>{
    'SEK' => new Map<String, String>{
      'tradingPartnerCode' => 'SEB SE1',
      'translatorCode' => 'SEB SE1',
      'EDIPaymentMethod' => 'SAME DAY CL',
      'bankAccountNumber' => '55847529', // sas bank account number. These need to be named better
      'bankSiteCode' => '10272',
      'bankEDIIDNumber' => 'ESSESESS', // sas swift account number. These need to be named better
      'accountHolderName' => 'SAS CARE SEK', // sas account holder name. These need to be named better
      'EFTRequester' => '9020017720', // sas org. number. These need to be named better
      'addressLine1' => 'Norrmalmstorg 8', // sas banking address. These need to be named better
      'city' => 'Stockholm', // sas banking address. These need to be named better
      'postalCode' => '11000', // sas banking address. These need to be named better
      'country' => 'SE' // sas banking address. These need to be named better
    }
  };*/

  // Defines the order record lines should be in the payment file.
  public static final List<String> RECORDS_IN_ORDER = new List<String>{
    'controlRecord',
    'accountData',
    'paymentData',
    'supplierData',
    'bankData',
    'supplierSiteData',
    'invoiceData',
    'invoiceFlexfields'
  };

  public Map<String, Map<String, String>> data;
  public String paymentCurrency;

  // Constructor for individual payment records. These include only fields which are specific to this one settlement.
  // This means that no currency specific or fully constant fields are set by this point.
  // There's so much duplicate data so we're doing this to avoid blowing up the heap limit.
  public PaymentEntry(Settlement__c s) {
    String amount = String.valueOf(s.Amount__c); // TODO: Ensure that we get decimal points, not commas, out of here.

    this.paymentCurrency = s.Currency__c;

    Map<String, String> accountData = new Map<String, String>();
    accountData.put('checkAmount', amount);
    accountData.put('currencyCode', s.Currency__c);
    accountData.put('vendorBankAccountNumber', s.IBAN__c);

    Map<String, String> paymentData = new Map<String, String>();
    paymentData.put('checkrunName', s.Currency__c.substring(0, 2) + s.Name);
    paymentData.put('selectedCheckId', s.Name);
    paymentData.put('supplierBankBranchNumber', s.BIC_Swift__c);

    Map<String, String> supplierSiteData = new Map<String, String>();
    supplierSiteData.put('vendorSiteCode', s.Name);
    supplierSiteData.put('vendorName', s.Payee_Name__c);
    supplierSiteData.put('addressLine1', s.Address_line_1__c);
    supplierSiteData.put('addressLine2', s.Address_line_2__c);
    supplierSiteData.put('city', s.City__c);
    supplierSiteData.put('postalCode', s.Postal_Code__c);
    supplierSiteData.put('country', s.Country__c);

    Map<String, String> invoiceData = new Map<String, String>();
    invoiceData.put('ref2Invoice', 'SF REF ' + s.Name);
    invoiceData.put('checkrunName', s.Name);
    invoiceData.put('invoiceNumber', s.Name);
    invoiceData.put('paymentAmount', amount);
    invoiceData.put('invoiceAmount', amount);

    Map<String, String> invoiceFlexfields = new Map<String, String>();
    invoiceFlexfields.put('ref2Invoice', 'SF REF ' + s.Name);
    invoiceFlexfields.put('attribute1', 'derp'); // TODO: This needs to be still figured out.

    // accountData.put('',);

    Map<String, Map<String, String>> tempMap = new Map<String, Map<String, String>>();
    tempMap.put('controlRecord', new Map<String, String>());
    tempMap.put('accountData', accountData);
    tempMap.put('paymentData', paymentData);
    tempMap.put('supplierData', new Map<String, String>());
    tempMap.put('bankData', new Map<String, String>());
    tempMap.put('supplierSiteData', supplierSiteData);
    tempMap.put('invoiceData', invoiceData);
    tempMap.put('invoiceFlexfields', invoiceFlexfields);

    this.data = tempMap;
  }
}
