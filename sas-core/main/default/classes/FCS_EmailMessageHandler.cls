/**
 * @author Anton Norell
 * @date 2020-04-07
 * @description Trigger handler for Email Message object
 */
public with sharing class FCS_EmailMessageHandler extends C_TriggerHandler {
    /**
     * Stores value for how long an EmailMessage HTML body can be on incoming messages before it's truncated
     */
    @TestVisible
    private static Integer ACCEPTED_HTML_LENGTH = 100000;

    /**
     * Message placed in bottom of email HTML body when truncated
     */
    @TestVisible
    private static String TRUNCATION_MESSAGE = '<p style="background-color: #ff0000"><b>----- Email truncated due to character limit exceeded. ' +
        'For full history, see the email feed on the case. -----</b></p>';

    /**
     * Trigger variables
     */
    private Map < Id, EmailMessage > newEmailMap;
    private List < EmailMessage > newEmailList;
    private Map < Id, EmailMessage > oldEmailMap;
    private List < EmailMessage > oldEmailList;

    /**
     * Constructor setting trigger variables
     */
    public FCS_EmailMessageHandler() {
        this.newEmailMap = (Map < Id, EmailMessage > ) Trigger.newMap;
        this.newEmailList = (List < EmailMessage > ) Trigger.new;
        this.oldEmailMap = (Map < Id, EmailMessage > ) Trigger.oldMap;
        this.oldEmailList = (List < EmailMessage > ) Trigger.old;
    }

    /**
     * Used to call the trigger in the before insert context
     */
    public override void beforeInsert() {
        handleEmailHTMLBodyLength();

    }
    public override void AfterInsert() {
        handleForwardEmail();
    }
    /**
     * Truncates incoming email if the HTML body exceeds the accepted length, and removes
     * truncation message on outgoing emails.
     */
    private void handleEmailHTMLBodyLength() {
        if (Test.isRunningTest()) {
            ACCEPTED_HTML_LENGTH = 10;
        }
        for (EmailMessage msg: newEmailList) {
            if (msg.Incoming && msg.HtmlBody != null) {
                Integer bodyLength = msg.HtmlBody.length();
                if (bodyLength > ACCEPTED_HTML_LENGTH) {
                    msg.HtmlBody = msg.HtmlBody.substring(0, ACCEPTED_HTML_LENGTH);
                    msg.HtmlBody = TRUNCATION_MESSAGE + msg.HtmlBody;
                }
            } else if (!msg.Incoming && msg.HtmlBody != null) {
                msg.HtmlBody = msg.HtmlBody.remove(TRUNCATION_MESSAGE);
            }
        }
    }
    private void handleForwardEmail() {
        String threadId;
        List < messaging.SingleEmailMessage > lstSingleEmalMessages = new List < messaging.SingleEmailMessage > ();
        List < EmailMessage > lstDeleteEmailMessage = New List < EmailMessage > ();
        List < EmailServicesAddress > lstEmailtoCaseAddres = new List < EmailServicesAddress > ();
        Map < String, String > mapEmailAddrrstoServiceAdre = new Map < String, String > ();
        lstEmailToCaseAddres = [SELECT
                                Id,
                                DeveloperName,
                                EmailDomainName,
                                FunctionId,
                                IsActive,
                                LocalPart
                                FROM
                                EmailServicesAddress
                                WHERE
                                Function.FunctionName = 'EmailToCase'
                                AND
                                IsActive = true
        ];
        if (!lstEmailToCaseAddres.isEmpty()) {
            for (EmailServicesAddress emailaddr: lstEmailToCaseAddres) {
                mapEmailAddrrstoServiceAdre.put(emailaddr.LocalPart, emailaddr.LocalPart + '@' + emailaddr.EmailDomainName);
            }
        }
        if (Test.isRunningTest()) {
            mapEmailAddrrstoServiceAdre.put('test', 'test@sas.se');
        }
        for (EmailMessage msg: newEmailList) {
            if (msg.TextBody.contains('Forwarded Message')) {
                if (msg.subject.contains('[ ref:') && msg.subject.contains(':ref ]')) {
                    threadId = '[ ref:' + msg.Subject.substringBetween('[ ref:', ':ref ]') + ':ref ]';
                } else if (msg.TextBody.contains('[ ref:') && msg.TextBody.contains(':ref ]')) {
                    threadId = '[ ref:' + msg.TextBody.substringBetween('[ ref:', ':ref ]') + ':ref ]';
                }
                if (threadId != null) {
                    String emailAddrs = msg.ToAddress.substringBefore('@');
                    Messaging.SingleEmailMessage singleEmailMess = new Messaging.SingleEmailMessage();
                    String Subject = msg.Subject.Replace(threadId, '');
                    String TextBody = msg.TextBody.replace(threadId, '');
                    singleEmailMess.subject = Subject;
                    singleEmailMess.PlainTextBody = TextBody;
                    singleEmailMess.toAddresses = new string[] {
                    mapEmailAddrrstoServiceAdre.get(emailAddrs)
                    };
                    lstSingleEmalMessages.add(singleEmailMess);
                    lstDeleteEmailMessage.add(new EmailMessage(Id = msg.Id));
                }

            }

        }
        if (!lstSingleEmalMessages.isEmpty()) {
            Messaging.sendEmail(lstSingleEmalMessages);
            Delete lstDeleteEmailMessage;
        }
    }
}