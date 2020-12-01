/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
*/
public class IRR_SEL_EventLogsSelector extends fflib_SObjectSelector
    implements IRR_SEL_IEventLogsSelector {

    public static IRR_SEL_IEventLogsSelector newInstance() {
        return (IRR_SEL_IEventLogsSelector)
            IRR_Application.Selector.newInstance(IRR_EventLog__c.SObjectType);
        }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
                IRR_EventLog__c.Id,
                IRR_EventLog__c.CreatedDate,
                IRR_EventLog__c.Event_Payload_1__c,
                IRR_EventLog__c.Event_Payload_2__c,
                IRR_EventLog__c.Event_Payload_3__c,
                IRR_EventLog__c.Event_Payload_4__c,
                IRR_EventLog__c.IRR_EventTime__c,
                IRR_EventLog__c.IRR_ScheduleTime__c,
                IRR_EventLog__c.IRR_FlightId__c
        };
    }   

    public Schema.SObjectType getSObjectType() {
    return IRR_EventLog__c.SObjectType;
    }

    public Database.QueryLocator getQueuedCheckinQueryLocator( ) {
        Datetime currentTime = System.Now();
        fflib_QueryFactory queryFactory = newQueryFactory()
            .setCondition('IRR_ScheduleTime__c <= :currentTime');
        return Database.getQueryLocator(queryFactory.toSOQL());

    }
}