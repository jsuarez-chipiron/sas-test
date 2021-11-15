/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description Handler class for operations performed on case object.
 */
public class FCS_CaseHandler extends C_TriggerHandler {
  /**
    Static variable for the Case Tag type Main
    */
  @TestVisible
  private static final String MAIN_TAG = 'Main';
  /**
   Static variable for the Case Tag type Sub
   */
  @TestVisible
  private static final String SUB_MAIN_TAG = 'Sub';
  /**
   Static variable for the Case Tag type Additional
   */
  @TestVisible
  private static final String ADDITIONAL_TAG = 'Additional';
  /**
    Static variable for the Social Post review status "Reviewed"
    */
  @TestVisible
  private static final String SP_STATUS_REVIEWED = 'Reviewed';
  /**
   Static variable for the Case status "Closed"
   */
  @TestVisible
  private static final String CASE_STATUS_CLOSED = 'Closed';

  static CasesSelector cases = (CasesSelector) SAS_Service_Application.Selector.newInstance(
    Case.SObjectType
  );

  /**
    Trigger variables
    */
  private Map<Id, Case> newCaseMap;
  private List<Case> newCaseList;
  private Map<Id, Case> oldCaseMap;
  private List<Case> oldCaseList;
  /**
   Set variables
   */
  public FCS_CaseHandler() {
    this.newCaseMap = (Map<Id, Case>) Trigger.newMap;
    this.newCaseList = (List<Case>) Trigger.new;
    this.oldCaseMap = (Map<Id, Case>) Trigger.oldMap;
    this.oldCaseList = (List<Case>) Trigger.old;
  }
  /**
   Used to call the trigger in the before insert context
   */
  public override void beforeInsert() {
    assignOwnerFromSoMe(newCaseList);
    validateCaseTags(newCaseList);
    enrichCaseDataBasedOnOrigin(newCaseList);
    enrichCaseTagData(newCaseList);
    enrichMissingPointsCaseDataWithMissingPointsFormData(newCaseList);
    // tryToAssignExistingEBAccountToCase(newCaseList);
  }
  /**
  Used to call the trigger in the before update context
  */
  public override void beforeUpdate() {
    validateCaseTags(newCaseList);
    completeMilestones(newCaseMap);
    enrichCaseTagData(newCaseList);
  }
  /**
   Used to call the trigger in the after insert context
   */
  public override void afterInsert() {
    manageCaseTagRecords(newCaseList, newCaseMap);
    updateSocialPost(newCaseList);
    updateBookingsForNewAssociatedAccounts(newCaseList);
    createCaseToBookings(newCaseList);
    // tryToFetchEBAccountFromCODS(newCaseList);
  }

  /**
    Used to call the trigger in the after update context
    */
  public override void afterUpdate() {
    manageCaseTagRecords(newCaseList, newCaseMap);
    updateBookingsForNewAssociatedAccounts(newCaseList, oldCaseList);
  }

  /**
    Used to call the trigger in the after delete context
    */
  public override void afterDelete() {
    //Make sure that related Survey Invitations are deleted upon case deletion
    delete [
      SELECT Id
      FROM SurveyInvitation
      WHERE FCS_RelatedCase__c IN :oldCaseMap.keySet()
    ];
  }

