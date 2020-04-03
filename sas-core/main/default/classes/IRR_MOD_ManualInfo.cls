/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_MOD_ManualInfo {
    @AuraEnabled
    public IRR_MOD_FlowVariables flowVariables;

    @AuraEnabled
    public List<IRR_MOD_PassengerInfo> passengerInfos;

    @AuraEnabled
    public Boolean sendSMSMessages;

    @AuraEnabled
    public Boolean sendEmailMessages;

    @AuraEnabled
    public String emailTemplate;

    @AuraEnabled
    public String smsTemplate;
}