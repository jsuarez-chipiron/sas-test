public without sharing class CaseService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'death-certificate-dk-da' => 'Form - Death Certificate DK',
    'death-certificate-no-no' => 'Form - Death Certificate NO',
    'death-certificate-se-sv' => 'Form - Death Certificate SE',
    'death-certificate-default' => 'Form - Death Certificate International',
    'visa-rejection-dk-da' => 'Form - Visa Rejection DK',
    'visa-rejection-no-no' => 'Form - Visa Rejection NO',
    'visa-rejection-se-sv' => 'Form - Visa Rejection SE',
    'visa-rejection-default' => 'Form - Visa Rejection International',
    'feedback-dk-da' => 'Form - Feedback DK',
    'feedback-no-no' => 'Form - Feedback NO',
    'feedback-se-sv' => 'Form - Feedback SE',
    'feedback-default' => 'Form - Feedback International'
  };

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'other' => 'Other'
  };

  private static Group refundsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Refunds'
  ];

  private static Group feedbackQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Feedback'
  ];

  public static String createCase(CaseFormJSON2Apex form) {
    if (form.formData.type == 'feedback') {
      Case caseToInsert = new Case(
        Initially_Provided_PNR__c = form.formData.bookingReference,
        Description = form.formData.comment,
        SuppliedEmail = form.formData.email,
        Feedback_Category__c = jsonToPicklist.get(
          form.formData.feedbackCategory
        ),
        Feedback_Type__c = jsonToPicklist.get(form.formData.feedbackType),
        Flight_Date__c = form.formdata.departureDate == null
          ? null
          : Date.valueOf(form.formdata.departureDate),
        Flight_Number__c = form.formdata.flightNumber,
        OwnerId = feedbackQueue.Id,
        RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
        Subject = 'Feedback: ' +
          form.formData.feedbackCategory +
          ', ' +
          form.formData.feedbackType
      );

      String suppliedName;
      if (form.formData.firstName != null) {
        suppliedName = form.formData.firstName;
      }
      if (form.formData.lastName != null) {
        if (suppliedName != null) {
          suppliedName += ' ' + form.formData.lastName;
        } else {
          suppliedName = form.formData.lastName;
        }
      }

      if (suppliedName != null) {
        caseToInsert.SuppliedName = suppliedName;
      }

      String caseOrigin = marketToOrigin.get('feedback-default');
      if (
        marketToOrigin.get(form.formData.type + '-' + form.metaData.market) !=
        null
      ) {
        caseOrigin = marketToOrigin.get(
          form.formData.type +
          '-' +
          form.metaData.market
        );
      }

      caseToInsert.Origin = caseOrigin;

      insert caseToInsert;

      Case insertedCase = [
        SELECT CaseNumber
        FROM Case
        WHERE Id = :caseToInsert.Id
      ];

      return insertedCase.CaseNumber;
    } else {
      ContentVersionsSelector contentVersions = (ContentVersionsSelector) SAS_Service_Application.Selector.newInstance(
        ContentVersion.SObjectType
      );

      Case caseToInsert;

      Set<Id> contentIds = new Set<Id>();

      for (String contentId : form.formData.contentVersionIds) {
        contentIds.add(Id.valueOf(contentId));
      }

      List<ContentVersion> contentToLink = contentVersions.selectById(
        contentIds
      );

      caseToInsert = new Case(
        Initially_Provided_PNR__c = form.formData.bookingReference,
        OwnerId = refundsQueue.Id,
        RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel),
        Subject = 'Waiver request due to ' +
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

      return caseToInsert.CaseNumber;
    }
  }
}
