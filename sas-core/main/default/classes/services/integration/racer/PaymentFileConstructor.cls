/**
 * This file defines methods for creating payment files, given a list of
 * PaymentEntries made from Settlement objects. The created files are
 * sent further to RACER to execute the payments. See Confluence for more
 * details.
 *
 * There are 8 records for every payment:
 * 1. Control record
 * 2. Account data
 * 3. Payment data
 * 4. Supplier data
 * 5. Bank data
 * 6. Supplier site data
 * 7. Invoice data
 * 8. Invoice flex fields
 *
 * Each of these records is it's own row in the text file. This means that
 * there are in total eight lines per settlement in the final file.
 *
 * We have also four sources for the different fields in the records:
 * 1. The settlement itself
 * 2. Constant values defined in the PaymentEntry class.
 * 3. Currency specific values defined in Settlement_Currency_Setting__mdt records.
 * 4. Counters and dates specified for a given file in this class.
 *
 * A given field should never appear in more than one source, so we simply
 * merge all of the fields together to create a full data source for a given
 * payment.
 *
 * The full list of all fields and their lengths in columns are given in
 * the PaymentEntry class.
 */
public class PaymentFileConstructor {
  public class CreateFileException extends Exception {
  }

  private static final String TODAYS_DATE = Datetime.now().format('yyyyMMdd');

  private static final Map<String, Map<String, String>> FILE_SPECIFIC_FIELDS = new Map<String, Map<String, String>>{
    'controlRecord' => new Map<String, String>{
      'transactionDate' => TODAYS_DATE,
      'runId' => '1234' // ??? TODO: FIX ME
    },
    'accountData' => new Map<String, String>{ 'paymentDate' => TODAYS_DATE },
    'paymentData' => new Map<String, String>(),
    'supplierData' => new Map<String, String>(),
    'bankData' => new Map<String, String>(),
    'supplierSiteData' => new Map<String, String>(),
    'invoiceData' => new Map<String, String>{ 'invoiceDate' => TODAYS_DATE },
    'invoiceFlexfields' => new Map<String, String>()
  };

  public enum PaymentCurrency {
    SEK,
    DKK,
    USD,
    NOK,
    OTH
  }

  /**
   * Creates a payment file based on the given PaymentEntries.
   * The file is created as a ContentVersion object.
   *
   * @param paymentEntries List of PaymentEntries created from Settlements to include in this file.
   * @param fileCurrency The currency of this file as PaymentCurrency.
   *
   *
   * @return Id of the created a file.
   */
  public static Id create(
    List<PaymentEntry> paymentEntries,
    PaymentCurrency fileCurrency
  ) {
    Map<String, Map<String, String>> currencySetting = fetchCurrencySettings(
      fileCurrency
    );

    if (
      fileCurrency == null ||
      paymentEntries == null ||
      paymentEntries.isEmpty()
    ) {
      throw new CreateFileException(
        'PaymentFileConstructor.create# Missing parameters'
      );
    }

    String fileContents = '';

    // Each settlement in a file has a unique batch reference. The starting
    // number for the batch reference depends on the file's currency.
    Integer batchReference = Integer.valueOf(
      currencySetting.get('controlRecord').get('ref1Batch')
    );

    for (PaymentEntry entry : paymentEntries) {
      Map<String, Map<String, String>> mergedRecord = new Map<String, Map<String, String>>();
      // Merge all four data sources into a single map
      for (String key : PaymentEntry.RECORDS_IN_ORDER) {
        mergedRecord.put(key, entry.data.get(key));
        mergedRecord.get(key)
          .putAll(PaymentEntry.CONSTANT_FIELDS_BY_RECORD.get(key));
        mergedRecord.get(key).putAll(FILE_SPECIFIC_FIELDS.get(key));
        mergedRecord.get(key).putAll(currencySetting.get(key));
      }

      for (String recordName : PaymentEntry.RECORDS_IN_ORDER) {
        for (
          String fieldName : PaymentEntry.FIELDS_IN_ORDER_BY_RECORD.get(
            recordName
          )
        ) {
          String textToAdd = '';

          if (
            fieldName == 'ref1Batch' ||
            fieldName == 'documentCode' ||
            fieldName == 'checkNumber'
          ) {
            // All these fields should contain just the batch reference.
            textToAdd = String.valueOf(batchReference);
          } else {
            textToAdd += mergedRecord.get(recordName).get(fieldName) != null
              ? mergedRecord.get(recordName).get(fieldName)
              : '';
          }

          // Pad field to full field length.
          fileContents += textToAdd.rightPad(
            PaymentEntry.FIELD_LENGTHS.get(recordName).get(fieldName)
          );
        }
        // Each record is a single line so we'll add a linebreak at the end.
        fileContents += '\n';
      }
      // Each settlement has it's own batch reference.
      batchReference++;
    }

    Settlement_Currency_Setting__mdt currencySettingMDT = Settlement_Currency_Setting__mdt.getall()
      .get(fileCurrency.name());

    String bank = currencySettingMDT.Bank__c != null
      ? currencySettingMDT.Bank__c
      : 'SEB';

    String fileName =
      'SF' +
      '_' +
      bank +
      '_' +
      fileCurrency.name() +
      '_' +
      TODAYS_DATE; // TODO: This isn't the same as the files we have.

    ContentVersion paymentFile = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = fileName + '.txt',
      Title = fileName,
      VersionData = Blob.valueOf(fileContents)
    );
    insert paymentFile;

    return paymentFile.Id;
  }

  /**
   * Fetches currency specific fields from custom metadata and populates
   * them into a map with same format as PaymentEntries.
   *
   * @param fileCurrency The currency for which settings should be fetched.
   *
   * @return A map of records with filled currency specific fields.
   */
  private static Map<String, Map<String, String>> fetchCurrencySettings(
    PaymentCurrency fileCurrency
  ) {
    Settlement_Currency_Setting__mdt currencySettingMDT = Settlement_Currency_Setting__mdt.getall()
      .get(fileCurrency.name());

    Map<String, Map<String, String>> currencySettings = new Map<String, Map<String, String>>{
      'controlRecord' => new Map<String, String>(),
      'accountData' => new Map<String, String>{
        'EDIPaymentMethod' => currencySettingMDT.EDIPaymentMethod__c,
        'bankAccountNumber' => currencySettingMDT.bankAccountNumber__c,
        'bankEDIIDNumber' => currencySettingMDT.bankEDIIDNumber__c,
        'accountHolderName' => currencySettingMDT.accountHolderName__c,
        'EFTRequester' => currencySettingMDT.EFTRequester__c
      },
      'paymentData' => new Map<String, String>(),
      'supplierData' => new Map<String, String>(),
      'bankData' => new Map<String, String>{
        'bankSiteCode' => currencySettingMDT.bankSiteCode__c,
        'addressLine1' => currencySettingMDT.addressLine1__c,
        'city' => currencySettingMDT.city__c,
        'postalCode' => currencySettingMDT.postalCode__c,
        'country' => currencySettingMDT.country__c
      },
      'supplierSiteData' => new Map<String, String>(),
      'invoiceData' => new Map<String, String>(),
      'invoiceFlexfields' => new Map<String, String>()
    };

    for (Map<String, String> record : currencySettings.values()) {
      record.put(
        'tradingPartnerCode',
        currencySettingMDT.tradingPartnerCode__c
      );
      record.put('translatorCode', currencySettingMDT.translatorCode__c);
      record.put('ref1Batch', currencySettingMDT.ref1Batch__c);
    }

    return currencySettings;
  }
}
