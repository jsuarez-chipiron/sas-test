/**
 * Domain class for IRR_SMSResponse__c object
 * @author Peter Södergren
 */
public class IRR_DOM_SMSResponses extends fflib_SObjectDomain {
    /**
     * Instantiates the domain using the supplied list of records
     * @param records The records which the domain instanse should operate on
     */
    public IRR_DOM_SMSResponses(List<IRR_SMSResponse__c> records){
        super(records);
        Configuration.disableTriggerCRUDSecurity();
    }
    /**
     * Before insert logic to update communication log messages
     */
    public override void onBeforeInsert(){
        setCommunicationLogData();
    }
    /**
     * Updates the communication logs of the subscriber keys to register the received message and the
     * most recent date of a message response to a communication log. The most recent communication log 
     * from the same phone number is assumed be the communication being responed to.
     * The sms response is also updated to be related to the communication log.
     * Note: This method does not use an fflib unit of work since it want to log errors rather than propagate them.
     */
    public void setCommunicationLogData(){
        Set<String> fromNo = new Set<String>();
        for(IRR_SMSResponse__c sms : (List<IRR_SMSResponse__c>)records){
            if(!String.isBlank(sms.IRR_InfoFrom__c)){
                fromNo.add(sms.IRR_InfoFrom__c);
            }
        }

        if(!fromNo.isEmpty()){
            List<IRR_CommunicationLog__c> comLogList = [SELECT Id,CreatedDate,IRR_Recipient__c,IRR_Response__c,IRR_LastResponseDate__c FROM IRR_CommunicationLog__c WHERE IRR_Recipient__c IN :fromNo FOR UPDATE];
            Map<String,IRR_CommunicationLog__c> comLogMap = new Map<String,IRR_CommunicationLog__c>();
            for(IRR_CommunicationLog__c comLog : comLogList){
                IRR_CommunicationLog__c comLogCurrent = comLogMap.get(comLog.IRR_Recipient__c);
                if(comLogCurrent==null || comLogCurrent.CreatedDate <= comLog.CreatedDate)comLogMap.put(comLog.IRR_Recipient__c,comLog);
            }
            Boolean prevMode = C_Log.setBuffered(true);
            for(IRR_SMSResponse__c sms : (List<IRR_SMSResponse__c>)records){
                if(!String.isBlank(sms.IRR_InfoFrom__c) && comLogMap.containsKey(sms.IRR_InfoFrom__c)){
                    IRR_CommunicationLog__c comLog = comLogMap.get(sms.IRR_InfoFrom__c);
                    comLog.IRR_Status__c='Responded';
                    //Setting the response capped at 255 chars
                    comLog.IRR_Response__c = sms.IRR_InfoMessage__c + (String.isBlank(comLog.IRR_Response__c) ? '' : ', '+comLog.IRR_Response__c);
                    if(comLog.IRR_Response__c.length()>255)comLog.IRR_Response__c = comLog.IRR_Response__c.substring(0,255);
                    //Setting the response date of the last response
                    DateTime smsTime = sms.IRR_DateUTC__c!=null && sms.IRR_TimeUTC__c!=null ? DateTime.newInstance(sms.IRR_DateUTC__c,sms.IRR_TimeUTC__c) : sms.CreatedDate;
                    if(comLog.IRR_LastResponseDate__c == null || comLog.IRR_LastResponseDate__c < smsTime)comLog.IRR_LastResponseDate__c = smsTime;
                    //Relates the sms message to the communication log
                    sms.IRR_CommunicationLog__c = comLog.Id;
                }
                else C_Log.log(C_Log.Severity.Warning, 'Cannot find related communication log for sms: '+sms.Id, null, 'SMSResponse', null);
            }
            try{
                Database.SaveResult[] srList = Database.update(comLogList, false);
                for(Integer i=0;i<srList.size();i++){
                    Database.SaveResult sr = srList[i];
                    if(!sr.isSuccess())C_Log.log(C_Log.Severity.Error, 'Cannot update communication log '+comLogList[i].Id+': '+sr.getErrors()[0].getMessage(), null, 'SMSResponse', null);
                }
            }
            catch(Exception e){
                C_Log.logException(e, 'SMSResponse', null);
            }
            C_Log.setBuffered(prevMode);
        }
    }
    
    /**
     * Constructor used to provide reflection support for the domain
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        /**
         * Creates the SMS responses object using the supplied list of records
         * @param records The records with which to instantiate the domain class
         * @return The domain class
         */
        public fflib_SObjectDomain construct(List<SObject> records){
           return new IRR_DOM_SMSResponses(records);
        }
     }
}
