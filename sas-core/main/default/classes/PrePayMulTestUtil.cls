public class PrePayMulTestUtil {
  public static PrePayMul createTestData() {
    prePayMul.GenericFields ctrGenFields = new prePayMul.GenericFields(
      '0010',
      'CT',
      'CTL'
    );
    PrePayMul.ControlRecord ctrRecord = new PrePayMul.ControlRecord(
      '5001',
      '',
      '',
      '',
      '',
      '5001',
      '',
      '',
      '',
      '',
      '701433',
      ctrGenFields
    );

    prePayMul.GenericFields accGenFields = new prePayMul.GenericFields(
      '1000',
      'BK',
      'BK1'
    );
    PrePayMul.AccountData accData = new PrePayMul.AccountData(
      '5001',
      '',
      '',
      '',
      '170.31',
      'USD',
      '',
      'NORDEA US DOM EDI',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '000000000000000000000000',
      '9020017720',
      accGenFields
    );

    prePayMul.GenericFields payGenFields = new prePayMul.GenericFields(
      '1010',
      'PY',
      'PAY'
    );

    PrePayMul.PaymentData payData = new PrePayMul.PaymentData(
      '5001',
      '',
      '',
      '',
      '',
      'EDI to payerss bank',
      '15',
      'US 78444438',
      '',
      '78444438',
      '5001',
      '',
      '',
      '',
      'CustSwift',
      '',
      payGenFields
    );

    prePayMul.GenericFields supGenFields = new prePayMul.GenericFields(
      '1020',
      'VN',
      'VN1'
    );

    PrePayMul.SupplierData suplData = new PrePayMul.SupplierData(
      '5001',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      supGenFields
    );

    prePayMul.GenericFields bnGenFields = new prePayMul.GenericFields(
      '1030',
      'AD',
      'BK1'
    );

    PrePayMul.BankData bnData = new PrePayMul.BankData(
      '5001',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'SE',
      '',
      '',
      '',
      '',
      '',
      bnGenFields
    );
    prePayMul.GenericFields SupSiteGenFields = new prePayMul.GenericFields(
      '1050',
      'AD',
      'VS1'
    );
    PrePayMul.SupplierSiteData SupSiteData = new PrePayMul.SupplierSiteData(
      '5001',
      '',
      '',
      '78444438',
      '',
      'Customer Name1',
      '',
      'Customer Address Line 2',
      '',
      '',
      'CustomerCity',
      'ZIP0',
      '',
      'NO',
      '',
      '',
      '',
      '',
      SupSiteGenFields
    );

    prePayMul.GenericFields incGenFields = new prePayMul.GenericFields(
      '2000',
      'IV',
      'INV'
    );
    PrePayMul.InvoiceData incData = new PrePayMul.InvoiceData(
      '5001',
      'CARE REF 78444438',
      '',
      '78444438',
      '',
      '',
      '',
      'SAS2065306',
      '',
      '170.31',
      '170.31',
      '0',
      incGenFields
    );
    prePayMul.GenericFields incFleGenFields = new prePayMul.GenericFields(
      '2010',
      'A1',
      'RE1'
    );
    PrePayMul.InvoiceFlexFields incFleFields = new PrePayMul.InvoiceFlexFields(
      '5001',
      'CARE REF 78444438',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      incFleGenFields
    );
    PrePayMul prePal = new PrePayMul(
      ctrRecord,
      accData,
      payData,
      suplData,
      bnData,
      supSiteData,
      incData,
      incFleFields,
      'USD'
    );
    return prePal;
  }
}
