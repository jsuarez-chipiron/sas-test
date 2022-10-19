public with sharing class SendEmailForReadOnlyCase {
  @InvocableMethod(label='Send template email')
  public static void sendEmailForReadOnlyCase(List<Id> caseIds) {
    String closedCasePermanentlyTemplate = 'permanent-case-closure';
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Messaging.SingleEmailMessage msg = EmailMessages.createSingleEmailMessageFromTemplate(
      closedCasePermanentlyTemplate,
      caseIds[0]
    );
    List<Case> associatedCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseIds[0] });
    msg.Subject = msg.getSubject()
      .replace('{{{Case.CaseNumber}}}', associatedCase[0].CaseNumber);
    msg.HtmlBody = msg.getHtmlBody()
      .replace('{{{Case.CaseNumber}}}', associatedCase[0].CaseNumber);
    msg.SetReplyTo('no-reply@flysas.com');
    Cases.newInstance(associatedCase).emailOwner(msg, uow);

    uow.commitWork();
  }
}
