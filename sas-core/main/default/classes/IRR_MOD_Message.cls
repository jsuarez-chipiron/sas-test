/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Model class for IRR Messages.
*/

public class IRR_MOD_Message {

    public enum MessageChannel {SMS, Email}

    public MessageChannel channel;
    public String status;
    public String template;
    public Map<String, Object> variables;
    public String recipient;
    public String content;
    public IRR_MOD_PassengerInfo passengerInfo;
    public String contactKey;
    public IRR_SVC_SFMCService.SFMCMessage SFMCMessage;
    public String subject;
    public String type;
    public Boolean responseMessage;

    public String messageKey {
        get {
            return SFMCMessage != null ? SFMCMessage.messageKey : '';
        }
    }

    public IRR_MOD_Message() {
        //CONSTRUCTOR INTENTIONALLY LEFT EMPTY
    }

    public IRR_MOD_Message(String status, MessageChannel channel, Map<String, Object> variables, String template,
            IRR_MOD_PassengerInfo passengerInfo, String type, Boolean responseMessage) {
        this.responseMessage = responseMessage;
        this.type = type;
        this.status = status;
        this.channel = channel;
        this.template = template;
        this.variables = variables;
        this.recipient = channel == MessageChannel.SMS ? passengerInfo.phoneNumber.replace('+','') :
                passengerInfo.emailAddress;
        this.contactKey = String.isNotBlank(passengerInfo.emailAddress) ? passengerInfo.emailAddress :
                this.recipient;
        this.passengerInfo = passengerInfo;
    }
}