/**
@author Thippeswamy Aravinda
Date : Dec-23-2021
*/
public class ConstructTextAccountFile {
  public static String constructAccountFile(List<AccountFile> accFiles) {
    string accfle;
    for (Integer i = 0; i < accFiles.size(); i++) {
      AccountFile accfile = accFiles[i];
      if (i == 0) {
        accfle = constructField(
          accfile.acc_RecordIdentifier,
          getFieldLength('acc_RecordIdentifier')
        );
      } else {
        accfle =
          accfle +
          constructField(
            accfile.acc_RecordIdentifier,
            getFieldLength('acc_RecordIdentifier')
          );
      }
      accfle =
        accfle + constructField(accfile.acc_Aun, getFieldLength('acc_Aun'));
      accfle =
        accfle +
        constructField(
          accfile.acc_VerificationNumber,
          getFieldLength('acc_VerificationNumber')
        );
      accfle =
        accfle +
        constructField(
          accfile.acc_ConcersationDate,
          getFieldLength('acc_ConcersationDate')
        );
      accfle =
        accfle +
        constructField(
          accfile.acc_NeutralAccount,
          getFieldLength('acc_NeutralAccount')
        );
      accfle =
        accfle +
        constructField(accfile.acc_Center, getFieldLength('acc_Center'));
      accfle =
        accfle +
        constructField(
          accfile.acc_ReconciliationReference,
          getFieldLength('acc_ReconciliationReference')
        );
      accfle =
        accfle +
        constructField(accfile.acc_Product, getFieldLength('acc_Product'));
      accfle =
        accfle +
        constructField(
          accfile.acc_CounterPart,
          getFieldLength('acc_CounterPart')
        );
      accfle =
        accfle + constructField(accfile.acc_Misc1, getFieldLength('acc_Misc1'));
      accfle =
        accfle + constructField(accfile.acc_Misc2, getFieldLength('acc_Misc2'));
      accfle =
        accfle +
        constructField(
          accfile.acc_EntCurrency,
          getFieldLength('acc_EntCurrency')
        );
      accfle =
        accfle +
        constructField(
          accfile.acc_DebitOrcredit,
          getFieldLength('acc_DebitOrcredit')
        );
      accfle =
        accfle +
        constructField(accfile.acc_Amount, getFieldLength('acc_Amount'));
      accfle =
        accfle +
        constructField(
          accfile.acc_Description,
          getFieldLength('acc_Description')
        );
      accfle =
        accfle +
        constructField(
          accfile.acc_CompanyCode,
          getFieldLength('acc_CompanyCode')
        );
      accfle =
        accfle +
        constructField(accfile.acc_Period, getFieldLength('acc_Period'));
      accfle =
        accfle +
        constructField(
          accfile.acc_FeederName,
          getFieldLength('acc_FeederName')
        );
      accfle =
        accfle +
        constructField(accfile.acc_DelivNo, getFieldLength('acc_DelivNo'));

      if (accFiles.size() > i + 1) {
        accfle = accfle + '\n';
      }
    }
    return accfle;
  }
  public static Integer getFieldLength(String fieldName) {
    TextFileFieldsCharLength__mdt prePayField = TextFileFieldsCharLength__mdt.getInstance(
      fieldName
    );
    return prePayField.FieldLength__c.intValue();
  }
  public static string constructField(String value, Integer maxChar) {
    String formattedField = value.rightPad(maxChar);
    return formattedField;
  }
}
