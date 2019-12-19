/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Class used to hold operations related to extracting personal data
 */
public with sharing class DataExtractService {
    private static final String PII_TAG = 'PIIExtract';
    private static final String CASE_OBJECT = Case.SObjectType.getDescribe().name;
    private static final String ACCOUNT_OBJECT = Account.SObjectType.getDescribe().name;
    private static final String CHAT_TRANSCRIPT_OBJECT = LiveChatTranscript.SObjectType.getDescribe().name;
    private static final String EMAIL_OBJECT = EmailMessage.SObjectType.getDescribe().name;

    /**
     * Generates a JSON extract of a customer's Personal Identifiable Information based on the supplied account id.
     * Fields included per object are defined on field level with metadata "ComplianceGroup. If new objects should be
     * included in extract, the objects should be added to query for field definitions and to lost of queries in the method.
     * @param accountId Account to generate extract for
     * @param fieldDefinitions Externally provided FieldDefinition. Available to set primarily for test purposes.
     * @return JSON structure with the customer's data
     */
    public static String extractAccountPersonalData(Id accountId, List<FieldDefinition> fieldDefinitions){
        if(fieldDefinitions == null){
            //ComplianceGroup filter set to != null due to inability to filter on list for field
            fieldDefinitions =
                    [SELECT QualifiedApiName, ComplianceGroup, SecurityClassification, EntityDefinitionId
                    FROM FieldDefinition
                    WHERE EntityDefinitionId
                    IN (:CASE_OBJECT, :ACCOUNT_OBJECT, :CHAT_TRANSCRIPT_OBJECT, :EMAIL_OBJECT)
                    AND ComplianceGroup != NULL];
        }
        String JsonString = JSON.serializePretty(fieldDefinitions);

        List<FieldDefinition> defs = (List<FieldDefinition>)JSON.deserialize(String.valueOf(JsonString), List<FieldDefinition>.class);

        List<SObject> extract = new List<SObject>();
        for(String query : getQueries(fieldDefinitions, accountId)){
            //In cases where no fields for object are tagged as PII, only Id is retrieved
            extract.addAll(Database.query(query.replace('null', 'Id')));
        }
        return JSON.serializePretty(extract);
    }

    /**
     * Used to generate queries to extract Personal Information based on field metadata and an account
     * @param fieldDefinitions Field definitions containing information about which fields and objects
     * to include in queries
     * @param accountId Id for account to generate extract for
     * @return List of queries that can be used to retrieve personal data
     */
    @TestVisible
    private static List<String> getQueries(List<FieldDefinition> fieldDefinitions, Id accountId) {
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

        List<String> queries = new List<String>();
        queries.add('SELECT ' + fieldSelections.get(ACCOUNT_OBJECT) + ' FROM ' + ACCOUNT_OBJECT + ' WHERE Id = \'' + accountId + '\'');
        String emailSubQuery = ', (SELECT ' + fieldSelections.get(EMAIL_OBJECT) + ' FROM ' + EMAIL_OBJECT + 's)';
        queries.add('SELECT ' + fieldSelections.get(CASE_OBJECT) + emailSubQuery + ' FROM ' + CASE_OBJECT + ' WHERE AccountId = \'' + accountId + '\'');
        queries.add('SELECT ' + fieldSelections.get(CHAT_TRANSCRIPT_OBJECT) + ' FROM ' + CHAT_TRANSCRIPT_OBJECT + ' WHERE AccountId = \'' + accountId + '\'');

        System.debug(queries);
        return queries;
    }
}