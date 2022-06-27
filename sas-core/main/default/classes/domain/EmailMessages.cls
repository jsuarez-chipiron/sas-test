public without sharing class EmailMessages extends fflib_SObjectDomain {
  public EmailMessages(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public static final String STATUS_NEW = '0';
  public static final String STATUS_READ = '1';
  public static final String STATUS_REPLIED = '2';
  public static final String STATUS_SENT = '3';
  public static final String STATUS_FORWARDED = '4';
  public static final String STATUS_DRAFT = '5';

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

  public static Messaging.EmailFileAttachment createEmailAttachmentFromBlob(
    Blob content,
    String fileName,
    String contentType
  ) {
    Messaging.EmailFileAttachment newAttachment = new Messaging.EmailFileAttachment();
    newAttachment.setContentType(contentType);
    newAttachment.setFileName(fileName);
    newAttachment.setInline(false);
    newAttachment.setBody(content);
    return newAttachment;
  }

  public static Messaging.SingleEmailMessage createSingleEmailMessageFromTemplate(
    String templateName,
    Id caseId
  ) {
    List<EmailTemplate> templates = EmailTemplatesSelector.newInstance()
      .selectByName(new Set<String>{ templateName });
    Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();

    if (templates.size() != 1) {
      throw new EmailTemplateNameException();
    }

    emailToSend.setSubject(
      templates[0].Subject +
      ' ' +
      Cases.getThreadId(caseId)
    );
    emailToSend.setHtmlBody(templates[0].HtmlValue);
    emailToSend.setPlainTextBody(templates[0].Body);
    return emailToSend;
  }

  public class EmailTemplateNameException extends Exception {
  }
}
