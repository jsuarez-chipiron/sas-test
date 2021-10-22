public class CaseService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'death-certificate-dk-da' => 'Form - Death Certificate DK',
    'death-certificate-no-no' => 'Form - Death Certificate NO',
    'death-certificate-se-sv' => 'Form - Death Certificate SE',
    'death-certificate-default' => 'Form - Death Certificate International',
    'visa-rejection-dk-da' => 'Form - Visa Rejection DK',
    'visa-rejection-no-no' => 'Form - Visa Rejection NO',
    'visa-rejection-se-sv' => 'Form - Visa Rejection SE',
    'visa-rejection-default' => 'Form - Visa Rejection International'
  };

  private static Group refundsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Refunds'
  ];

  public static void createCase(CaseFormJSON2Apex form) {
    ContentVersionsSelector contentVersions = (ContentVersionsSelector) SAS_Service_Application.Selector.newInstance(
      ContentVersion.SObjectType
    );

    Case caseToInsert;

    Set<Id> contentIds = new Set<Id>();

    for (String contentId : form.formData.contentVersionIds) {
      contentIds.add(Id.valueOf(contentId));
    }

    List<ContentVersion> contentToLink = contentVersions.selectById(contentIds);

    caseToInsert = new Case(
      Initially_Provided_PNR__c = form.formData.bookingReference,
      OwnerId = refundsQueue.Id,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
      Subject = 'Waiver request due to' +
        (form.formData.type == 'death-certificate'
          ? 'death in family'
          : 'visa rejection') +
        ', PNR: ' +
        form.formData.bookingReference
    );

    String caseOrigin = marketToOrigin.get('visa-rejection-default');
    if (
      marketToOrigin.get(form.formData.type + '-' + form.metaData.market) !=
      null
    ) {
      caseOrigin = marketToOrigin.get(
        form.formData.type +
        '-' +
        form.metaData.market
      );
    } else if (marketToOrigin.get(form.formData.type + '-default') != null) {
      caseOrigin = marketToOrigin.get(form.formData.type + '-default');
    }

    caseToInsert.Origin = caseOrigin;

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
  }
}
