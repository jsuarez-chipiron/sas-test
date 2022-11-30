public with sharing class SendEmailForReadOnlyCase {
  @InvocableMethod(label='Send template email')
  public static void sendEmail(List<Id> caseIds) {
    List<Case> allCases = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseIds[0] });
    String closedCasePermanentlyTemplate = EmailMessages.departmentToTemplateName.get(
      allCases[0].Department__c
    );
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Messaging.SingleEmailMessage msg = EmailMessages.createSingleEmailMessageFromTemplate(
      closedCasePermanentlyTemplate,
      caseIds[0]
    );
    msg.SetReplyTo('no-reply@flysas.com');
    Cases.newInstance(allCases).emailOwner(msg, uow);

    uow.commitWork();
  }
}
