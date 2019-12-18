/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Class used to hold operations related to extracting personal data
 */
public with sharing class DataExtractService {
    /**
     * Generates a JSON extract of a customer's Personal Identifiable Information based on the supplied account id.
     * The objects included in the extract must be modified within the method, while the fields included per object
     * uses the Compliance Group field metadata.
     * @param accountId Account to generate extract for
     * @return JSON structure with the customer's data
     */
    public static String extractPIIData(Id accountId){
        List<FieldDefinition> fieldDefinitions =
                [SELECT QualifiedApiName, ComplianceGroup, SecurityClassification, EntityDefinitionId
                FROM FieldDefinition
                WHERE EntityDefinitionId
                IN ('Case', 'LiveChatTranscript', 'EmailMessage') AND ComplianceGroup != NULL];

        String caseFieldSelection = '';
        String transcriptFieldSelection = '';
        String emailFieldSelection = '';

        for(FieldDefinition def : fieldDefinitions){
            if(def.ComplianceGroup.contains('PIIExtract')){
                if(def.EntityDefinitionId == 'Case'){
                    caseFieldSelection += def.QualifiedApiName + ', ';
                } else if(def.EntityDefinitionId == 'LiveChatTranscript'){
                    transcriptFieldSelection += def.QualifiedApiName + ', ';
                } else if(def.EntityDefinitionId == 'EmailMessage'){
                    emailFieldSelection += def.QualifiedApiName + ', ';
                }
            }
        }
        caseFieldSelection = caseFieldSelection.removeEnd(', ');
        transcriptFieldSelection = transcriptFieldSelection.removeEnd(', ');
        emailFieldSelection = emailFieldSelection.removeEnd(', ');

        String emailSubQuery = ', (SELECT ' + emailFieldSelection + ' FROM EmailMessages)';
        String caseQuery = 'SELECT ' + caseFieldSelection + emailSubQuery + ' FROM Case WHERE AccountId = \'' + accountId + '\'';
        String transcriptQuery = 'SELECT ' + transcriptFieldSelection + ' FROM LiveChatTranscript WHERE Account.FrequentFlyer__c = \'' + accountId + '\'';

        CustomerDataExtract  extract = new CustomerDataExtract();
        extract.casesAndEmails = Database.query(caseQuery);
        extract.chatTranscripts = Database.query(transcriptQuery);

        return JSON.serializePretty(extract);
    }

    private class CustomerDataExtract{
        public List<Case> casesAndEmails;
        public List<LiveChatTranscript> chatTranscripts;
    }
}