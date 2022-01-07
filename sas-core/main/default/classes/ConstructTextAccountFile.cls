/**
@author Thippeswamy Aravinda
Date : Dec-23-2021
*/
public class ConstructTextAccountFile {
  public static String constructAccountFile(
    List<AccountFile> accFiles,
    String currencyType
  ) {
    string accfle;
    for (Integer i = 0; i < accFiles.size(); i++) {
      AccountFile accfile = accFiles[i];
      if (i == 0) {
        accfle = constructField(
          getRacerConstFieldValue(currencyType, 'acc_RecordIdentifier'),
          getFieldLength('acc_RecordIdentifier')
        );
      } else {
        accfle =
          accfle +
          constructField(
            getRacerConstFieldValue(currencyType, 'acc_RecordIdentifier'),
            getFieldLength('acc_RecordIdentifier')
          );
      }
      accfle =
        accfle +
        constructField(
          getRacerConstFieldValue(currencyType, 'acc_Aun'),
          getFieldLength('acc_Aun')
        );
      accfle =
        accfle +
        constructField('973270', getFieldLength('acc_VerificationNumber'));
      accfle =
        accfle +
        constructField(
          getYear(accfile.acc_ConversationDate) +
          getMonth(accfile.acc_ConversationDate) +
          getDayOfMonth(accfile.acc_ConversationDate),
          getFieldLength('acc_ConversationDate')
        );
      accfle =
        accfle +
        constructField(
          accfile.acc_NaturalAccount,
          getFieldLength('acc_NaturalAccount')
        );
      accfle =
        accfle +
        constructField(
          getRacerConstFieldValue(currencyType, 'acc_Center'),
          getFieldLength('acc_Center')
        );
      accfle =
        accfle +
        constructField(
          accfile.acc_ReconciliationReference,
          getFieldLength('acc_ReconciliationReference')
        );
      accfle = accfle + constructField('', getFieldLength('acc_Product'));
      accfle = accfle + constructField('', getFieldLength('acc_CounterPart'));
      accfle = accfle + constructField('', getFieldLength('acc_Misc1'));
      accfle = accfle + constructField('', getFieldLength('acc_Misc2'));
      accfle =
        accfle +
        constructField(
          accfile.acc_EntCurrency,
          getFieldLength('acc_EntCurrency')
        );
      accfle =
        accfle + constructField('D', getFieldLength('acc_DebitOrcredit'));
      accfle =
        accfle +
        constructField(accfile.acc_Amount, getFieldLength('acc_Amount'));
      accfle = accfle + constructField('', getFieldLength('acc_Description'));
      accfle =
        accfle +
        constructField(
          getRacerConstFieldValue(currencyType, 'acc_CompanyCode'),
          getFieldLength('acc_CompanyCode')
        );
      accfle =
        accfle +
        constructField(
          getYear(Date.today()).right(2) + getDayOfMonth(Date.today()),
          getFieldLength('acc_Period')
        );
      accfle =
        accfle +
        constructField(
          getRacerConstFieldValue(currencyType, 'acc_FeederName'),
          getFieldLength('acc_FeederName')
        );
      accfle =
        accfle +
        constructField(
          getRacerConstFieldValue(currencyType, 'acc_DelivNo'),
          getFieldLength('acc_DelivNo')
        );

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
  public static string getRacerConstFieldValue(
    String currencyType,
    String fieldName
  ) {
    RacerTextFileConstant__mdt racerTextFileConst = RacerTextFileConstant__mdt.getInstance(
      currencyType +
      '_' +
      fieldName
    );
    return racerTextFileConst.Value__c;
  }

  public static string getDayOfMonth(Date dte) {
    String day = String.valueOf(dte.day());
    if (day.length() == 1)
      day = '0' + day;
    return day;
  }
  public static string getYear(Date dte) {
    String year = String.valueOf(dte.year());
    return year;
  }
  public static string getMonth(Date dte) {
    String month = String.valueOf(dte.Month());
    if (month.length() == 1)
      month = '0' + month;
    return month;
  }
}
