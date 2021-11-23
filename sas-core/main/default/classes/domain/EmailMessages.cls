public without sharing class EmailMessages extends fflib_SObjectDomain {
  public EmailMessages(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new EmailMessages(records);
    }
  }
  /**
   * Stores value for how long an EmailMessage HTML body can be on incoming messages before it's truncated
   */
  @TestVisible
  private static final Integer ACCEPTED_HTML_LENGTH = Test.isRunningTest()
    ? 10
    : 100000;

  /**
   * Message placed in bottom of email HTML body when truncated
   */
  @TestVisible
  private static final String TRUNCATION_MESSAGE =
    '<p style="background-color: #ff0000"><b>----- Email truncated due to character limit exceeded. ' +
    'For full history, see the email feed on the case. -----</b></p>';

  /**
   * Used to call the trigger in the before insert context
   */
  public override void onBeforeInsert() {
    handleEmailHTMLBodyLength();
  }

  /**
   * Truncates incoming email if the HTML body exceeds the accepted length, and removes
   * truncation message on outgoing emails.
   */
  private void handleEmailHTMLBodyLength() {
    for (EmailMessage msg : (List<EmailMessage>) Records) {
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
}