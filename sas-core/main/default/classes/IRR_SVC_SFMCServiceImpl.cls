/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Concrete implementation of SFMC integration functionality.
*/

public class IRR_SVC_SFMCServiceImpl implements IRR_SVC_ISFMCService {

    private static final String SMS_ENDPOINT = '/messaging/v1/sms/messages/';
    private static final String EMAIL_ENDPOINT; //TODO WIP

    private static final String NAMED_CREDENTIAL = 'callout:SAS_MC_API';
    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .build();
            }
            return integrationExecutor;
        }
        private set;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sorts messages by send definition country prefix and then makes individual calls to SFMC for each
     *      send definition.
     *
     * @param messages SMS Message list to send
     */
    public List<IRR_SVC_SFMCService.SMSMessage> sendSMSMessages(List<IRR_SVC_SFMCService.SMSMessage> messages) {
        Map<String, List<IRR_SVC_SFMCService.SMSMessage>> smsMessagesBySendDefinitions =
                sortMessagesBySendDefinitions(messages);
        for (String definition : smsMessagesBySendDefinitions.keySet()) {
            List<IRR_SVC_SFMCService.SMSMessage> scopedMessages = smsMessagesBySendDefinitions.get(definition);
            Map<String, Object> requestBody = createSMSRequestBody(definition, scopedMessages);

            String responseString = integrationExecutor.executeRequest(
                    SMS_ENDPOINT, C_IntegrationExecutor.Method.POST, requestBody, null);

            IRR_SVC_SFMCService.SFMCResponse response = (IRR_SVC_SFMCService.SFMCResponse)
                    JSON.deserialize(responseString, IRR_SVC_SFMCService.SFMCResponse.class);
            Integer responsesSize = response.responses != null && !response.responses.isEmpty() ?
                    response.responses.size() : 0;

            for (Integer i = 0; i < responsesSize; i++) {
                IRR_SVC_SFMCService.MessageResponse messageResponse = response.responses[i];
                scopedMessages[i].messageKey = messageResponse.messageKey;
                scopedMessages[i].errorCode = messageResponse.errorcode;
                if(messageResponse.errorcode!=null && messageResponse.errorcode!=0)scopedMessages[i].errorMessage = messageResponse.message;
            }
        }
        return messages;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Sorts messages by send definition country prefix based on phone number.
     *
     * @param messages Messages to process
     *
     * @return Map of SMS Messages by send definition key
     */
    private Map<String, List<IRR_SVC_SFMCService.SMSMessage>> sortMessagesBySendDefinitions(
            List<IRR_SVC_SFMCService.SMSMessage> messages) {
        if (smsDefinitionsCache == null) retrieveSMSDefinitions();
        Map<String, List<IRR_SVC_SFMCService.SMSMessage>> smsMessagesBySendDefinitions =
                new Map<String, List<IRR_SVC_SFMCService.SMSMessage>>();
        for (IRR_SVC_SFMCService.SMSMessage message : messages) {
            for (String code : smsDefinitionsCache.keySet()) {
                if (code != null && !message.recipient.startsWith(code)) continue;
                String definition = smsDefinitionsCache.get(code);
                if (!smsMessagesBySendDefinitions.containsKey(definition)) {
                    smsMessagesBySendDefinitions.put(definition, new List<IRR_SVC_SFMCService.SMSMessage>());
                }
                smsMessagesBySendDefinitions.get(definition).add(message);
                break;
            }
        }
        return smsMessagesBySendDefinitions;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves SMS send definitions and stores them by Country Prefix in a local cache map.
     */
    private void retrieveSMSDefinitions() {
        smsDefinitionsCache = new Map<String, String>();
        List<SFMC_SMSDefinition__mdt> smsDefinitions = IRR_SEL_SMSDefinitionsSelector.newInstance()
                .getAllSMSDefinitions();
        for (SFMC_SMSDefinition__mdt definition : smsDefinitions) {
            smsDefinitionsCache.put(definition.SFMC_CountryPrefix__c, definition.SFMC_DefinitionKey__c);
        }
    }

    /*
     * Cache Map of SMS Send definition keys by Country Prefix
     */
    private static Map<String, String> smsDefinitionsCache;

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates SFMC request body structure for a send definition and a list of SMS Messages.
     *
     * @param sendDefinition SFMC Send Definition key
     * @param messages List of SMS Messages
     *
     * @return SFMC Request body structure
     */
    private Map<String, Object> createSMSRequestBody(String sendDefinition,
            List<IRR_SVC_SFMCService.SMSMessage> messages) {
        List<Map<String, Object>> recipients = new List<Map<String, Object>>();
        for (IRR_SVC_SFMCService.SMSMessage smsMessage : messages) {
            Map<String, Object> recipient = new Map<String, Object> {
                    'to' => smsMessage.recipient,
                    'contactKey' => smsMessage.contactKey,
                    'attributes' => new Map<String, Object> {
                            'message' => smsMessage.content
                    }
            };
            recipients.add(recipient);
        }
        Map<String, Object> requestBody = new Map<String, Object>{
                'definitionKey' => sendDefinition,
                'recipients' => recipients,
                'content' => new Map<String, Object> { 'message' => '%%message%%' },
                'subscriptions' => new Map<String, Object> { 'resubscribe' => true }
        };
        return requestBody;
    }
}