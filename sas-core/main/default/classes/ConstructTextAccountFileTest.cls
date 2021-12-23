@isTest
public class ConstructTextAccountFileTest {
  public static testMethod void testConstructAccFiles() {
    List<AccountFile> lstAccFiles = new List<AccountFile>();

    AccountFile accFile = new AccountFile(
      'RAC',
      '01',
      '973270',
      '20210731',
      '6727',
      '90801',
      '78616807',
      '',
      '',
      '',
      '',
      'EUR',
      'D',
      '000000000040000',
      '',
      'SK',
      '2111',
      'CARE',
      '01'
    );
    AccountFile accFile1 = new AccountFile(
      'RAC',
      '01',
      '973270',
      '20210731',
      '6727',
      '90801',
      '78616808',
      '',
      '',
      '',
      '',
      'EUR',
      'D',
      '000000000040000',
      '',
      'SK',
      '2111',
      'CARE',
      '01'
    );
    lstAccFiles.add(accFile);
    lstAccFiles.add(accFile1);

    String strAccFile = ConstructTextAccountFile.constructAccountFile(
      lstAccFiles
    );
    System.debug('accFile**' + strAccFile);
  }
}
