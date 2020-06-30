/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event processor for the manual messages event.
*/

public class IRR_EVT_ManualProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Manual message request is missing';
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
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_EVENT);
        }
        if (manualRequest.passengerInfos == null || manualRequest.passengerInfos.isEmpty()) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_PASSENGERS);
        }
        if (manualRequest.sendEmailMessages != null && manualRequest.sendEmailMessages &&
                String.isBlank(manualRequest.emailTemplate)) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_EMAIL_TEMPLATE);
        }
        if (manualRequest.sendSMSMessages != null && manualRequest.sendSMSMessages &&
                String.isBlank(manualRequest.smsTemplate)) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_SMS_TEMPLATE);
        }
        if (!manualRequest.sendSMSMessages && !manualRequest.sendEmailMessages) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_MESSAGE_TO_SEND);
        }
    }

    public void initiateEvent() {
        if (manualRequest.sendEmailMessages == null) manualRequest.sendEmailMessages = false;
        if (manualRequest.sendSMSMessages == null) manualRequest.sendSMSMessages = false;
        if (manualRequest.responseMessage == null) manualRequest.responseMessage = false;
        if (manualRequest.delayInfo != null && String.isNotBlank(manualRequest.delayInfo.flightId)) {
            IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                    new IRR_SVC_CommunicationService.FlightIdSplit(manualRequest.delayInfo.flightId);
            manualRequest.delayInfo.flightRef = flightIdSplit.flightNumber;
            manualRequest.delayInfo.stationDeparture = flightIdSplit.stationDeparture;
            manualRequest.delayInfo.stationArrival = flightIdSplit.stationArrival;
        }
        if (manualRequest.newInfo != null && String.isNotBlank(manualRequest.newInfo.flightId)) {
            IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                    new IRR_SVC_CommunicationService.FlightIdSplit(manualRequest.newInfo.flightId);
            manualRequest.newInfo.flightRef = flightIdSplit.flightNumber;
            manualRequest.newInfo.stationDeparture = flightIdSplit.stationDeparture;
            manualRequest.newInfo.stationArrival = flightIdSplit.stationArrival;
        }
        if (manualRequest.cancelInfo != null && String.isNotBlank(manualRequest.cancelInfo.flightId)) {
            IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                    new IRR_SVC_CommunicationService.FlightIdSplit(manualRequest.cancelInfo.flightId);
            manualRequest.cancelInfo.flightRef = flightIdSplit.flightNumber;
            manualRequest.cancelInfo.stationDeparture = flightIdSplit.stationDeparture;
            manualRequest.cancelInfo.stationArrival = flightIdSplit.stationArrival;
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Checks if any active manual override blocks exist for this flight.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        //Active blocks are currently not applicable for Manual Message event
        return false;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Process passenger infos and create messages according to event info and passenger contact info.
     */
    public void processEvent() {
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.customInfo = manualRequest.customInfo;
        flowVariables.delayInfo = manualRequest.delayInfo;
        flowVariables.newInfo = manualRequest.newInfo;
        flowVariables.cancelInfo = manualRequest.cancelInfo;
        flowVariables.scheduledChangeInfo = manualRequest.scheduledChangeInfo;

        for (IRR_MOD_PassengerInfo passengerInfo : manualRequest.passengerInfos) {
            Boolean sendEmail = manualRequest.sendEmailMessages;
            Boolean sendSMS = manualRequest.sendSMSMessages;

            if (sendEmail || sendSMS) {
                flowVariables.passengerInfo = passengerInfo;
                createMessages(sendSMS, manualRequest.smsTemplate, sendEmail, manualRequest.emailTemplate,
                        flowVariables, manualRequest.responseMessage);
            }
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