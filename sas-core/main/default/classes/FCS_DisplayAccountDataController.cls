/**
 * @author Anton Norell
 * @date 2020-02-18
 * @description Controller for component DisplayAccountData
 */
public with sharing class FCS_DisplayAccountDataController {
    /**
     * Used to retrieve account id connected to a records on which the component calls from
     * @param recordId Id of record on which component is placed and for which the account id should be retrieved
     * @return Account id for record
     */
    @AuraEnabled
    public static Id getAccountId(Id recordId){
        Id accountId;
        if(recordId.getSobjectType() == Case.SObjectType){
            accountId = [SELECT AccountId FROM Case WHERE Id = :recordId].AccountId;
        } else if(recordId.getSobjectType() == LiveChatTranscript.SObjectType) {
            accountId = [SELECT AccountId FROM LiveChatTranscript WHERE Id = :recordId].AccountId;
        } else if(recordId.getSobjectType() == MessagingSession.SObjectType){
            accountId = [SELECT EndUserAccountId FROM MessagingSession WHERE Id = :recordId].EndUserAccountId;
        }
        return accountId;
    }
}