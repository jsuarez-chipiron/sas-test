public class AccountingEntry {
  private static final String TODAYS_DATE = Datetime.now().format('yyyyMMdd');
  private static final String TODAYS_PERIOD = Datetime.now().format('yyMM');

  // Defines the field lengths in columns for all fields in all records.
  public static final Map<String, Integer> FIELD_LENGTHS = new Map<String, Integer>{
    'RecordIdentifier' => 3,
    'AUN' => 2,
    'VerificationNumber' => 6,
    'ConversionDate' => 8,
    'NaturalAccount' => 4,
    'CostCenter' => 5,
    'ReconciliationReference' => 10,
    'Product' => 6,
    'Counterpart' => 7,
    'Misc1' => 6,
    'Misc2' => 6,
    'Currency' => 3,
    'DebitOrCredit' => 1,
    'Amount' => 15,
    'Description' => 24,
    'CompanyCode' => 3,
    'Period' => 4,
    'FeederName' => 5,
    'DeliveryNumber' => 2
  };

  public static final Map<String, String> CONSTANT_FIELDS_FOR_DEBITS = new Map<String, String>{
    'RecordIdentifier' => 'RAC',
    'AUN' => '01',
    'CostCenter' => '90801',
    'DebitOrCredit' => 'C',
    'CompanyCode' => 'SK',
    'Period' => TODAYS_PERIOD,
    'FeederName' => 'SF',
    'DeliveryNumber' => '01'
  };

  public static final Map<String, String> CONSTANT_FIELDS_FOR_CREDITS = new Map<String, String>{
    'RecordIdentifier' => 'RAC',
    'AUN' => '01',
    'ReconciliationReference' => 'CARE2111',
    'DebitOrCredit' => 'D',
    'Description' => 'Balance post for debits',
    'CompanyCode' => 'SK',
    'Period' => TODAYS_PERIOD,
    'FeederName' => 'SF',
    'DeliveryNumber' => '01'
  };

  public static final Map<String, String> CREDIT_COST_CENTERS_BY_CURRENCY = new Map<String, String>{
    'DKK' => '90802',
    'NOK' => '69851',
    'SEK' => '90801',
    'OTH' => '90890'
  };

  public static final List<String> FIELDS_IN_ORDER = new List<String>{
    'RecordIdentifier',
    'AUN',
    'VerificationNumber',
    'ConversionDate',
    'NaturalAccount',
    'CostCenter',
    'ReconciliationReference',
    'Product',
    'Counterpart',
    'Misc1',
    'Misc2',
    'Currency',
    'DebitOrCredit',
    'Amount',
    'Description',
    'CompanyCode',
    'Period',
    'FeederName',
    'DeliveryNumber'
  };

  public Map<String, String> data;
  public Integer amount;

  public AccountingEntry(Settlement_Item__c settlementItem) {
    Integer amountInCents = (settlementItem.Amount__c * 100).intValue();
    amount = amountInCents;
    this.data = new Map<String, String>{
      'ConversionDate' => (Datetime.newInstanceGmt(
          settlementItem.Settlement__r.Date_of_Exchange_Calculation__c,
          Time.newInstance(0, 0, 0, 0)
        ))
        .format('yyyyMMdd'),
      'NaturalAccount' => settlementItem.Cost_Account__c,
      'ReconciliationReference' => settlementItem.Name,
      'Product' => '',
      'Counterpart' => '',
      'Misc1' => '',
      'Misc2' => '',
      'Currency' => settlementItem.Currency__c,
      'DebitOrCredit' => 'C',
      'Amount' => String.valueOf(amountInCents),
      'Description' => ''
    };
  }
}