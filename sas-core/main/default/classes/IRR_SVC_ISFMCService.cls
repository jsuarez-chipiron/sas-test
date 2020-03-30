/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_ISFMCService {
    IRR_SVC_SFMCService.SMSMessage sendSMSMessage(String recipient, String contactKey, String content);
    List<IRR_SVC_SFMCService.SMSMessage> sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages);
}