/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Controller for LWC gdpr_AccountGDPRExtract component.
 */
public with sharing class GDPR_AccountGDPRExtractController {
    @AuraEnabled
    public static ContentVersion generateExtractFile(Id accountId){
        String jsonExtract = DataExtractService.extractAccountPersonalData(accountId, null);

        ContentVersion extractFile = new ContentVersion();
        extractFile.Description = 'Extract of Personal Identifiable Information.';
        extractFile.ContentLocation = 'S';
        extractFile.PathOnClient = 'GDPR extract ' + Date.today().format() + '.json';
        extractFile.Title = 'GDPR extract ' + Date.today().format() + '.json ';
        extractFile.VersionData = Blob.valueOf(jsonExtract);
        insert extractFile;

        return [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :extractFile.Id];
    }
}