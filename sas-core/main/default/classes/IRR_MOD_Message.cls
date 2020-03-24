/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Model class for IRR Messages.
*/

public class IRR_MOD_Message {

    public enum MessageType {SMS, Email}

    public MessageType type;
    public String status;
    public String template;
    public Map<String, Object> variables;
    public String recipient;
    public String content;
    public IRR_MOD_PassengerInfo passengerInfo;
    public String contactKey;
    public IRR_SVC_SFMCService.SMSMessage smsMessage;
    public Object emailMessage;
    public String subject;

    public String messageKey {
        get {
            return type == MessageType.SMS && smsMessage != null ? smsMessage.messageKey :
                    emailMessage != null ? 'emailKey' : '';
        }
    }

    public IRR_MOD_Message(String status, MessageType type, Map<String, Object> variables, String template,
            IRR_MOD_PassengerInfo passengerInfo) {
        this.status = status;
        this.type = type;
        this.template = template;
        this.variables = variables;
        this.recipient = type == MessageType.SMS ? passengerInfo.phoneNumber.replace('+','') :
                passengerInfo.emailAddress;
        this.contactKey = String.isNotBlank(passengerInfo.emailAddress) ? passengerInfo.emailAddress :
                this.recipient;
        this.passengerInfo = passengerInfo;
    }
}