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
                        'CountryCode__c, CountyState__c, EmailPersonal__c, EBBalance__c, EBLevel__c, EBNumber__c, CMP__c, ' +
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
                    CMP__c = ff.CMP__c,
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
     * Used to retrieve data for the record that the controller is called from.
     * @param recordId Record id for the record where the component is called from.
     * @return Abstract interpretation of object in context, containing record data.
     */
    @AuraEnabled(Cacheable = true)
        public static ComponentRecordData getRecordData(Id recordId){
        SObjectType sObjectType = recordId.getSobjectType();
        if(sObjectType == Case.getSObjectType()){
            return new ComponentRecordData(
                    [SELECT Id, EBNumber__c, TPAccountNumber__c, AccountId,
                    Account.FrequentFlyer__c, Account.LastRetrievedFromSource__c
                    FROM Case
                    WHERE Id = :recordId]
            );
        } else if (sObjectType == LiveChatTranscript.getSObjectType()){
            return new ComponentRecordData(
                    [SELECT Id, EBNumber__c, CODSId__c, Account.PersonContactId, Account.FrequentFlyer__c, CaseId, Account.LastRetrievedFromSource__c
                    FROM LiveChatTranscript
                    WHERE Id = :recordId]
            );
        }
        return null;
    }

    /**
     * Class used as an abstract interpretation of multiple SObject types. The class is used to communicate data
     * between the controlled and the Lightning Web Component, as well as performing actions on records encapsuled
     * by this wrapper. To support new SObject types, add a new constructor and a corresponding block in the update method.
     */
    public class ComponentRecordData{
        @AuraEnabled public Id recordId {get; private set;}
        @AuraEnabled public Id accountId {get; private set;}
        @AuraEnabled public Id personContactId {get; private set;}
        @AuraEnabled public Id caseId {get; private set;}
        @AuraEnabled public String euroBonusNumber {get; private set;}
        @AuraEnabled public String tpAccountNumber {get; private set;}
        @AuraEnabled public String codsId {get; private set;}
        @AuraEnabled public Datetime lastRetrievedFromSource {get; private set;}
        /**
         * Indicates that this SObjectType supports UI API. This enables transactions in JavaScript without
         * utilizing APEX to perform DML.
         */
        @AuraEnabled public Boolean supportsUIApi {get; private set;}

        /**
         * Constructor for class
         * @param cse Case record used to populate class params
         */
        public ComponentRecordData(Case cse) {
            recordId = cse.Id;
            accountId = cse.AccountId;
            euroBonusNumber = cse.EBNumber__c;
            tpAccountNumber = cse.TPAccountNumber__c;
            codsId = cse.Account.FrequentFlyer__c;
            lastRetrievedFromSource = cse.Account.LastRetrievedFromSource__c;
            supportsUIApi = true;
        }

        /**
         * Constructor for class
         * @param transcript LiveChatTranscript record used to populate class params
         */
        public ComponentRecordData(LiveChatTranscript transcript){
            recordId = transcript.Id;
            accountId = transcript.AccountId;
            personContactId = transcript.Account.PersonContactId;
            euroBonusNumber = transcript.EBNumber__c;
            codsId = transcript.CODSId__c;
            caseId = transcript.CaseId;
            lastRetrievedFromSource = transcript.Account.LastRetrievedFromSource__c;
            supportsUIApi = false;
        }

        /**
         * Used to perform an update with dynamic selection of SObject type based on type derived from record id.
         */
        public void updateUnderlyingRecord(){
            SObject[] recordsToUpdate = new SObject[]{};
            if(recordId.getSobjectType() == LiveChatTranscript.getSObjectType()){
                recordsToUpdate.add(generateRecord(recordId));
                if(caseId != null){
                    recordsToUpdate.add(generateRecord(caseId));
                }
            } else if (recordId.getSobjectType() == Case.getSObjectType()){
                recordsToUpdate.add(generateRecord(recordId));
                    for(LiveChatTranscript transcript:[SELECT Id FROM LiveChatTranscript WHERE CaseId = :recordId]){
                        recordsToUpdate.add(generateRecord(transcript.Id));
                    }
            }
            update recordsToUpdate;
        }

        /**
         * Used to populate a new SObject record based on values in ComponentRecordData.
         * @param recordId Id of record to create. Possible to set to enable creation of records based on related Ids.
         * @return A new SObject record.
         */
        private SObject generateRecord(Id recordId){
            SObject returnRecord;
            if(recordId.getSobjectType() == Case.SObjectType){
                returnRecord = new Case(
                        Id = recordId,
                        AccountId = accountId,
                        TPAccountNumber__c = tpAccountNumber,
                        CODSId__c = codsId,
                        EBNumber__c = euroBonusNumber
                );
            } else if (recordId.getSobjectType() == LiveChatTranscript.SObjectType){
                returnRecord = new LiveChatTranscript(
                        Id = recordId,
                        AccountId = accountId,
                        EBNumber__c = euroBonusNumber,
                        CODSId__c = codsId,
                        ContactId = personContactId
                );
            }
            return returnRecord;
        }
    }

    /**
     * Used to perform an update from a Lightning Web Component with apex, when UI API is not supported.
     * @param jsonData JSON structure corresponding to the ComponentRecordData class.
     */
    @AuraEnabled
    public static void updateRecordDataWithApex(String jsonData){
        ComponentRecordData recordData = (ComponentRecordData)JSON.deserialize(jsonData, ComponentRecordData.class);
        recordData.updateUnderlyingRecord();
    }
}