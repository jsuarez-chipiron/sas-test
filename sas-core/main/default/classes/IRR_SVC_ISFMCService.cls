/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_ISFMCService {
    void sendSMSMessage(String recipient, String contactKey, String content);
    void sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages);
}