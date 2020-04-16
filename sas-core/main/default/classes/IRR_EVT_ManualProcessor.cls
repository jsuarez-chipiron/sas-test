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
    private IRR_MOD_ManualRequest manualRequest;

    public String getEventName() {
        return 'Manual';
    }

    public void validateEvent() {
        if (manualRequest == null) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_EVENT);
        }
        if (manualRequest.passengerInfos == null || manualRequest.passengerInfos.isEmpty()) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_PASSENGERS);
        }
        if (manualRequest.sendEmailMessages != null && manualRequest.sendEmailMessages &&
                String.isBlank(manualRequest.emailTemplate)) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_EMAIL_TEMPLATE);
        }
        if (manualRequest.sendSMSMessages != null && manualRequest.sendSMSMessages &&
                String.isBlank(manualRequest.smsTemplate)) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_SMS_TEMPLATE);
        }
        if (!manualRequest.sendSMSMessages && !manualRequest.sendEmailMessages) {
            throw new IRR_SVC_EventService.EventException(ERROR_NO_MESSAGE_TO_SEND);
        }
    }

    public void initiateEvent() {
        if (manualRequest.sendEmailMessages == null) manualRequest.sendEmailMessages = false;
        if (manualRequest.sendSMSMessages == null) manualRequest.sendSMSMessages = false;
        if (manualRequest.delayInfo != null && String.isNotBlank(manualRequest.delayInfo.flightId)) {
            List<String> flightIdSplit = manualRequest.delayInfo.flightId.split('-');
            manualRequest.delayInfo.flightRef = flightIdSplit[0];
            manualRequest.delayInfo.stationArrival = flightIdSplit.size() >= 3 ? flightIdSplit[2] : null;
            manualRequest.delayInfo.stationDeparture = flightIdSplit.size() >= 4 ? flightIdSplit[3] : null;
        }
    }

    public void processEvent() {
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.customInfo = manualRequest.customInfo;
        flowVariables.delayInfo = manualRequest.delayInfo;

        for (IRR_MOD_PassengerInfo passengerInfo : manualRequest.passengerInfos) {
            Boolean sendEmail = manualRequest.sendEmailMessages && passengerInfo.hasEmailAddress;
            Boolean sendSMS = manualRequest.sendSMSMessages && passengerInfo.hasPhoneNumber;

            if (sendEmail || sendSMS) {
                flowVariables.passengerInfo = passengerInfo;
                createMessages(sendSMS, manualRequest.smsTemplate, sendEmail, manualRequest.emailTemplate, flowVariables);
            }
        }
    }

    public void finalizeEvent(fflib_ISObjectUnitOfWork uow) {
        if (messages != null && !messages.isEmpty()) {
            insertCommunicationLogs(uow);
        }
    }

    public IRR_EVT_ManualProcessor(IRR_MOD_ManualRequest manualRequest) {
        this.manualRequest = manualRequest;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_ManualProcessor((IRR_MOD_ManualRequest) payload);
        }
    }
}