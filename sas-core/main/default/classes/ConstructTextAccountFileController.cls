public class ConstructTextAccountFileController
{
   public static string getAccountFileText(String currencyType)
   {
     List<AccountFile> lstAccFiles = new List<AccountFile>();
     System.debug('inside controller');
     List<Settlement_Item__c> lstSettlementItems = [SELECT 
                                                 Id,
                                                 Cost_Account__c,
                                                 Amount__c,
                                                 Settlement__r.Name,
                                                 Settlement__r.Currency__c,
                                                 Settlement__r.Date_of_Exchange_Calculation__c
                                                 FROM
                                                 Settlement_Item__c
                                                 WHERE
                                                 Settlement__r.Currency__c=:currencyType
                                                 ];
         if(!lstSettlementItems.isEmpty()) 
         {                                    
            for(Settlement_Item__c item: lstSettlementItems)
             {
               AccountFile accFile = new AccountFile(
                                                  item.Settlement__r.Date_of_Exchange_Calculation__c,
                                                  item.Cost_Account__c,
                                                  item.Settlement__r.Name,
                                                  item.Settlement__r.Currency__c,
                                                  String.valueOf(item.Amount__c)
                                                );
                lstAccFiles.add(accFile);                                
             } 
             
         } 
         if(!lstAccFiles.isEmpty() && lstAccFiles.size()>0)
         {
         return ConstructTextAccountFile.constructAccountFile(lstAccFiles,currencyType);
         }
         else                                  
        return null;
   }
}