  /**
   * Updates case fields based on Origin of the Case. The Enrich_Case_Based_On_Origin_Config__mdt
   * custom metadata type is used to defined what data to assign based on Origin.
   *
   * Should be run only on beforeInsert.
   */
  private static void enrichCaseDataBasedOnOrigin(List<Case> newCaseList) {
    List<Entitlement> entitlements = [
      SELECT Name, Id
      FROM Entitlement
      WHERE Type = 'Vendor'
    ];
    Entitlement refundsEntitlement = null;

    for (Entitlement e : entitlements) {
      if (e.Name == 'Refunds BOM') {
        refundsEntitlement = e;
      }
    }

    for (Case c : newCaseList) {
      List<Enrich_Case_Based_On_Origin_Config__mdt> enrichmentData = [
        SELECT
          Department_To_Assign__c,
          Entitlement_To_Assign__c,
          Team_To_Assign__c,
          Case_Type_To_Assign__c
        FROM Enrich_Case_Based_On_Origin_Config__mdt
        WHERE Incoming_Case_Origin__c = :c.Origin
      ];

      if (!enrichmentData.isEmpty()) {
        // A configuration was found for this Origin
        Enrich_Case_Based_On_Origin_Config__mdt caseConfiguration = enrichmentData[0];

        // Fill in fields only if they have a value set in the config
        if (!String.isEmpty(caseConfiguration.Case_Type_To_Assign__c)) {
          c.Type = caseConfiguration.Case_Type_To_Assign__c;
        }

        if (!String.isEmpty(caseConfiguration.Department_To_Assign__c)) {
          c.Department__c = caseConfiguration.Department_To_Assign__c;
        }

        if (!String.isEmpty(caseConfiguration.Team_To_Assign__c)) {
          c.Team__c = caseConfiguration.Team_To_Assign__c;
        }

        if (!String.isEmpty(caseConfiguration.Entitlement_To_Assign__c)) {
          for (Entitlement e : entitlements) {
            if (e.Name == caseConfiguration.Entitlement_To_Assign__c) {
              c.EntitlementId = e.Id;
            }
          }
        }
      }

      if (c.Origin == 'Internal - New Refund Request Form') {
        // Special handling for cases created by Refund Request Form.
        // It seems to be impossible to add entitlements in flows, and we cannot set them
        // for refunds requests purely based on case origin, so we have this.
        // TODO: Get rid of this special case and somehow manage these normally.

        if (
          !String.isEmpty(c.Team__c) &&
          c.Team__c.startsWith('BOM') &&
          refundsEntitlement != null
        ) {
          c.EntitlementId = refundsEntitlement.Id;
        }
      }
    }
  }

  /**
   * Completes all milestones of a case when case status changes to one in statusesThatCompleteMilestones.
   */
  private static void completeMilestones(Map<Id, Case> newCaseMap) {
    List<String> statusesThatCompleteMilestones = new List<String>{
      'Awaiting Customer Response',
      'Closed',
      'Escalated',
      'Merged',
      'On Hold'
    };

    List<CaseMilestone> milestonesOfCases = [
      SELECT CaseId, CompletionDate, Id
      FROM CaseMilestone
      WHERE CaseId IN :newCaseMap.keySet() AND IsCompleted = FALSE
    ];

    List<CaseMilestone> milestonesToComplete = new List<CaseMilestone>();

    for (CaseMilestone milestone : milestonesOfCases) {
      if (
        statusesThatCompleteMilestones.contains(
          newCaseMap.get(milestone.CaseId).Status
        )
      ) {
        milestone.CompletionDate = DateTime.now();
        milestonesToComplete.add(milestone);
      }
    }

    update milestonesToComplete;
  }

  /**
   * Checks if format of mailaddress provided is correct, if yes it returns the mail address provided else
   * returns null
   */
  private static Boolean isEmailAddress(String emailAddress) {
    if (emailAddress == null) {
      return false;
    }

    Pattern emailPattern = Pattern.compile(
      '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})'
    );
    Matcher emailMatcher = emailPattern.matcher(emailAddress);

    return emailMatcher.matches();
  }

