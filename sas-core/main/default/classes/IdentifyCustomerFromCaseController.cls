public with sharing class IdentifyCustomerFromCaseController {


    @AuraEnabled
    public static Account findCustomer(String searchField, String searchValue){
        String query = 'SELECT ExternalId, EBNumber__c, FirstName__c, LastName__c FROM FrequentFlyer__x WHERE ' + searchField + ' = \'' + searchValue + '\'';
        System.debug('Query: ' + query);
        List<FrequentFlyer__x> externalData = Database.query(query);
        if(!externalData.isEmpty()){
            FrequentFlyer__x data = externalData[0];
            Account acc = new Account();
            acc.FirstName = data.FirstName__c;
            acc.LastName = data.LastName__c;
            acc.EBNumber__c = '700001043';
            acc.TPAccountNumber__c = '700001042';
            acc.FrequentFlyer__c = data.ExternalId;
            acc.CustomerIdentifier__c = data.ExternalId;
            acc.LastRetrievedFromSource__c = Datetime.now();

            upsert acc CustomerIdentifier__c;
            return acc;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseData(String caseId){
        return [SELECT Id, AccountId, EBNumber__c, TPAccountNumber__c, Account.FrequentFlyer__c, Account.LastRetrievedFromSource__c FROM Case WHERE Id = :caseId];
    }
}