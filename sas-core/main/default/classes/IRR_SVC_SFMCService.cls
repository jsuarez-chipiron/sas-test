/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Entry point for SFMC Integration functionality.
*/

public class IRR_SVC_SFMCService {

    public static void sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages) {
        service().sendSMSMessages(messages);
    }

    private static IRR_SVC_ISFMCService service() {
        return (IRR_SVC_ISFMCService) IRR_Application.Service.newInstance(IRR_SVC_ISFMCService.class);
    }

    public class SFMCResponse {
        public List<MessageResponse> responses;
        public Integer errorcode;
        public String message;
        public String requestId;
    }

    public class MessageResponse {
        public String messageKey;
        public Integer errorcode; //The error code in case of an error
        public String message; //The error message in case of an error
    }

    public class SMSMessage {
        public String content;
        public String recipient;
        public String contactKey;
        public String messageKey;
        public String externalId;
        public Integer errorCode; //The error code returned by marketing cloud in case of an error
        public String errorMessage; //The error message returned by marketing cloud in case of an error

        public SMSMessage(String content, String recipient, String contactKey) {
            this.content = content;
            this.recipient = recipient;
            this.contactKey = contactKey;
        }

        public SMSMessage(IRR_MOD_Message message) {
            this.content = message.content;
            this.recipient = message.recipient;
            this.contactKey = message.recipient;
            message.smsMessage = this;
        }
    }

    public class SFMCException extends Exception { }
}