  /**
   * Enrich Missing Points EB case with data received from form
   * Provided tat criteria is met.
   */
  private static void enrichMissingPointsCaseDataWithMissingPointsFormData(
    List<Case> newCaseList
  ) {
    /* List emailSubjectKeywords and formFromEmailAddress are Used as part of verification to check if email comes from form */
    String emailSubjectKeyword = 'flight retro';
    List<String> formSentFromEmailAddress = new List<String>{
      'noreply@flysas.com',
      'salesforce_uat5@sas.se',
      'madis.tepp@sas.se'
    };
    List<String> ebTierLevels = new List<String>{
      'pandion',
      'diamond',
      'basic',
      'silver',
      'gold'
    };

    for (Case c : newCaseList) {
      Boolean comesFromForm =
        c.Subject != null &&
        c.Subject.toLowercase().Contains(emailSubjectKeyword) &&
        formSentFromEmailAddress.contains(c.SuppliedEmail);

      if (comesFromForm) {
        if (c.Description != '' && c.Description.length() > 0) {
          String data = c.Description;

          String memberEmailFromForm = data.substringBetween(
            'member-email: ',
            '\n'
          );

          if (isEmailAddress(memberEmailFromForm)) {
            c.SuppliedEmail = memberEmailFromForm;
          }

          String ebLevel = data.substringBetween('eurobonus-level: ', '\n');
          if (ebLevel != null && ebTierLevels.contains(ebLevel)) {
            c.FCS_EBLevel__c = ebLevel.substring(0, 1);
          }

          String numberOfFlightData = data.substringBetween(
            'number-of-flights: ',
            '\n'
          );
          Integer numberOfFlights = null;
          try {
            numberOfFlights = Integer.valueOf(numberOfFlightData);
          } catch (Exception e) {
            numberOfFlights = 0;
          }

          for (Integer i = 1; i <= numberOfFlights; i++) {
            String airline = data.substringBetween(
              'flight-' +
              i +
              '-airline:',
              '\n'
            );
            String description = data.substringBetween(
              'flight-' +
              i +
              '-description:',
              '\n'
            );
            String flightNo = data.substringBetween(
              'flight-' +
              i +
              '-flight-no:',
              '\n'
            );
            String ticketNo = data.substringBetween(
              'flight-' +
              i +
              '-ticket-no:',
              '\n'
            );
            String departureDate = data.substringBetween(
              'flight-' +
              i +
              '-departure-date:',
              '\n'
            );
            String departure = data.substringBetween(
              'flight-' +
              i +
              '-departure:',
              '\n'
            );
            String arrival = data.substringBetween(
              'flight-' +
              i +
              '-arrival:',
              '\n'
            );
            String firstName = data.substringBetween(
              'flight-' +
              i +
              '-ticket-first-name:',
              '\n'
            );
            String lastName = data.substringBetween(
              'flight-' +
              i +
              '-ticket-last-name:',
              '\n'
            );
            String bookingClass = data.substringBetween(
              'flight-' +
              i +
              '-booking-class:',
              '\n'
            );
            String boardingNumber = data.substringBetween(
              'flight-' +
              i +
              '-boarding-number:',
              '\n'
            );
            String seatNumber = data.substringBetween(
              'flight-' +
              i +
              '-seat-number:',
              '\n'
            );

            c.put(
              'Flight_Info_Missing_Points_X' +
              i +
              '__c',
              '<b>Airline</b> : ' +
              airline +
              '<br/>' +
              '<b>Description</b> : ' +
              description +
              '<br/>' +
              '<b>Flight Nr</b> : ' +
              flightNo +
              '<br/>' +
              '<b>Ticket Nr</b> : ' +
              ticketNo +
              '<br/>' +
              '<b>Departure Date</b> : ' +
              departureDate +
              '<br/>' +
              '<b>Departure</b> : ' +
              departure +
              '<br/>' +
              '<b>Arrival</b> : ' +
              arrival +
              '<br/>' +
              '<b>First Name</b> : ' +
              firstName +
              '<br/>' +
              '<b>Last Name</b> : ' +
              lastName +
              '<br/>' +
              '<b>Booking Class</b> : ' +
              bookingClass +
              '<br/>' +
              '<b>Boarding Number</b> : ' +
              boardingNumber +
              '<br/>' +
              '<b>Seat Number</b> : ' +
              seatNumber +
              '<br/>'
            );
          }
        }
      }
    }
  }

