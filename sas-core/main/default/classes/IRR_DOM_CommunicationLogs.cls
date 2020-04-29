/**
* @author Ludvig Wälimaa, Deloitte
* @date 2020
*
* @description Domain to process Communication Logs
*/

public class IRR_DOM_CommunicationLogs extends fflib_SObjectDomain
        implements IRR_DOM_ICommunicationLogs {

    public static IRR_DOM_ICommunicationLogs newInstance(List<SObject> sObjectList) {
        return (IRR_DOM_ICommunicationLogs) IRR_Application.Domain.newInstance(sObjectList);
    }

     /**
     * @author Ludvig Wälimaa, Deloitte
     * @date 2020
     *
     * @description Processing Communication Logs in form of deleting them from Service Cloud and initating call to MC to delete contacts. 
     *
     * @param uow FFLIB uow
     * @param lastRetentionDate The last retention date of a Communication Log
     */
    public void processGDPRLogs(fflib_ISObjectUnitOfWork uow, DateTime lastRetentionDate) {
        //We have the Ids of the Communication Logs to be deleted
        List<IRR_CommunicationLog__c> logs = (List<IRR_CommunicationLog__c>) records;
        System.debug('logs ' + logs);
        Set<String> contactKeys = new Set<String>();
        for(IRR_CommunicationLog__c c : logs){
            contactKeys.add(c.IRR_ContactKey__c);
        }
        
        System.debug('contactKeys ' + contactKeys);
        
        //Check if there are other communication logs with the same contactKey (phone/email) but outside of retentionDate
        List<IRR_CommunicationLog__c> newerLogs = IRR_SEL_CommunicationLogsSelector.newInstance()
                .selectLogsNewerThanForContactKey(contactKeys, lastRetentionDate);
                System.debug('newerLogs ' + newerLogs);
        //Remove contactKeys with newer Communication Logs
        for(IRR_CommunicationLog__c c : newerLogs){
            if(contactKeys.contains(c.IRR_ContactKey__c)){
                contactKeys.remove(c.IRR_ContactKey__c);
            }            
        }

        System.debug('contactKeys (to be deleted) ' + contactKeys);
        //Delete contacts in MC
        Boolean isDeleted = IRR_SVC_SFMCService.deleteContacts(contactKeys);   

        if(isDeleted){
            System.debug('deleted in MC');
            //Delete in Salesforce
            for(IRR_CommunicationLog__c c : logs){
                uow.registerDeleted(c);
            }
        }else{
            System.debug('Not deleted in MC');
        }
        
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