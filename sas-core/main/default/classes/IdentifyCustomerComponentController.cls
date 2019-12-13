/**
 * @author Anton Norell
 * @date 2019-10-01
 * @description Controller for component used to identify a customer from a Salesforce record. Includes methods
 * to retrieve data and create data.
 */
public with sharing class IdentifyCustomerComponentController {
    /**
     * Used to handle request to fins a customer from the component. A list of frequent flyer record is fetched by
     * a query, and then the first record in the list is synced to a corresponding account record in Salesforce.
     * If the account already exists it is updated, otherwise created.
     * @param searchField Field on Frequent Flyer object to use as filter to retrieve customer, e.g. EBNumber__c
     * @param searchValue Value for the search field, e.g. a EuroBonus number
     * @return If an account is found it is returned, otherwise null,
     */
    @AuraEnabled
    public static Account findCustomer(String searchField, String searchValue){
        String query = 'SELECT Id, ExternalId, AddressLine1__c, AddressLine2__c, AddressLine3__c, BirthDate__c, ' +
                        'City__c, ConsentTelemarketing__c, ConsentEB0__c, ConsentSMS__c, ConsentEB__c, ConsentEmail__c, ' +
                        'CountryCode__c, CountyState__c, EmailPersonal__c, EBBalance__c, EBLevel__c, EBNumber__c, ' +
                        'FirstName__c, LastName__c, Gender__c, EBMemberSinceDate__c, Mobile__c, Name__c, Phone__c, ' +
                        'EBMbrshipLvlStatusStartDate__c, EBMbrshipLvlStatusEndDate__c, EBReachesNextLevelPoints__c, ' +
                        'SubscriptionId__c, TPAccountNumber__c, ZipCode__c, CompanyName__c, Title__c, MiddleName__c, Salutation__c ' +
                        'FROM FrequentFlyer__x ' +
                        'WHERE ' + searchField + ' = \'' + searchValue + '\'';
        List<FrequentFlyer__x> externalData = Database.query(query);
        return createAccountRecordBasedOnFrequentFlyers(externalData);
    }

    /**
     * Used to create an account based on a Frequent Flyer record. If additional fields are added in the mapping
     * below, they also have to be added to the query retrieving the frequent flyer record.
     * @param frequentFlyers List of Frequent Flyer record to generate accounts for
     * @return List of account generated
     */
    @TestVisible
    private static Account createAccountRecordBasedOnFrequentFlyers(List<FrequentFlyer__x> frequentFlyers){
        List<Account> accounts = new List<Account>();
        for(FrequentFlyer__x ff:frequentFlyers){
            Account newAccount = new Account(
                    RecordTypeId = RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER,
                    CODSId__c = ff.ExternalId,
                    FrequentFlyer__c = ff.ExternalId,
                    PersonMailingStreet = ff.AddressLine1__c,
                    PersonMailingCity = ff.City__c,
                    PersonMailingPostalCode = ff.ZipCode__c,
                    PersonMailingCountry = ff.CountryCode__c,
                    PersonMailingState = ff.CountyState__c,
                    PersonBirthdate = ff.BirthDate__c != null ? Date.valueOf(ff.BirthDate__c) : null,
                    ConsentEmail__c = ff.ConsentEmail__c,
                    ConsentEuroBonus__c = ff.ConsentEB__c,
                    ConsentSMS__c = ff.ConsentSMS__c,
                    ConsentSiteProfile__c = ff.ConsentEB0__c,
                    ConsentTelemarketing__c = ff.ConsentTelemarketing__c,
                    PersonEmail = ff.EmailPersonal__c,
                    EBBalance__c = ff.EBBalance__c,
                    EBLevel__c = ff.EBLevel__c,
                    EBNumber__c = ff.EBNumber__c,
                    FirstName = ff.FirstName__c,
                    Gender__c = ff.Gender__c,
                    LastName = ff.LastName__c,
                    EBMemberSinceDate__c = ff.EBMemberSinceDate__c != null ? Date.valueOf(ff.EBMemberSinceDate__c) : null,
                    PersonMobilePhone = ff.Mobile__c,
                    PersonHomePhone = ff.Phone__c,
                    EBMbrshipLvlStatusEndDate__c = ff.EBMbrshipLvlStatusEndDate__c != null ? Date.valueOf(ff.EBMbrshipLvlStatusEndDate__c) : null,
                    EBMbrshipLvlStatusStartDate__c = ff.EBMbrshipLvlStatusStartDate__c != null ? Date.valueOf(ff.EBMbrshipLvlStatusStartDate__c) : null,
                    EBReachesNextLevelPoints__c = ff.EBReachesNextLevelPoints__c,
                    SubscriptionId__c = ff.SubscriptionId__c,
                    TPAccountNumber__c = ff.TPAccountNumber__c,
                    CompanyName__c = ff.CompanyName__c,
                    PersonTitle = ff.Title__c,
                    Salutation = ff.Salutation__c,
                    MiddleName = ff.MiddleName__c,
                    LastRetrievedFromSource__c = Datetime.now()
            );
            accounts.add(newAccount);
        }
        if(!accounts.isEmpty()){
            upsert accounts[0] CODSId__c;
            return accounts[0];
        }
        return null;
    }

    /**
     * Used to retrieve case data for the case record that the controller is called from.
     * @param caseId Id for case to retrieve data
     * @return Case record corresponding to the supplied Id
     */
    @AuraEnabled(Cacheable=true)
    public static Case getCaseData(Id caseId){
        return [SELECT Id, AccountId, EBNumber__c, TPAccountNumber__c, Account.FrequentFlyer__c, Account.LastRetrievedFromSource__c FROM Case WHERE Id = :caseId];
    }
}