  /**
    Method to set owner on case created from SoMe-post quick actions
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
  private static void assignOwnerFromSoMe(List<Case> newCaseList) {
    Set<Id> socialPostIds = new Set<Id>();
    List<Case> caseInScope = new List<Case>();
    for (Case c : newCaseList) {
      Boolean infoTag =
        (c.Origin == 'Facebook' || c.Origin == 'Twitter') &&
        (c.SourceId != null &&
        c.SourceId.getSOBjectType() == SocialPost.SObjectType &&
        c.Status == CASE_STATUS_CLOSED &&
        c.RecordTypeId == C_RecordTypeHelper.CASE_INFORMATION);
      Boolean supportTag =
        (c.Origin == 'Facebook' || c.Origin == 'Twitter') &&
        (c.SourceId != null &&
        c.SourceId.getSOBjectType() == SocialPost.SObjectType &&
        c.Status == CASE_STATUS_CLOSED &&
        c.RecordTypeId == C_RecordTypeHelper.CASE_SUPPORT);
      Boolean feedbackTag =
        (c.Origin == 'Facebook' || c.Origin == 'Twitter') &&
        (c.SourceId != null &&
        c.SourceId.getSOBjectType() == SocialPost.SObjectType &&
        c.Status == CASE_STATUS_CLOSED &&
        c.RecordTypeId == C_RecordTypeHelper.CASE_FEEDBACK);
      if ((infoTag || supportTag || feedbackTag)) {
        socialPostIds.add(c.SourceId);
        caseInScope.add(c);
      }
    }
    Map<Id, SocialPost> socialPostsByIds = new Map<Id, SocialPost>(
      [SELECT Id, OwnerId FROM SocialPost WHERE Id = :socialPostIds]
    );
    for (Case c : caseInScope) {
      if (socialPostsByIds.containsKey(c.SourceId)) {
        if (
          socialPostsByIds.get(c.SourceId).OwnerId.getSObjectType() ==
          User.SObjectType
        ) {
          c.OwnerId = socialPostsByIds.get(c.SourceId).OwnerId;
        } else {
          c.addError(
            'The Social Post needs to be assign to a user before tagging the post'
          );
        }
      }
    }
  }

  /**
    Method to update parent social post with status fields when case is created
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
  private static void updateSocialPost(List<Case> newCaseList) {
    Map<Id, Case> caseBySoMeIds = new Map<Id, Case>();
    for (Case c : newCaseList) {
      if (
        c.SourceId != null &&
        c.SourceId.getSobjectType() == SocialPost.SObjectType
      ) {
        caseBySoMeIds.put(c.SourceId, c);
      }
    }
    if (!caseBySoMeIds.isEmpty()) {
      List<SocialPost> sps = [
        SELECT Id
        FROM SocialPost
        WHERE Id = :caseBySoMeIds.keySet() AND ParentId = NULL
      ];
      List<SocialPost> spToUpdate = new List<SocialPost>();
      for (SocialPost sp : sps) {
        sp.ParentId = caseBySoMeIds.get(sp.Id).Id;
        if (caseBySoMeIds.get(sp.Id).Status != CASE_STATUS_CLOSED) {
          sp.FCS_CaseCreated__c = true;
          sp.FCS_Done__c = true;
          sp.FCS_ClosedDate__c = system.now();
          sp.ReviewedStatus = SP_STATUS_REVIEWED;
        }
        spToUpdate.add(sp);
      }
      update spToUpdate;
    }
  }

  /**
    Method to make sure Case Reason and Case Tags is not the same value
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
  private static void validateCaseTags(List<Case> newCaseList) {
    // TODO: Remove when when old case tags setup is gone.
    Integer cSize = newCaseList.size();
    for (Integer i = 0; i < cSize; i++) {
      Case newC = newCaseList[i];
      List<String> caseTagString = newC.FCS_CaseTags__c != null
        ? newC.FCS_CaseTags__c.split(';')
        : null;
      if (caseTagString != null) {
        for (String s : CaseTagString) {
          if (s == newC.FCS_CaseReason__c) {
            newC.addError(
              'You can not provide the same additional reason (case tag) as the Case Reason'
            );
          }
        }
      }
    }
  }

  /**
   * Creates/updates/delete case tag records when tags (Case Reason, Case SubReason or Case Tag) is updated on case
   * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
   */
  private static void manageCaseTagRecords(
    List<Case> newCaseList,
    Map<Id, Case> newCaseMap
  ) {
    // TODO: Remove when when old case tags setup is gone.
    Map<String, FCS_CaseTag__c> newTagByKeyId = createToBeCaseTagMap(
      newCaseList
    );
    Map<String, FCS_CaseTag__c> oldTagByKeyId = createCurrentCaseTagMap(
      newCaseMap
    );
    List<FCS_CaseTag__c> deleteCaseTags = new List<FCS_CaseTag__c>();
    List<FCS_CaseTag__c> createCaseTags = new List<FCS_CaseTag__c>();

    for (String keyId : newTagByKeyId.keySet()) {
      if (oldTagByKeyId.containsKey(keyId))
        oldTagByKeyId.remove(keyId);
      else if (!oldTagByKeyId.containsKey(keyId))
        createCaseTags.add(newTagByKeyId.get(keyId));
    }
    deleteCaseTags = oldTagByKeyId.values();
    if (createCaseTags != null)
      upsert createCaseTags;
    if (deleteCaseTags != null)
      delete deleteCaseTags;
  }
  /**
   * Returns a map containing the current (old) case tags records that needs to be evaluate agianst the new version of the case, FCS_CaseId__c+CaseTag+Type as key
   * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
   * @return caseTagsByKeyId Map with existing case tag records (FCS_CaseTag__c) with FCS_CaseId__c+Tag+Type as key
   */
  public static Map<String, FCS_CaseTag__c> createCurrentCaseTagMap(
    Map<Id, Case> newCaseMap
  ) {
    // TODO: Remove when when old case tags setup is gone.
    List<FCS_CaseTag__c> caseTagRecords = [
      SELECT Id, FCS_CaseTag__c, FCS_Type__c, FCS_CaseId__c
      FROM FCS_CaseTag__c
      WHERE FCS_CaseId__c = :newCaseMap.keySet()
    ];
    Map<String, FCS_CaseTag__c> caseTagsByKeyId = new Map<String, FCS_CaseTag__c>();
    if (!caseTagRecords.isEmpty()) {
      for (FCS_CaseTag__c ct : caseTagRecords) {
        if (
          !caseTagsByKeyId.containsKey(
            ct.FCS_CaseId__c +
            ct.FCS_CaseTag__c +
            ct.FCS_Type__c
          )
        )
          caseTagsByKeyId.put(
            ct.FCS_CaseId__c +
            ct.FCS_CaseTag__c +
            ct.FCS_Type__c,
            ct
          );
      }
    }
    return caseTagsByKeyId;
  }

