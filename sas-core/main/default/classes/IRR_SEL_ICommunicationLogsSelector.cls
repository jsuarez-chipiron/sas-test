/**
* @author Ludvig Wäilmaa, Deloitte
* @date 2020
*
*/

public interface IRR_SEL_ICommunicationLogsSelector extends fflib_ISObjectSelector {
    Map<String, IRR_CommunicationLog__c> getLatestResponseMessageByRecipients(Set<String> recipients);
    Database.QueryLocator getGDPRLogsQueryLocator(DateTime lastRetentionDate); 
    List<IRR_CommunicationLog__c> selectLogsNewerThanForContactKey(Set<String> contactKeys, DateTime lastRetentionDate);
    List<IRR_CommunicationLog__c> getCommunicationMessagesbyEBAccount(Set<String> seAccIds);
    
}