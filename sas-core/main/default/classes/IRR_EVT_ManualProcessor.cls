/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event processor for the manual messages event.
*/

public class IRR_EVT_ManualProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Manual message info is missing';
    private static final String ERROR_NO_PASSENGERS = 'No passengers to send message to';
    private static final String ERROR_NO_EMAIL_TEMPLATE = 'No Email template selected';
    private static final String ERROR_NO_SMS_TEMPLATE = 'No SMS template selected';
    private static final String ERROR_NO_MESSAGE_TO_SEND = 'There is no message to send';

    @TestVisible
    private IRR_MOD_ManualInfo manualInfo;

    public String getEventName() {
        return 'Manual';
    }

    public void validateEvent() {
        if (manualInfo == null) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_EVENT);
        }
        if (manualInfo.passengerInfos == null || manualInfo.passengerInfos.isEmpty()) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_PASSENGERS);
        }
        if (manualInfo.sendEmailMessages != null && manualInfo.sendEmailMessages &&
                String.isBlank(manualInfo.emailTemplate)) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_EMAIL_TEMPLATE);
        }
        if (manualInfo.sendSMSMessages != null && manualInfo.sendSMSMessages &&
                String.isBlank(manualInfo.smsTemplate)) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_SMS_TEMPLATE);
        }
        if (!manualInfo.sendSMSMessages && !manualInfo.sendEmailMessages) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_MESSAGE_TO_SEND);
        }
    }

    public void initiateEvent() {
        if (manualInfo.sendEmailMessages == null) manualInfo.sendEmailMessages = false;
        if (manualInfo.sendSMSMessages == null) manualInfo.sendSMSMessages = false;
    }

    public void processEvent() {
        IRR_MOD_FlowVariables flowVariables = manualInfo.flowVariables;

        for (IRR_MOD_PassengerInfo passengerInfo : manualInfo.passengerInfos) {
            Boolean sendEmail = manualInfo.sendEmailMessages && passengerInfo.hasEmailAddress;
            Boolean sendSMS = manualInfo.sendSMSMessages && passengerInfo.hasPhoneNumber;

            if (sendEmail || sendSMS) {
                flowVariables.passengerInfo = passengerInfo;
                createMessages(sendSMS, manualInfo.smsTemplate, sendEmail, manualInfo.emailTemplate, flowVariables);
            }
        }
    }

    public void finalizeEvent(fflib_ISObjectUnitOfWork uow) {
        if (messages != null && !messages.isEmpty()) {
            insertCommunicationLogs(uow);
        }
    }

    public IRR_EVT_ManualProcessor(IRR_MOD_ManualInfo manualInfo) {
        this.manualInfo = manualInfo;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_ManualProcessor((IRR_MOD_ManualInfo) payload);
        }
    }
}