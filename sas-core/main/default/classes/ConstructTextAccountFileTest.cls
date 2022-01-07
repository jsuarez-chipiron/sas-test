@isTest
public class ConstructTextAccountFileTest {
  public static testMethod void testConstructAccFiles() {
    List<AccountFile> lstAccFiles = new List<AccountFile>();
    
    Settlement__c sett = new Settlement__c();
    sett.Currency__c = 'SEK';
    sett.Date_of_Exchange_Calculation__c = date.Today().addDays(-3);
    insert sett;
    
    Settlement_Item__c settItem = new Settlement_Item__c ();
    settItem.Cost_Account__c = '6727';
    settItem.Amount__c = 234;
    settItem.Settlement__c = sett.Id;
    
    insert settItem;
    
   String accFile = ConstructTextAccountFileController.getAccountFileText('SEK');
   System.debug('accFile**'+accFile);
  }
}