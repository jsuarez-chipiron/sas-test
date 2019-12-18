/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description Controller for LWC accountGDPRExtract component.
 */
public with sharing class AccountGDPRExtractController {
    @AuraEnabled
    public static ContentVersion generateExtractFile(Id accountId){
        String jsonExtract = DataExtractService.extractPIIData(accountId);

        ContentVersion extractFile = new ContentVersion();
        extractFile.Description = 'Extract of Personal Identifiable Information.';
        extractFile.ContentLocation = 'S';
        extractFile.PathOnClient = 'GDPR extract ' + Date.today().format() + '.json';
        extractFile.Title = 'GDPR extract ' + Date.today().format() + '.json ';
        extractFile.VersionData = Blob.valueOf(jsonExtract);
        insert extractFile;

        return [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :extractFile.Id];
    }

}