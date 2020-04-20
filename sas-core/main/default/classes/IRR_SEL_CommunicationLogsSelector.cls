/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_SEL_CommunicationLogsSelector extends fflib_SObjectSelector
        implements IRR_SEL_ICommunicationLogsSelector {

    public static IRR_SEL_ICommunicationLogsSelector newInstance() {
        return (IRR_SEL_ICommunicationLogsSelector)
                IRR_Application.Selector.newInstance(IRR_CommunicationLog__c.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
                IRR_CommunicationLog__c.Id
        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_CommunicationLog__c.SObjectType;
    }

    public Database.QueryLocator getGDPRLogsQueryLocator(Integer olderThanDays) {
        return null;
    }

    public List<IRR_CommunicationLog__c> selectLogsNewerThanForContactKey(Set<String> contactKeys,
            Integer newerThanDays) {
        return null;
    }
}