/**
 * @author Anton Norell
 * @date 2020-04-07
 * @description Trigger handler for Email Message object
 */
public with sharing class FCS_EmailMessageHandler extends C_TriggerHandler{
    /**
     * Stores value for how long an EmailMessage HTML body can be on incoming messages before it's truncated
     */
    @TestVisible
    private static Integer ACCEPTED_HTML_LENGTH = 100000;

    /**
     * Message placed in bottom of email HTML body when truncated
     */
    @TestVisible
    private static String TRUNCATION_MESSAGE = '<p><b>----- Email truncated due to character limit exceeded. ' +
                                        'For full history, see the email feed on the case. -----</b></p>';

    /**
     * Trigger variables
     */
    private Map<Id, EmailMessage> newEmailMap;
    private List<EmailMessage> newEmailList;
    private Map<Id, EmailMessage> oldEmailMap;
    private List<EmailMessage> oldEmailList;

    /**
     * Constructor setting trigger variables
     */
    public FCS_EmailMessageHandler() {
        this.newEmailMap = (Map<Id, EmailMessage>) Trigger.newMap;
        this.newEmailList = (List <EmailMessage>) Trigger.new;
        this.oldEmailMap = (Map<Id, EmailMessage>) Trigger.oldMap;
        this.oldEmailList = (List <EmailMessage>) Trigger.old;
    }

    /**
     * Used to call the trigger in the before insert context
     */
    public override void beforeInsert() {
        handleEmailHTMLBodyLength();
    }

    /**
     * Truncates incoming email if the HTML body exceeds the accepted length, and removes
     * truncation message on outgoing emails.
     */
    private void handleEmailHTMLBodyLength() {
        if(Test.isRunningTest()){
            ACCEPTED_HTML_LENGTH = 10;
        }
        for(EmailMessage msg:newEmailList){
            if (msg.Incoming && msg.HtmlBody != null) {
                Integer bodyLength = msg.HtmlBody.length();
                if (bodyLength > ACCEPTED_HTML_LENGTH) {
                    msg.HtmlBody = msg.HtmlBody.substring(0, ACCEPTED_HTML_LENGTH);
                    msg.HtmlBody += TRUNCATION_MESSAGE;
                }
            } else if (!msg.Incoming && msg.HtmlBody != null) {
                msg.HtmlBody = msg.HtmlBody.remove(TRUNCATION_MESSAGE);
            }
        }
    }
}