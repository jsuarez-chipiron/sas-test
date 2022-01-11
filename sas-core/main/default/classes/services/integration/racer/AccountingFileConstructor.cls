/**
 * A class for creating accounting files from AccountingEntries.
 *
 * These are sent further to RACER to be passed along to accounting.
 *
 * See Confluence for more details.
 */
public class AccountingFileConstructor {
  private static final String VERIFICATION_NUMBER = '123';

  public class CreateFileException extends Exception {
  }

  public static Id create(
    List<AccountingEntry> accountingEntries,
    String fileCurrency
  ) {
    if (
      fileCurrency == null ||
      accountingEntries == null ||
      accountingEntries.isEmpty()
    ) {
      throw new CreateFileException('AccountingFileConstructor.create# Missing parameters');
    }

    String fileContents = '';
    Integer sumOfEntries = 0;

    // Create one debit line per accounting entry.
    for (AccountingEntry entry : accountingEntries) {
      for (String field : AccountingEntry.FIELDS_IN_ORDER) {
        if (field == 'Amount') {
          // A special case. Padded with to left zeroes and added up to a total line.
          String amountAsText = entry.data.get(field);

          fileContents += amountAsText.leftPad(
            AccountingEntry.FIELD_LENGTHS.get(field),
            '0'
          );

          sumOfEntries += entry.amount;
        } else {
          // Check if this is a constant field.
          String fieldContents = AccountingEntry.CONSTANT_FIELDS_FOR_DEBITS.get(
            field
          );

          // If yes, we should add that value. If not, we should get the value
          // from the accounting entry.
          String textToAdd = fieldContents == null
            ? entry.data.get(field)
            : fieldContents;

          // Pad text to full field length as the file format is column based.
          fileContents += textToAdd.rightPad(
            AccountingEntry.FIELD_LENGTHS.get(field)
          );
        }
      }
      fileContents += '\n';
    }

    // Create corresponding credit lines
    for (AccountingEntry entry : accountingEntries) {
      for (String field : AccountingEntry.FIELDS_IN_ORDER) {
        if (field == 'Amount') {
          // A special case. Padded with zeroes to left.
          String amountAsText = entry.data.get(field);

          fileContents += amountAsText.leftPad(
            AccountingEntry.FIELD_LENGTHS.get(field),
            '0'
          );
        } else {
          String fieldContents = AccountingEntry.CONSTANT_FIELDS_FOR_CREDITS.get(
            field
          );

          String textToAdd = fieldContents == null
            ? entry.data.get(field)
            : fieldContents;

          fileContents += textToAdd.rightPad(
            AccountingEntry.FIELD_LENGTHS.get(field)
          );
        }
      }
      fileContents += '\n';
    }

    fileContents += createTotalLine(sumOfEntries);

    String dayOfYear = String.valueOf(Date.today().dayOfYear());
    // Format is a5{AUN}{dayOfYear}{RunningCoun}
    String fileName = 'a501' + dayOfYear + '0'; // TODO: This isn't the same as the files we have.

    ContentVersion accountingFile = new ContentVersion(
      ContentLocation = 'S',
      PathOnClient = fileName + '.txt',
      Title = fileName,
      VersionData = Blob.valueOf(fileContents)
    );

    insert accountingFile;

    return accountingFile.Id;
  }

  private static String createTotalLine(Integer sumOfEntries) {
    String totalLine = 'RAT01';
    totalLine += VERIFICATION_NUMBER.rightPad(60);
    totalLine += String.valueOf(sumOfEntries).leftPad(17, '0');
    totalLine += ''.rightPad(AccountingEntry.FIELD_LENGTHS.get('Description'));
    totalLine += AccountingEntry.CONSTANT_FIELDS_FOR_DEBITS.get('CompanyCode')
      .rightPad(AccountingEntry.FIELD_LENGTHS.get('CompanyCode'));
    totalLine += AccountingEntry.CONSTANT_FIELDS_FOR_DEBITS.get('FeederName')
      .rightPad(AccountingEntry.FIELD_LENGTHS.get('FeederName'));
    totalLine += AccountingEntry.CONSTANT_FIELDS_FOR_DEBITS.get(
        'DeliveryNumber'
      )
      .rightPad(AccountingEntry.FIELD_LENGTHS.get('DeliveryNumber'));

    return totalLine;
  }
}
