/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Abstract Event Processor class containing common methods for processing events.
*       Should be extended for each of the events to be processed. Implementations are registered in IRR Application.
*/

public abstract class IRR_EVT_EventProcessor implements IRR_EVT_IEventProcessor {

    private static final String MESSAGE_STATUS_DEFAULT = 'Created';
    private static final String MESSAGE_STATUS_PAUSED = 'Paused';
    private static final String MESSAGE_STATUS_NOT_WHITELISTED = 'Not Whitelisted';

    @TestVisible
    protected List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>();

    @TestVisible
    protected List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();

    @TestVisible
    protected Map<String,String> airportInfoMap = new Map<String,String>();
    Boolean sendIcouponEmailMessage = false;

    abstract String getEventName();

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Renders content for messages in scope using a Renderer initialized with applicable templates.
     */
    private void renderMessages() {
        Set<String> templateNames = new Set<String>();
        for (IRR_MOD_Message message : messages) {
            if (!templateNames.contains(message.template)) {
                templateNames.add(message.template);
            }
        }
        MSG_IRenderer renderer = IRR_Application.MessageRenderer.newInstance(templateNames);
        for (IRR_MOD_Message message : messages) {
            renderer.renderMessage(message);
        }
    }

    private void pauseMessages() {
        //TODO WIP
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Filters messages by changing its status if running in a sandbox and recipient is not on whitelist.
     */
    private void whitelistFilterMessages() {
        Organization org = IRR_SEL_OrganizationSelector.newInstance().selectOrganization();
        if (!org.IsSandbox) return;
        Set<String> whitelistedRecipients = IRR_SEL_RecipientWhitelistSelector.newInstance()
                .getAllWhitelistedRecipients();
        for (IRR_MOD_Message message : messages) {
            if (String.isNotBlank(message.recipient) && !whitelistedRecipients.contains(message.recipient)) {
                message.status = MESSAGE_STATUS_NOT_WHITELISTED;
            }
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description De-duplicates messages in scope.
     */
    protected void deduplicateMessages() {
        List<IRR_MOD_Message> deduplicatedMessages = new List<IRR_MOD_Message>();
        Set<String> recipients = new Set<String>();
        for (IRR_MOD_Message message : messages) {
            if (!recipients.contains(message.recipient)) {
                deduplicatedMessages.add(message);
                recipients.add(message.recipient);
            }
        }
        messages = deduplicatedMessages;
    }

    private void sendMessages() {
        List<IRR_SVC_SFMCService.SMSMessage> SFMCSMSMessages = new List<IRR_SVC_SFMCService.SMSMessage>();
        List<IRR_SVC_SFMCService.EmailMessage> SFMCEmailMessages = new List<IRR_SVC_SFMCService.EmailMessage>();
        for (IRR_MOD_Message message : messages) {
            if (message.status != MESSAGE_STATUS_DEFAULT) continue;
            if (message.channel == IRR_MOD_Message.MessageChannel.SMS) {
                SFMCSMSMessages.add(new IRR_SVC_SFMCService.SMSMessage(message));
            }
            else if (message.channel == IRR_MOD_Message.MessageChannel.Email) {
                SFMCEmailMessages.add(new IRR_SVC_SFMCService.EmailMessage(message));
            }
        }
        System.debug('SEND SMS');
        System.debug(SFMCSMSMessages);
        if (!SFMCSMSMessages.isEmpty()) IRR_SVC_SFMCService.sendSMSMessages(SFMCSMSMessages);
        System.debug('SEND EMAIL');
        System.debug(SFMCEmailMessages);
        if (!SFMCEmailMessages.isEmpty()) IRR_SVC_SFMCService.sendEmailMessages(SFMCEmailMessages);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Processes messages in scope.
     *      - De-duplicates, renders, pauses and sends SMS and Email messages.
     */
    public void processMessages() {
        if (messages == null || messages.isEmpty()) return;
        if(sendIcouponEmailMessage = false) {
            deduplicateMessages();
        }
            renderMessages();
            pauseMessages();
            whitelistFilterMessages();
            sendMessages();
       
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates communication logs for scoped messages, if any.
     *
     * @param uow Unit of Work
     */
    public virtual void finalizeEvent(fflib_ISObjectUnitOfWork uow) {
        if (messages != null && !messages.isEmpty()) {
            insertCommunicationLogs(uow);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates Communication Logs from messages in scope.
     *
     * @param uow Unit of Work
     */
    protected void insertCommunicationLogs(fflib_ISObjectUnitOfWork uow) {
        IRR_SVC_CommunicationService.CommunicationLogFactory logFactory =
                new IRR_SVC_CommunicationService.CommunicationLogFactory(uow);
        for (IRR_MOD_Message message : messages) {
            logFactory.add(message);
        }
    }

    //Dummy flow input map
    private static final Map<String, Object> flowMap = new Map<String, Object>();

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Instantiates a flow and executes it with parameters passenger and eventParams.
     *      - Send Message Boolean variables are set to true if there are available contact details.
     *      - Result templates and sendMessage Boolean variables are picked up
     *      - Message objects are created if FLow sendMessage variables output true and a template is set
     *
     * @param flowName Name of Flow to execute
     * @param flowVariables Variables to use in Flow
     */
    protected void executeFlow(String flowName, IRR_MOD_FlowVariables flowVariables) {

        IRR_ACT_StaticInput.actionOutput = flowVariables;
        Flow.Interview interview = Flow.Interview.createInterview(flowName, flowMap);
        interview.start();

      String emailTemplateName = (String) interview.getVariableValue('emailTemplateName');
        Boolean sendEmailMessage = (Boolean) interview.getVariableValue('sendEmailMessage');
        sendEmailMessage = sendEmailMessage == null || String.isBlank(emailTemplateName) ? false : sendEmailMessage;

        String smsTemplateName = (String) interview.getVariableValue('smsTemplateName');
        Boolean sendSMSMessage = (Boolean) interview.getVariableValue('sendSMSMessage');
        sendSMSMessage = sendSMSMessage == null || String.isBlank(smsTemplateName) ? false : sendSMSMessage;

        ///Added By Gaurav 
         String iCouponEmailTemplateName = (String) interview.getVariableValue('IcouponEmailTemplateName');
         sendIcouponEmailMessage = (Boolean) interview.getVariableValue('sendIcouponEmailMessage');
         sendIcouponEmailMessage = sendIcouponEmailMessage == null || String.isBlank(iCouponEmailTemplateName) ? false : sendIcouponEmailMessage;

        String iCouponSmsTemplateName = (String) interview.getVariableValue('IcouponSMSTemplateName');
        Boolean sendIcoupnSMSMessage = (Boolean) interview.getVariableValue('sendIcouponSMSMessage');
        sendIcoupnSMSMessage = sendIcoupnSMSMessage == null || String.isBlank(iCouponSmsTemplateName) ? false : sendIcoupnSMSMessage;
      if (sendSMSMessage || sendEmailMessage  ){
          
        
        createMessages(sendSMSMessage, smsTemplateName, sendEmailMessage, emailTemplateName, flowVariables, false);
        }
     
        if (sendIcoupnSMSMessage || sendIcouponEmailMessage ){
            
        createMessages(sendIcoupnSMSMessage, iCouponSmsTemplateName, sendIcouponEmailMessage,iCouponEmailTemplateName, flowVariables, false);
        }

    }

    protected void createMessages(Boolean sendSMS, String SMSTemplate, Boolean sendEmail, String emailTemplate,
            IRR_MOD_FlowVariables flowVariables, Boolean responseMessage) {
        String serializedVariables = JSON.serialize(flowVariables);
        System.debug('flowVariables:' +flowVariables);
        Map<String, Object> templateParams =new Map<String, Object>();
               templateParams = (Map<String,Object>) JSON.deserializeUntyped(serializedVariables);

        if (sendSMS) {
            IRR_MOD_Message smsMessage = new IRR_MOD_Message(MESSAGE_STATUS_DEFAULT, IRR_MOD_Message.MessageChannel.SMS,
                    templateParams, SMSTemplate, flowVariables.passengerInfo, getEventName(), responseMessage);
            messages.add(smsMessage);
            //system.debug('test ' + Integer.valueOf('tes'));
        }
        if (sendEmail) {
            IRR_MOD_Message emailMessage = new IRR_MOD_Message(MESSAGE_STATUS_DEFAULT, IRR_MOD_Message.MessageChannel.Email,
                    templateParams,emailTemplate, flowVariables.passengerInfo, getEventName(), responseMessage);
            messages.add(emailMessage);
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Throws a formatted Event Exception.
     *
     * @param errorString Error message template string
     * @param eventInfo Object to serialize into the message template
     */
    protected void throwEventException(String errorString, Object eventInfo) {
        throw new IRR_SVC_CommunicationService.EventException(
                String.format(errorString, new List<String>{
                        eventInfo.toString()
                }));
    }

    public interface IConstructable {
        IRR_EVT_IEventProcessor newInstance(Object eventInfo);
    }
}