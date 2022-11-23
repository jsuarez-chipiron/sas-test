public with sharing class SendEmailForReadOnlyCase {
  @InvocableMethod(label='Send template email')
  public static void sendEmail(List<Id> caseIds) {
    String closedCasePermanentlyTemplate = 'permanent-case-closure';
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Messaging.SingleEmailMessage msg = EmailMessages.createSingleEmailMessageFromTemplate(
      closedCasePermanentlyTemplate,
      caseIds[0]
    );
    msg.SetReplyTo('no-reply@flysas.com');
    Cases.newInstance(
        CasesSelector.newInstance().selectById(new Set<Id>{ caseIds[0] })
      )
      .emailOwner(msg, uow);

    uow.commitWork();
  }
}
