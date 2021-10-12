public class CaseService {
  public static String createCaseForm(CaseFormJSON2Apex caseForm) {
    ContentVersionsSelector contentVersions = (ContentVersionsSelector) SAS_Service_Application.Selector.newInstance(
      ContentVersion.SObjectType
    );

    Case caseToInsert;
    try {
      CaseFormJSON2Apex.FormData caseFormRequest = caseForm.formData;
      Set<Id> contentIds = new Set<Id>();

      for (String contentId : caseFormRequest.contentVersionIds) {
        contentIds.add(Id.valueOf(contentId));
      }

      List<ContentVersion> contentToLink = contentVersions.selectById(
        contentIds
      );

      caseToInsert = new Case(
        Initially_Provided_PNR__c = caseFormRequest.bookingReference
      );

      insert caseToInsert;

      List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();

      for (ContentVersion content : contentToLink) {
        linksToCreate.add(
          new ContentDocumentLink(
            ContentDocumentId = content.ContentDocumentId,
            LinkedEntityId = caseToInsert.Id
          )
        );
      }

      insert linksToCreate;
    } catch (Exception e) {
      C_Log.logException(e, 'CaseForm', null);
      return e.getMessage();
    }

    return caseToInsert.Id;
  }
}