  /**
   * Returns a map containg the updated version (new) of the case tags records with FCS_CaseId__c+CaseTag+Type as key
   * @param newCaseList The list of the new version of the case i.e. the Trigger.new variable
   * @return newTagsByKeyId Map with new case tags on Case with FCS_CaseId__c+Tag+Type as key
   */
  public static Map<String, FCS_CaseTag__c> createToBeCaseTagMap(
    List<Case> newCaseList
  ) {
    // TODO: Remove when when old case tags setup is gone.
    Integer cSize = newCaseList.size();
    Map<String, FCS_CaseTag__c> newTagsByKeyId = new Map<String, FCS_CaseTag__c>();
    for (Integer i = 0; i < cSize; i++) {
      Case newC = newCaseList == null ? null : newCaseList[i];
      List<String> caseTagString = newC.FCS_CaseTags__c != null
        ? newC.FCS_CaseTags__c.split(';')
        : null;
      if (newC.FCS_CaseReason__c != null)
        newTagsByKeyId.put(
          newC.Id +
          newC.FCS_CaseReason__c +
          MAIN_TAG,
          new FCS_CaseTag__c(
            FCS_CaseId__c = newC.Id,
            FCS_CaseTag__c = newC.FCS_CaseReason__c,
            FCS_Type__c = MAIN_TAG
          )
        );
      if (newC.FCS_CaseSubReason__c != null)
        newTagsByKeyId.put(
          newC.Id +
          newC.FCS_CaseSubReason__c +
          SUB_MAIN_TAG,
          new FCS_CaseTag__c(
            FCS_CaseId__c = newC.Id,
            FCS_CaseTag__c = newC.FCS_CaseSubReason__c,
            FCS_Type__c = SUB_MAIN_TAG
          )
        );
      if (caseTagString != null) {
        for (String s : CaseTagString) {
          newTagsByKeyId.put(
            newC.Id +
            s +
            ADDITIONAL_TAG,
            new FCS_CaseTag__c(
              FCS_CaseId__c = newC.Id,
              FCS_CaseTag__c = s,
              FCS_Type__c = ADDITIONAL_TAG
            )
          );
        }
      }
    }
    return newTagsByKeyId;
  }

  /**
   * If an account with the same email address as the case's SuppliedEmail
   * exists in Salesforce, associates the case with the account.
   */
  private void tryToAssignExistingEBAccountToCase(List<Case> newCaseList) {
    if (
      newCaseList.size() > 1 || String.isBlank(newCaseList[0].SuppliedEmail)
    ) {
      // At the time of writing CODS didn't support searching with more than one key
      // at a time so we can't reasonably support batch operations.
      return;
    }
    Case c = newCaseList[0];

    List<Account> accountsFromDB = [
      SELECT Id, FCS_EBLevel__c, FCS_EBNumber__c
      FROM Account
      WHERE PersonEmail = :c.SuppliedEmail AND isPersonAccount = TRUE
    ];

    if (accountsFromDB.size() == 1) {
      assignAccountToCase(accountsFromDB[0], c);
    }
  }

