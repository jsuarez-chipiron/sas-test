public class CaseService {
  public static String createCaseForm(CaseFormJSON2Apex caseForm) {
    Case cse;
    try {
      CaseFormJSON2Apex.FormData caseFormRequest = caseForm.formData;
      Id conDocument = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :caseFormRequest.contentVersionId
      ]
      .ContentDocumentId;

      cse = new Case(
        Initially_Provided_PNR__c = caseFormRequest.bookingReference
      );
      insert cse;

      //Insert ContentDocumentLink
      ContentDocumentLink cDocLink = new ContentDocumentLink();
      cDocLink.ContentDocumentId = conDocument; //Add ContentDocumentId
      cDocLink.LinkedEntityId = cse.Id; //Add attachment parentId
      insert cDocLink;
    } catch (Exception e) {
      C_Log.logException(e, 'CaseForm', null);
      return e.getMessage();
    }

    return cse.Id;
  }
}
