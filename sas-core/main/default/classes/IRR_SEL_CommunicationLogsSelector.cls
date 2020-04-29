/**
* @author Ludvig Wälimaa, Deloitte
* @date 2020
*
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
                IRR_CommunicationLog__c.Id,
                IRR_CommunicationLog__c.CreatedDate,
                IRR_CommunicationLog__c.IRR_ContactKey__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return IRR_CommunicationLog__c.SObjectType;
    }

    public Database.QueryLocator getGDPRLogsQueryLocator(DateTime lastRetentionDate) {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .setCondition('CreatedDate <= :lastRetentionDate');
        System.debug(queryFactory.toSOQL());
        return Database.getQueryLocator(queryFactory.toSOQL());
    }

    public List<IRR_CommunicationLog__c> selectLogsNewerThanForContactKey(Set<String> contactKeys,
        DateTime lastRetentionDate) {
        fflib_QueryFactory queryFactory = newQueryFactory()
        .setCondition('CreatedDate > :lastRetentionDate AND IRR_ContactKey__c IN :contactKeys');
        System.debug(queryFactory.toSOQL());
        return Database.query(queryFactory.toSOQL());
    }
}