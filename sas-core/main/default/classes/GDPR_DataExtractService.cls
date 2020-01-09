/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Class used to hold operations related to extracting personal data
 */
public with sharing class GDPR_DataExtractService {
    /**
     * Determines the name of the ComplianceGroup field value on FieldDefinition that determines if field
     * should be included in GDPR Extract.
     */
    private static final String PII_TAG = 'PIIExtract';
    /**
     * Object name for Case object
     */
    private static final String CASE_OBJECT = Case.SObjectType.getDescribe().name;
    /**
     * Object name for Account object
     */
    private static final String ACCOUNT_OBJECT = Account.SObjectType.getDescribe().name;
    /**
     * Object name for Chat Transcript object
     */
    private static final String CHAT_TRANSCRIPT_OBJECT = LiveChatTranscript.SObjectType.getDescribe().name;
    /**
     * Object name for Email object
     */
    private static final String EMAIL_OBJECT = EmailMessage.SObjectType.getDescribe().name;

    /**
     * Generates a JSON extract of a customer's Personal Identifiable Information based on the supplied account id.
     * Fields included per object are defined on field level with metadata "ComplianceGroup. If new objects should be
     * included in extract, the objects should be added to query for field definitions and to lost of queries in the method.
     * @param accountIds Account to generate extract for
     * @param fieldDefinitions Externally provided FieldDefinition. Available to set primarily for test purposes, but
     * should be null for most uses.
     * @return List of JSON structures with the customer's data, one instance for each account
     */
    public static String[] extractAccountPersonalData(Id[] accountIds, List<FieldDefinition> fieldDefinitions){
        if(fieldDefinitions == null){
            //ComplianceGroup filter set to != null due to inability to filter on list for field
            fieldDefinitions =
                    [SELECT QualifiedApiName, ComplianceGroup, SecurityClassification, EntityDefinitionId
                    FROM FieldDefinition
                    WHERE EntityDefinitionId
                    IN (:CASE_OBJECT, :ACCOUNT_OBJECT, :CHAT_TRANSCRIPT_OBJECT, :EMAIL_OBJECT)
                    AND ComplianceGroup != NULL];
        }

        Map<Id, SObject[]> extractByAccountId = new Map<Id, SObject[]>();
        for(String query : getQueries(fieldDefinitions, accountIds)){
            System.debug('QUery:' + query);
            //In cases where no fields for object are tagged as PII, only Id is retrieved
            SObject[] records = Database.query(query.replace('null', 'Id'));

            String accountIdentifierField = getSObjectTypeAccountIdentifier(records.getSObjectType());

            for(SObject record:records){
                Id recordAccountId = (Id)record.get(accountIdentifierField);
                if(extractByAccountId.get(recordAccountId) == null){
                    extractByAccountId.put(recordAccountId, new SObject[]{record});
                } else {
                    extractByAccountId.get(recordAccountId).add(record);
                }
            }
        }

        String[] jsonExtracts = new String[]{};
        for(SObject[] records:extractByAccountId.values()){
            jsonExtracts.add(JSON.serializePretty(records));
        }
        return jsonExtracts;
    }

    /**
     * Used to generate queries to extract Personal Information based on field metadata and an account
     * @param fieldDefinitions Field definitions containing information about which fields and objects
     * to include in queries
     * @param accountId Id for account to generate extract for
     * @return List of queries that can be used to retrieve personal data
     */
    @TestVisible
    private static List<String> getQueries(List<FieldDefinition> fieldDefinitions, Id[] accountIds) {
        Map<String, String> fieldSelections = new Map<String, String>();
        for (FieldDefinition def : fieldDefinitions) {
            if (def.ComplianceGroup.contains(PII_TAG)) {
                String currentFieldSelection = fieldSelections.get(def.EntityDefinitionId);
                if (currentFieldSelection == null) {
                    fieldSelections.put(def.EntityDefinitionId, def.QualifiedApiName + ', ');
                } else {
                    fieldSelections.put(def.EntityDefinitionId, currentFieldSelection += def.QualifiedApiName + ', ');
                }
            }
        }

        for (String fieldSelectionKey : fieldSelections.keySet()) {
            fieldSelections.put(fieldSelectionKey, fieldSelections.get(fieldSelectionKey).removeEnd(', '));
        }

        String[] accountIdsAsStrings = new String[]{};
        for(Id accId : accountIds){
            accountIdsAsStrings.add('\'' + accId + '\'');
        }

        List<String> queries = new List<String>();
        queries.add('SELECT ' + fieldSelections.get(ACCOUNT_OBJECT) + ' FROM ' + ACCOUNT_OBJECT + ' WHERE Id IN ' + accountIdsAsStrings);
        String emailSubQuery = ', (SELECT ' + fieldSelections.get(EMAIL_OBJECT) + ' FROM ' + EMAIL_OBJECT + 's)';
        queries.add('SELECT ' + fieldSelections.get(CASE_OBJECT) + emailSubQuery + ' FROM ' + CASE_OBJECT + ' WHERE AccountId IN ' + accountIdsAsStrings);
        queries.add('SELECT ' + fieldSelections.get(CHAT_TRANSCRIPT_OBJECT) + ' FROM ' + CHAT_TRANSCRIPT_OBJECT + ' WHERE AccountId IN ' + accountIdsAsStrings);

        return queries;
    }

    private static String getSObjectTypeAccountIdentifier(SObjectType sObjectType){
        String identifier;
        if (sObjectType == Account.SObjectType){
            identifier = 'Id';
        } else if (sObjectType == Case.SObjectType){
         identifier = 'AccountId';
        } else if (sObjectType == LiveChatTranscript.SObjectType){
            identifier = 'AccountId';
        }
        return identifier;
    }
}