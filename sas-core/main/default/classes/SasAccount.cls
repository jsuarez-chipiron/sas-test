public without sharing class SasAccount {

    // Get the EB level for an EB number by searching for the account with that EB number.
    // If the account does not exist, COSD is searched for the EB number. 
    // If the account is found in CODS, it's added to Salesforce.
    @InvocableMethod(label='getId' description='Get the account Id a EB number' category='Account')
    public static List<Account> getId(List<String> eurobonusNumbers) {
        
        List<Account> toReturn = new List<Account>();
        
        for (String ebNumber : eurobonusNumbers) {
            List<Account> existingAccounts = AccountsSelector.newInstance().selectByEuroBonusNumber(new Set<String>{ebNumber});
            if (existingAccounts.size() == 1) {
                toReturn.addAll(existingAccounts);
            } else if (existingAccounts.size() == 0) {
                Account externalAccount = FCS_IdentifyCustomerController.findCustomer('EBNumber__c', ebNumber);
               if (externalAccount != null) {
               toReturn.add(externalAccount);
               } 
            } else {
                continue;
            }
        }
        return toReturn;
    }
}