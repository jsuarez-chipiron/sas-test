/**
 * @author Anton Norell
 * @date 2020-01-08
 * @description Controller for LWC accountGDPRDelete component.
 */
public with sharing class AccountGDPRDeleteController {
    /**
     * Initiates batch to deleta account data and data related to account
     * @param accountId Id of account to delete data for
     */
    @AuraEnabled
    public static void startBatchDelete(Id accountId){
        //TODO Implement method
    }
}