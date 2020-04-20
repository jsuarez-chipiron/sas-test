/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public interface IRR_SEL_ICommunicationLogsSelector extends fflib_ISObjectSelector {
    Database.QueryLocator getGDPRLogsQueryLocator(Integer olderThanDays);
    List<IRR_CommunicationLog__c> selectLogsNewerThanForContactKey(Set<String> contactKeys, Integer newerThanDays);
}