  /**
   * Tries to fetch a EuroBonus account for the cases from CODS if the case doesn't
   * already have an associated account.
   */
  private void tryToFetchEBAccountFromCODS(List<Case> newCaseList) {
    // TODO: We need to ignore email addresses here somehow
    if (newCaseList.size() > 1) {
      // At the time of writing CODS didn't support searching with more than one key
      // at a time so we can't reasonably support batch operations.
      return;
    }
    Case c = newCaseList[0];

    if (c.accountId == null && !String.isBlank(c.SuppliedEmail)) {
      findEuroBonusAccount(c.Id, c.SuppliedEmail);
    }
  }

  /**
   * Performs a CODS query for an EB account with the given email. If one
   * is found, creates a corresponding account in SF and associates it with
   * the given case.
   *
   * @param caseId The case to which this account should be associated to.
   * @param email Email to search with.
   */
  @future(callout=true)
  public static void findEuroBonusAccount(Id caseId, String email) {
    Account acc = FCS_IdentifyCustomerController.findCustomer(
      'EmailPersonal__c',
      email
    );

    if (acc != null) {
      List<Case> casesFromDB = cases.selectById(new Set<Id>{ caseId });
      if (casesFromDB.size() > 0) {
        Case c = casesFromDB[0];
        c.accountId = acc.Id;
        c.FCS_EBLevel__c = acc.FCS_EBLevel__c;
        c.FCS_EBNumber__c = acc.FCS_EBNumber__c;

        update c;
      }
    }
  }

  private void assignAccountToCase(Account acc, Case c) {
    c.accountId = acc.Id;
    c.FCS_EBLevel__c = acc.FCS_EBLevel__c;
    c.FCS_EBNumber__c = acc.FCS_EBNumber__c;
  }

  private void updateBookingsForNewAssociatedAccounts(List<Case> newCases) {
    updateBookingsForNewAssociatedAccounts(newCases, null);
  }

  /**
   * Fetches bookings for an account that was added to a case if only one was added.
   * (Works only for one as the current TEDS doesn't support fetching multiple ones.)
   * TODO: Batchify when we can get multiple bookings from TEDS.
   */
  private void updateBookingsForNewAssociatedAccounts(
    List<Case> newCases,
    List<Case> oldCases
  ) {
    if (
      newCases.size() == 1 &&
      !System.isFuture() &&
      !System.isBatch() &&
      !System.isQueueable()
    ) {
      // FIXME: Make sure that the future's cannot be called again in a trigger.
      Case c = newCases[0];
      if (c.AccountId != null) {
        if (oldCases == null || (c.AccountId != oldCases[0].AccountId)) {
          AccountsSelector accounts = (AccountsSelector) SAS_Service_Application.Selector.newInstance(
            Account.SObjectType
          );
          Account a = accounts.selectById(new Set<Id>{ c.AccountId })[0];
          if (a.FCS_EBNumber__c != null && a.FCS_EBNumber__c.length() > 0) {
            BookingService.fetchBookingsByEBNumber(a.FCS_EBNumber__c);
          }
        }
      }
    }
  }

  public static void enrichCaseTagData(List<Case> newCases) {
    for (Case cse : newCases) {
      if (cse.FCS_Case_Reason__c != 'Other') {
        cse.FCS_CaseResolutionDetails__c = '';
      }
    }
  }

  private static void createCaseToBookings(List<Case> newCases) {
    if (newCases.size() == 1) {
      // Fetch bookings API supports only a single booking at a time.
      // FIXME: When possible, make this support batches.
      Case c = newCases[0];

      if (!String.isBlank(c.Refund_PNR__c)) {
        BookingService.addBookingToCaseAsync(c.Id, c.Refund_PNR__c);
      } else if (!String.isBlank(c.Initially_Provided_PNR__c)) {
        BookingService.addBookingToCaseAsync(c.Id, c.Initially_Provided_PNR__c);
      }
    }
  }
}
