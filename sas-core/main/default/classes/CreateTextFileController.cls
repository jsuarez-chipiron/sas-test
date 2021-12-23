public class CreateTextFileController {
  public CreateTextFileController() {
  }

  public String createTextFile(List<PrePayMul> prePayList) {
    String Cr;
    PrePayMul.GenericFields ctrGenFields = prePayList[0].ctrlRecord.genFields;
    PrePayMul.GenericFields adGenFields = prePayList[0].accData.genFields;
    PrePayMul.GenericFields pdGenFields = prePayList[0].payData.genFields;
    PrePayMul.GenericFields sdGenFields = prePayList[0].suplData.genFields;
    PrePayMul.GenericFields bdGenFields = prePayList[0].bnData.genFields;
    PrePayMul.GenericFields ssdGenFields = prePayList[0].supSiteData.genFields;
    PrePayMul.GenericFields idGenFields = prePayList[0].incData.genFields;
    PrePayMul.GenericFields iffGenFields = prePayList[0].incFleFields.genFields;
    System.debug('listSize' + prePayList.size());

    for (Integer j = 0; j < prePayList.size(); j++) {
      PrePayMul pp = prePayList[j];
      PrePayMul.ControlRecord ctr = pp.ctrlRecord;
      PrePayMul.AccountData ad = pp.accData;
      PrePayMul.PaymentData pd = pp.payData;
      PrePayMul.SupplierData sd = pp.suplData;
      PrePayMul.BankData bd = pp.bnData;
      PrePayMul.SupplierSiteData ssd = pp.supSiteData;
      PrePayMul.InvoiceData id = pp.incData;
      PrePayMul.InvoiceFlexFields iff = pp.incFleFields;

      if (ctr != null) {
        if (j == 0) {
          cr = constructField(
            getGeneriConstFieldValue(
              'ControlRecord',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        } else {
          cr =
            cr +
            constructField(
              getGeneriConstFieldValue(
                'ControlRecord',
                pp.currencyType,
                'tradingPartnerCode'
              ),
              getFieldLength('tradingPartnerCode')
            );
        }
        cr = cr + constructField(ctr.ref1Batch, getFieldLength('ref1Batch'));
        cr =
          cr + constructField(ctr.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(ctr.ref3Blank, getFieldLength('ref3Blank'));
        cr =
          cr +
          constructField(
            ctrGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            ctrGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            ctrGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr +
          constructField(
            System.Label.communicationMethod,
            getFieldLength('communicationMethod')
          );
        cr =
          cr +
          constructField(System.Label.testFlag, getFieldLength('testFlag'));
        cr =
          cr +
          constructField(System.Label.documentId, getFieldLength('documentId'));
        cr =
          cr + constructField(ctr.documentType, getFieldLength('documentType'));

        cr =
          cr +
          constructField(
            ctr.documentpurposeCode,
            getFieldLength('documentpurposeCode')
          );
        cr =
          cr + constructField(ctr.documentCode, getFieldLength('documentCode'));

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'ControlRecord',
              pp.currencyType,
              'translatorCode'
            ),
            getFieldLength('translatorCode')
          );

        cr =
          cr +
          constructField(
            ctr.locationCodeText,
            getFieldLength('locationCodeText')
          );

        cr =
          cr + constructField(ctr.description, getFieldLength('description'));
        cr =
          cr +
          constructField(ctr.referenceExt1, getFieldLength('referenceExt1'));
        cr =
          cr +
          constructField(ctr.referenceExt2, getFieldLength('referenceExt2'));

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'ControlRecord',
              pp.currencyType,
              'transactionDate'
            ),
            getFieldLength('transactionDate')
          );

        cr = cr + constructField(ctr.runId, getFieldLength('runId'));
        cr =
          cr +
          constructField(
            System.Label.documentStandard,
            getFieldLength('documentStandard')
          ) +
          '\n';
      }
      if (ad != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'AccountData',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(ad.ref1Batch, getFieldLength('ref1Batch'));
        cr = cr + constructField(ad.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(ad.ref3Blank, getFieldLength('ref3Blank'));
        cr =
          cr +
          constructField(
            adGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            adGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            adGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr +
          constructField(
            System.Label.transactionHandlingCode,
            getFieldLength('transactionHandlingCode')
          );
        cr =
          cr +
          constructField(
            ad.trxHandlingCodeExt,
            getFieldLength('trxHandlingCodeExt')
          );
        cr = cr + constructField(ad.checkAmount, getFieldLength('checkAmount'));
        cr =
          cr + constructField(ad.currencyCode, getFieldLength('currencyCode'));
        cr =
          cr +
          constructField(ad.currencyCodeExt, getFieldLength('currencyCodeExt'));

        cr =
          cr +
          constructField(
            ad.ediPaymentMethod,
            getFieldLength('ediPaymentMethod')
          );
        cr =
          cr +
          constructField(
            ad.ediPaymentMethodExt,
            getFieldLength('ediPaymentMethodExt')
          );
        cr =
          cr +
          constructField(
            ad.ediPaymentFormat,
            getFieldLength('ediPaymentFormat')
          );
        cr =
          cr +
          constructField(
            ad.ediPaymentFormatExt,
            getFieldLength('ediPaymentFormatExt')
          );

        cr =
          cr +
          constructField(ad.bankBranchType, getFieldLength('bankBranchType'));
        cr =
          cr +
          constructField(
            ad.bankBranchTypeExt,
            getFieldLength('bankBranchTypeExt')
          );
        cr =
          cr +
          constructField(ad.bankAccountType, getFieldLength('bankAccountType'));
        cr =
          cr +
          constructField(
            ad.bankAccountTypeExt,
            getFieldLength('bankAccountTypeExt')
          );

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'AccountData',
              pp.currencyType,
              'bankAccountNumber'
            ),
            getFieldLength('bankAccountNumber')
          );
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'AccountData',
              pp.currencyType,
              'bankEdiIdNumber'
            ),
            getFieldLength('bankEdiIdNumber')
          );

        cr =
          cr +
          constructField(
            ad.vendorBankBranchType,
            getFieldLength('vendorBankBranchType')
          );
        cr =
          cr +
          constructField(
            ad.vendorBankBranchTypeExt,
            getFieldLength('vendorBankBranchTypeExt')
          );
        cr =
          cr +
          constructField(
            ad.vendorBankAccountType,
            getFieldLength('vendorBankAccountType')
          );
        cr =
          cr +
          constructField(
            ad.vendorBankAccountTypeExt,
            getFieldLength('vendorBankAccountTypeExt')
          );
        cr =
          cr +
          constructField(
            ad.vendorBankAccountNumber,
            getFieldLength('vendorBankAccountNumber')
          );

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'AccountData',
              pp.currencyType,
              'paymentDate'
            ),
            getFieldLength('paymentDate')
          );
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'AccountData',
              pp.currencyType,
              'accountHolderName'
            ),
            getFieldLength('accountHolderName')
          );

        cr =
          cr +
          constructField(ad.eftRequester, getFieldLength('eftRequester')) +
          '\n';
      }
      if (pd != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'PaymentData',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(pd.ref1Batch, getFieldLength('ref1Batch'));
        cr = cr + constructField(pd.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(pd.ref3Blank, getFieldLength('ref3Blank'));

        cr =
          cr +
          constructField(
            pdGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            pdGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            pdGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr = cr + constructField(pd.bankNumber, getFieldLength('bankNumber'));
        cr =
          cr +
          constructField(
            pd.vendorBankNumber,
            getFieldLength('vendorBankNumber')
          );
        cr =
          cr +
          constructField(
            pd.ediRemittanceMethod,
            getFieldLength('ediRemittanceMethod')
          );
        cr =
          cr +
          constructField(
            pd.ediRemittanceInstruction,
            getFieldLength('ediRemittanceInstruction')
          );
        cr =
          cr + constructField(pd.checkRunName, getFieldLength('checkRunName'));

        cr =
          cr +
          constructField(
            pd.checkVoucherNumber,
            getFieldLength('checkVoucherNumber')
          );
        cr =
          cr +
          constructField(pd.SelectedCheckId, getFieldLength('SelectedCheckId'));
        cr = cr + constructField(pd.checkNumber, getFieldLength('checkNumber'));
        cr =
          cr +
          constructField(pd.customerNumber, getFieldLength('customerNumber'));

        cr = cr + constructField(pd.voidFlag, getFieldLength('voidFlag'));
        cr = cr + constructField(pd.voidDate, getFieldLength('voidDate'));
        cr =
          cr +
          constructField(
            pd.supplierBankBranchNumber,
            getFieldLength('supplierBankBranchNumber')
          );
        cr =
          cr +
          constructField(
            pd.SupplierBankBranchSwiftCode,
            getFieldLength('SupplierBankBranchSwiftCode')
          ) +
          '\n';
      }
      if (sd != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'SupplierData',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(sd.ref1Batch, getFieldLength('ref1Batch'));
        cr = cr + constructField(sd.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(sd.ref3Blank, getFieldLength('ref3Blank'));

        cr =
          cr +
          constructField(
            sdGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            sdGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            sdGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr + constructField(sd.vendorNumber, getFieldLength('vendorNumber'));
        cr =
          cr +
          constructField(sd.vendorNumberExt, getFieldLength('vendorNumberExt'));
        cr =
          cr +
          constructField(
            sd.vendorEdiIdNumber,
            getFieldLength('vendorEdiIdNumber')
          );
        cr = cr + constructField(sd.segment2, getFieldLength('segment2'));
        cr = cr + constructField(sd.segment3, getFieldLength('segment3'));
        cr = cr + constructField(sd.segment4, getFieldLength('segment4'));
        cr =
          cr +
          constructField(sd.segment5, getFieldLength('segment5')) +
          '\n';
      }
      if (bd != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'BankData',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(bd.ref1Batch, getFieldLength('ref1Batch'));
        cr = cr + constructField(bd.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(bd.ref3Blank, getFieldLength('ref3Blank'));

        cr =
          cr +
          constructField(
            bdGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            bdGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            bdGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'BankData',
              pp.currencyType,
              'bankSiteCode'
            ),
            getFieldLength('bankSiteCode')
          );

        cr =
          cr +
          constructField(bd.bankSiteCodeExt, getFieldLength('bankSiteCodeExt'));
        cr = cr + constructField(bd.bankName, getFieldLength('bankName'));

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'BankData',
              pp.currencyType,
              'addressLine1'
            ),
            getFieldLength('addressLine1')
          );
        cr =
          cr + constructField(bd.addressLine2, getFieldLength('addressLine2'));
        cr =
          cr + constructField(bd.addressLine3, getFieldLength('addressLine3'));
        cr =
          cr + constructField(bd.addressLine4, getFieldLength('addressLine4'));

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue('BankData', pp.currencyType, 'city'),
            getFieldLength('city')
          );
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue('BankData', pp.currencyType, 'postalCode'),
            getFieldLength('postalCode')
          );

        cr = cr + constructField(bd.country, getFieldLength('country'));
        cr = cr + constructField(bd.countryExt, getFieldLength('countryExt'));

        cr = cr + constructField(bd.state, getFieldLength('state'));
        cr = cr + constructField(bd.stateExt, getFieldLength('stateExt'));
        cr = cr + constructField(bd.province, getFieldLength('province'));
        cr =
          cr +
          constructField(bd.provinceExt, getFieldLength('provinceExt')) +
          '\n';
      }
      if (ssd != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'SupplierSiteData',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(ssd.ref1Batch, getFieldLength('ref1Batch'));
        cr =
          cr + constructField(ssd.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(ssd.ref3Blank, getFieldLength('ref3Blank'));

        cr =
          cr +
          constructField(
            ssdGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            ssdGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            ssdGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr +
          constructField(ssd.vendorSiteCode, getFieldLength('vendorSiteCode'));
        cr =
          cr +
          constructField(
            ssd.vendorSiteCodeExt,
            getFieldLength('vendorSiteCodeExt')
          );
        cr = cr + constructField(ssd.vendorName, getFieldLength('vendorName'));

        cr =
          cr + constructField(ssd.addressLine1, getFieldLength('addressLine1'));
        cr =
          cr + constructField(ssd.addressLine2, getFieldLength('addressLine2'));
        cr =
          cr + constructField(ssd.addressLine3, getFieldLength('addressLine3'));
        cr =
          cr + constructField(ssd.addressLine4, getFieldLength('addressLine4'));

        cr = cr + constructField(ssd.city, getFieldLength('city'));
        cr = cr + constructField(ssd.postalCode, getFieldLength('postalCode'));
        cr = cr + constructField(ssd.country, getFieldLength('country'));
        cr = cr + constructField(ssd.countryExt, getFieldLength('countryExt'));

        cr = cr + constructField(ssd.state, getFieldLength('state'));
        cr = cr + constructField(ssd.stateExt, getFieldLength('stateExt'));
        cr = cr + constructField(ssd.province, getFieldLength('province'));
        cr =
          cr +
          constructField(ssd.provinceExt, getFieldLength('provinceExt')) +
          '\n';
      }
      if (id != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'InvoiceData',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(id.ref1Batch, getFieldLength('ref1Batch'));
        cr = cr + constructField(id.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(id.ref3Blank, getFieldLength('ref3Blank'));

        cr =
          cr +
          constructField(
            idGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            idGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            idGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr + constructField(id.checkRunName, getFieldLength('checkRunName'));
        cr =
          cr + constructField(id.vendorNumber, getFieldLength('vendorNumber'));
        cr =
          cr +
          constructField(
            id.invoiceVendorNumberExt,
            getFieldLength('invoiceVendorNumberExt')
          );
        cr =
          cr +
          constructField(id.customerNumber, getFieldLength('customerNumber'));
        cr =
          cr +
          constructField(id.invoiceNumber, getFieldLength('invoiceNumber'));

        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'InvoiceData',
              pp.currencyType,
              'invoiceDate'
            ),
            getFieldLength('invoiceDate')
          );

        cr =
          cr +
          constructField(
            id.invoiceDescription,
            getFieldLength('invoiceDescription')
          );
        cr =
          cr +
          constructField(id.paymentAmount, getFieldLength('paymentAmount'));
        cr =
          cr +
          constructField(id.invoiceAmount, getFieldLength('invoiceAmount'));
        cr =
          cr +
          constructField(id.discountAmount, getFieldLength('discountAmount')) +
          '\n';
      }
      if (iff != null) {
        cr =
          cr +
          constructField(
            getGeneriConstFieldValue(
              'InvoiceFlexFields',
              pp.currencyType,
              'tradingPartnerCode'
            ),
            getFieldLength('tradingPartnerCode')
          );
        cr = cr + constructField(iff.ref1Batch, getFieldLength('ref1Batch'));
        cr =
          cr + constructField(iff.ref2Invoice, getFieldLength('ref2Invoice'));
        cr = cr + constructField(iff.ref3Blank, getFieldLength('ref3Blank'));

        cr =
          cr +
          constructField(
            iffGenFields.recordNumber,
            getFieldLength('recordNumber')
          );
        cr =
          cr +
          constructField(
            iffGenFields.recordLayout,
            getFieldLength('recordLayout')
          );
        cr =
          cr +
          constructField(
            iffGenFields.recordLayoutQualifier,
            getFieldLength('recordLayoutQualifier')
          );

        cr =
          cr +
          constructField(
            iff.attributeCategory,
            getFieldLength('attributeCategory')
          );
        cr = cr + constructField(iff.attribute1, getFieldLength('attribute1'));
        cr = cr + constructField(iff.attribute2, getFieldLength('attribute2'));
        cr = cr + constructField(iff.attribute3, getFieldLength('attribute3'));
        cr = cr + constructField(iff.attribute4, getFieldLength('attribute4'));
        cr = cr + constructField(iff.attribute5, getFieldLength('attribute5'));

        if (prePayList.size() > j + 1) {
          cr = cr + '\n';
        }
      }
    }
    System.debug('========== Heap Size :: ' + Limits.getHeapSize());
    return cr;
  }
  public string constructField(String value, Integer maxChar) {
    String formattedField = value.rightPad(maxChar);
    return formattedField;
  }

  public Integer getFieldLength(String fieldName) {
    PrePayFieldsCharLength__mdt prePayField = PrePayFieldsCharLength__mdt.getInstance(
      fieldName
    );
    return prePayField.FieldLength__c.intValue();
  }
  public string getGeneriConstFieldValue(
    String recordName,
    String currencyType,
    String fieldName
  ) {
    PrePayGenericConstantField__mdt prePayGenField = PrePayGenericConstantField__mdt.getInstance(
      recordName +
      currencyType +
      fieldName
    );
    return prePayGenField.Value__c;
  }
}
