/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_DOM_CommunicationLogs extends fflib_SObjectDomain
        implements IRR_DOM_ICommunicationLogs {

    public static IRR_DOM_ICommunicationLogs newInstance(List<SObject> sObjectList) {
        return (IRR_DOM_ICommunicationLogs) IRR_Application.Domain.newInstance(sObjectList);
    }

    public Set<String> processGDPRLogs(fflib_ISObjectUnitOfWork uow) {
        Integer days = null;
        Set<String> contactKeys = null;
        List<IRR_CommunicationLog__c> newerLogs = IRR_SEL_CommunicationLogsSelector.newInstance()
                .selectLogsNewerThanForContactKey(contactKeys, days);
        return null;
    }

    public IRR_DOM_CommunicationLogs(List<SObject> records) {
        super(records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new IRR_DOM_CommunicationLogs(records);
        }
    }
}