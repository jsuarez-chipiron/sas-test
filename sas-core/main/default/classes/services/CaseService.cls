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
    'airport-experience' => 'Airport experience',
    'baggage' => 'Baggage',
    'baggage-damaged' => 'Baggage damaged',
    'baggage-delayed' => 'Baggage delayed/lost',
    'booking' => 'Booking',
    'booking-error' => 'Booking error',
    'cabin-environment' => 'Cabin environment',
    'denied-boarding' => 'Denied boarding',
    'downgrading' => 'Downgrading',
    'extra-baggage' => 'Extra baggage',
    'flight-cancellation' => 'Flight cancellation',
    'flight-delay' => 'Flight delay',
    'flight-disruptions' => 'Flight disruptions',
    'flight-experience' => 'Flight experience',
    'gate-issues' => 'Gate issues',
    'general' => 'General',
    'in-flight-meal' => 'In-flight meal',
    'in-flight-service' => 'In-flight service',
    'lounge' => 'Lounge',
    'meals-drinks' => 'Meals/Drinks',
    'missed-connection' => 'Missed connection',
    'other' => 'Other',
    'prepaid-seat' => 'Prepaid seat',
    'refund' => 'Refund',
    'regression' => 'Regression',
    'special-assistance' => 'Special assistance',
    'travel-document-control' => 'Travel document control',
    'travel-extras' => 'Travel extras',
    'wifi' => 'WiFi'
  };

  private static Group refundsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Refunds'
  ];

  private static Group feedbackQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Customer_Claim'
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
        Flight_Date__c = String.isBlank(form.formdata.departureDate)
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
      if (!String.isBlank(form.formData.firstName)) {
        suppliedName = form.formData.firstName;
      }
      if (!String.isBlank(form.formData.lastName)) {
        if (suppliedName != null) {
          suppliedName += ' ' + form.formData.lastName;
        } else {
          suppliedName = form.formData.lastName;
        }
      }

      if (!String.isBlank(suppliedName)) {
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

      Database.DMLOptions DMLOptions = new Database.DMLOptions();
      DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

      database.insert(caseToInsert, DMLOptions);

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
        if (!String.isBlank(contentId)) {
          contentIds.add(Id.valueOf(contentId));
        }
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

      Case insertedCase = [
        SELECT CaseNumber
        FROM Case
        WHERE Id = :caseToInsert.Id
      ];

      return insertedCase.CaseNumber;
    }
  }

  /**
   * Creates a support case for the given case.
   *
   * @param department To which department the case should be created to.
   * @param team To which team within the department the case should be created to.
   * @param caseToCreate The case object which is to be created. No fields need to be set by default.
   * @param parentCaseId Id of the case for which this support case is created.
   * @param uow Unit of work instance with which the case should be created.
   */
  public static void createSupportCase(
    String department,
    String team,
    Case caseToCreate,
    Id parentCaseId,
    fflib_ISObjectUnitOfWork uow
  ) {
    caseToCreate.Department__c = department;
    caseToCreate.Team__c = team;
    caseToCreate.Origin = 'Internal - Support';
    caseToCreate.ParentId = parentCaseId;
    caseToCreate.OwnerId = GroupsSelector.newInstance()
        .selectQueuesByDepartment(new Set<String>{ department })[0]
      .Id;
    if (caseToCreate.RecordTypeId == null) {
      // If no record type is set, default to department's default record type.
      caseToCreate.RecordTypeId = Cases.getRecordTypeId(
        Cases.defaultRecordTypeForDepartment.get(department)
      );
    }

    uow.registerNew(caseToCreate);

    Case parentCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ parentCaseId })[0];

    parentCase.Created_Support_Case__c = true;
    uow.registerDirty(parentCase);
  }

  public class AssignPriorityAndRouteToQueueAsync implements Queueable, Database.AllowsCallouts {
    private Set<Id> caseIds;
    public AssignPriorityAndRouteToQueueAsync(Set<Id> caseIds) {
      this.caseIds = caseIds;
    }
    public void execute(QueueableContext ctx) {
      assignPriorityAndRouteToQueue(this.caseIds);
    }
  }

  /**
   * Cases with Customers with Diamond and Gold EB-level should have "high" priority.
   * Cases get routeAndPrioritized to a queue depending on their claim type.
   *
   * Special cases:
   * 1. Pandion customers have their own queue.
   * 2. Claims with high care costs have a special queue as we quickly want to
   *    compensate customers who might have been put in a difficult economical situation.
   */
  public static void assignPriorityAndRouteToQueue(Set<Id> caseIds) {
    List<Case> casesToSortThrough = CasesSelector.newInstance()
      .selectById(caseIds);

    Map<Id, Case> claimIdToCase = new Map<Id, Case>{};
    for (Case c : casesToSortThrough) {
      if (c.LIA_Claim__c != null) {
        claimIdToCase.put(c.LIA_Claim__c, c);
      } else {
        return;
      }
    }

    List<LIA_Claim__c> caseClaims = ClaimsSelector.newInstance()
      .selectByIdWithCustomers(claimIdToCase.keySet());

    List<Case> casesToRoute = new List<Case>{};
    for (LIA_Claim__c cl : caseClaims) {
      Case c = claimIdToCase.get(cl.Id); // Do we want to route compensationcards this way? @Jesús
      if (
        (cl.RecordTypeId ==
        Claim.getRecordTypeIdByEnum(Claim.RecordType.CustomerClaim) &&
        String.valueOf(c.OwnerId).substring(0, 3) == '00G') ||
        cl.RecordTypeId ==
        Claim.getRecordTypeIdByEnum(Claim.RecordType.CompensationCard)
      ) {
        casesToRoute.add(c);
      }
    }

    if (casesToRoute.size() == 0) {
      return;
    }

    Set<String> groupNames = new Set<String>{
      'Claims - EU261',
      'Claims - Care Expenses',
      'Claims - High Priority',
      'Claims - High Care Costs',
      'Claims - Flight Disruptions',
      'Claims - Flight Disruptions Expenses',
      'Claims - Compensation Card',
      'Claims - Baggage',
      'Claims - Other'
    };

    List<Group> queues = GroupsSelector.newInstance()
      .selectGroupsByName(groupNames);

    Integer casesRemaining = casesToRoute.size();
    while (casesRemaining > 0) {
      if (casesRemaining > 250) {
        List<Case> notAllCases = new List<Case>{};
        for (Integer i = 0; i < 250; i++) {
          notAllCases.add(casesToRoute[0]);
          casesToRoute.remove(0);
        }
        casesRemaining = casesToRoute.size();
        routeCases(notAllCases, queues);
      } else {
        routeCases(casesToRoute, queues);
        casesRemaining = 0;
      }
    }
  }

  private static void routeCases(List<Case> casesToRoute, List<Group> queues) {
    Map<String, List<SObject>> params = new Map<String, List<SObject>>{
      'Cases' => casesToRoute,
      'Groups' => queues
    };
    Flow.Interview.CASE_Route_And_Set_Priority routeAndPrioritize = new Flow.Interview.CASE_Route_And_Set_Priority(
      params
    );
    routeAndPrioritize.start();
  }
  public static void createChatterPost(
    List<Case> casesToPost,
    String feedItemBody,
    fflib_ISObjectUnitOfWork uow
  ) {
    List<FeedItem> toCreate = new List<FeedItem>();
    for (Case c : casesToPost) {
      FeedItem fi = new FeedItem(
        ParentId = c.Id,
        Body = feedItemBody,
        Type = 'TextPost'
      );
      toCreate.add(fi);
    }
    uow.registerNew(toCreate);
  }
}
