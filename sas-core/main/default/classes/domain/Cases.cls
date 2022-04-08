public without sharing class Cases extends fflib_SObjectDomain {
  public Cases(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Case>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Cases(records);
    }
  }

  public static Cases newInstance(List<Case> sObjectList) {
    return (Cases) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  private List<Case> instanceRecords;

  public static final String STATUS_IN_PROGRESS = 'In Progress';
  public static final String STATUS_WAITING_FOR_APPROVAL = 'Waiting for Approval';
  public static final String STATUS_WAITING_FOR_CONTROL = 'Waiting for Control';
  public static final String STATUS_WAITING_FOR_TRANSFER = 'Waiting for Transfer';
  public static final String STATUS_CLOSED = 'Closed';

  public enum RecordType {
    Channel,
    CustomerClaim
  }

  public static Map<RecordType, String> recordTypeToDeveloperName = new Map<RecordType, String>{
    RecordType.Channel => 'Channel',
    RecordType.CustomerClaim => 'Customer Claim'
  };

  private static Map<RecordType, Id> recordTypeToId = new Map<RecordType, String>();

  public static Id getRecordTypeId(RecordType rt) {
    Id rtId = recordTypeToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.Case.getRecordTypeInfosByName()
        .get(recordTypeToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeToId.put(rt, rtId);
    }
    return rtId;
  }

  public override void onAfterDelete() {
    removeRelatedSurveyInvitations();
  }

  public override void onAfterInsert() {
    createCaseToBookings();
    updateBookingsForNewAssociatedAccounts();
    updateSocialPost();
    tryToFetchEBAccountFromCODS();
    refundDuplicateCheck();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    updateBookingsForNewAssociatedAccounts(
      instanceRecords,
      (Map<Id, Case>) existingRecords
    );
    lockClaimsAfterMerge((Map<Id, Case>) existingRecords);
    closeClaimCaseAfterApproval();
  }

  public override void onBeforeInsert() {
    assignOwnerFromSoMe();
    enrichCaseDataBasedOnOrigin();
    enrichCaseTagData();
    enrichMissingPointsCaseDataWithMissingPointsFormData();
    tryToAssignExistingEBAccountToCase();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    completeMilestones();
    enrichCaseTagData();
  }

  private void completeMilestones() {
    // how to handle maps?
    List<String> statusesThatCompleteMilestones = new List<String>{
      'Awaiting Customer Response',
      'Closed',
      'Escalated',
      'Merged',
      'On Hold'
    };

    Map<Id, Case> cases = new Map<Id, Case>(instanceRecords);

    List<CaseMilestone> milestonesOfCases = [
      SELECT CaseId, CompletionDate, Id
      FROM CaseMilestone
      WHERE CaseId IN :cases.keySet() AND IsCompleted = FALSE
    ];

    List<CaseMilestone> milestonesToComplete = new List<CaseMilestone>();

    for (CaseMilestone milestone : milestonesOfCases) {
      if (
        statusesThatCompleteMilestones.contains(
          cases.get(milestone.CaseId).Status
        )
      ) {
        milestone.CompletionDate = DateTime.now();
        milestonesToComplete.add(milestone);
      }
    }

    update milestonesToComplete;
  }

  /**
   * Updates case fields based on Origin of the Case. The Enrich_Case_Based_On_Origin_Config__mdt
   * custom metadata type is used to defined what data to assign based on Origin.
   *
   * Should be run only on beforeInsert.
   */
  private void enrichCaseDataBasedOnOrigin() {
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

    for (Case c : instanceRecords) {
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

  private void enrichCaseTagData() {
    for (Case c : instanceRecords) {
      if (c.FCS_Case_Reason__c != 'Other') {
        c.FCS_CaseResolutionDetails__c = '';
      }
    }
  }

  private void createCaseToBookings() {
    if (instanceRecords.size() == 1) {
      // Fetch bookings API supports only a single booking at a time.
      // FIXME: When possible, make this support batches.
      Case c = instanceRecords[0];

      if (!String.isBlank(c.Initially_Provided_PNR__c)) {
        BookingService.addBookingToCaseAsync(c.Id, c.Initially_Provided_PNR__c);
      }
    }
  }

  class CaseException extends Exception {
  }

  /**
   * Locks the related claims for merged cases.
   *
   * Throws an error when trying to merge cases which have a claim with an
   * existing settlement.
   */
  private void lockClaimsAfterMerge(Map<Id, Case> oldCases) {
    Set<Id> claimsToLock = new Set<Id>();
    for (Case c : instanceRecords) {
      Boolean isNewlyMergedWithClaim =
        c.Status == 'Merged' &&
        c.LIA_Claim__c != null &&
        oldCases.get(c.Id).Status != 'Merged';
      if (isNewlyMergedWithClaim) {
        // Queries inside a loop, but we shouldn't be merging a lot at a time, anyway.
        List<Settlement__c> settlementsForClaim = SettlementsSelector.newInstance()
          .selectByClaimId(new Set<Id>{ c.LIA_Claim__c });

        if (settlementsForClaim != null && settlementsForClaim.size() > 0) {
          throw new CaseException(
            'Cannot merge cases with existing settlements.'
          );
        }

        claimsToLock.add(c.LIA_Claim__c);
      }
    }
    if (claimsToLock.size() > 0) {
      Approval.lock(new List<Id>(claimsToLock));
    }
  }

  private void updateBookingsForNewAssociatedAccounts() {
    updateBookingsForNewAssociatedAccounts(instanceRecords, null);
  }

  /**
   * Fetches bookings for an account that was added to a case if only one was added.
   * (Works only for one as the current TEDS doesn't support fetching multiple ones.)
   * TODO: Batchify when we can get multiple bookings from TEDS.
   */
  private void updateBookingsForNewAssociatedAccounts(
    List<Case> newCases,
    Map<Id, Case> oldCases
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
        if (
          oldCases == null || (c.AccountId != oldCases.values()[0].AccountId)
        ) {
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

  /**
   * Prefer to search by EuroBonus number for cases where this can be entered directly such as Turi or Forms on sas.xx.
   * Search by email address for cases where EuroBonus number is unavailable such as Email-To-Case.
   * If the account exists in Salesforce, associate the case with the account.
   */
  private void tryToAssignExistingEBAccountToCase() {
    if (
      instanceRecords.size() > 1 ||
      (String.isBlank(instanceRecords[0].SuppliedEmail) &&
      String.isBlank(instanceRecords[0].FCS_EBNumber__c))
    ) {
      // At the time of writing CODS didn't support searching with more than one key
      // at a time so we can't reasonably support batch operations.
      return;
    }
    Case c = instanceRecords[0];
    AccountsSelector accs = AccountsSelector.newInstance();

    List<Account> accountsFromDB = !String.isBlank(c.FCS_EBNumber__c)
      ? accs.selectByEuroBonusNumber(new Set<String>{ c.FCS_EBNumber__c })
      : accs.selectByEmail(new Set<String>{ c.SuppliedEmail });

    if (accountsFromDB?.size() == 1) {
      assignAccountToCase(accountsFromDB[0], c);
    }
  }

  /**
   * Tries to fetch a EuroBonus account for the cases from CODS if the case doesn't
   * already have an associated account.
   *
   * Prefer to search by EuroBonus number for cases where this can be entered directly such as Turi or Forms on sas.xx.
   * Search by email address for cases where EuroBonus number is unavailable such as Email-To-Case.
   */
  private void tryToFetchEBAccountFromCODS() {
    if (
      instanceRecords.size() > 1 ||
      (String.isBlank(instanceRecords[0].SuppliedEmail) &&
      String.isBlank(instanceRecords[0].FCS_EBNumber__c))
    ) {
      // At the time of writing CODS didn't support searching with more than one key
      // at a time so we can't reasonably support batch operations.
      return;
    }
    Case c = instanceRecords[0];

    if (c.accountId == null) {
      String searchField = !String.isBlank(c.FCS_EBNumber__c)
        ? 'FCS_EBNumber__c'
        : 'EmailPersonal__c';
      String searchValue = !String.isBlank(c.FCS_EBNumber__c)
        ? c.FCS_EBNumber__c
        : c.SuppliedEmail;
      findEuroBonusAccount(c.Id, searchField, searchValue);
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
  public static void findEuroBonusAccount(
    Id caseId,
    String searchField,
    String searchValue
  ) {
    Account acc = FCS_IdentifyCustomerController.findCustomer(
      searchField,
      searchValue
    );

    if (acc != null) {
      List<Case> casesFromDB = CasesSelector.newInstance()
        .selectById(new Set<Id>{ caseId });
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

  private void removeRelatedSurveyInvitations() {
    List<Id> caseIds = new List<Id>(
      new Map<Id, Case>(instanceRecords).keySet()
    );

    delete [
      SELECT Id
      FROM SurveyInvitation
      WHERE FCS_RelatedCase__c IN :caseIds
    ];
  }

  /**
    Method to set owner on case created from SoMe-post quick actions
    */
  private void assignOwnerFromSoMe() {
    Set<Id> socialPostIds = new Set<Id>();
    List<Case> caseInScope = new List<Case>();
    for (Case c : instanceRecords) {
      Boolean channelTag =
        (c.Origin == 'Facebook' || c.Origin == 'Twitter') &&
        (c.SourceId != null &&
        c.SourceId.getSOBjectType() == SocialPost.SObjectType &&
        c.Status == 'Closed' &&
        c.RecordTypeId == getRecordTypeId(RecordType.Channel));
      if (channelTag) {
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
    */
  private void updateSocialPost() {
    Map<Id, Case> caseBySoMeIds = new Map<Id, Case>();
    for (Case c : instanceRecords) {
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
        if (caseBySoMeIds.get(sp.Id).Status != 'Closed') {
          sp.FCS_CaseCreated__c = true;
          sp.FCS_Done__c = true;
          sp.FCS_ClosedDate__c = system.now();
          sp.ReviewedStatus = 'Reviewed';
        }
        spToUpdate.add(sp);
      }
      update spToUpdate;
    }
  }

  private void enrichMissingPointsCaseDataWithMissingPointsFormData() {
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

    for (Case c : instanceRecords) {
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

          if (StringUtils.isEmailAddress(memberEmailFromForm)) {
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
   * Run Duplicate Check Flow for Refund cases
   */
  private void refundDuplicateCheck() {
    if (instanceRecords.size() > 1) {
      return;
    }
    Case c = instanceRecords[0];
    if (c.Department__c == 'Refunds' && c.Refund_Request__c != null) {
      Map<String, Object> inputs = new Map<String, Object>();
      inputs.put('recordId', c.Id);
      inputs.put('isManualCheck', false);

      Flow.Interview.UTIL_Duplicate_Check_Refund duplicateFlow = new Flow.Interview.UTIL_Duplicate_Check_Refund(
        inputs
      );
      duplicateFlow.start();
    }
  }

  /**
   * Sends the draft email connected to a Customer Claim Case once
   * the case has been approved then closes the case and notifies
   * the user
   */
  private void closeClaimCaseAfterApproval() {
    if (instanceRecords.size() > 1) {
      return;
    }

    Case c = instanceRecords[0];
    if (
      c.RecordTypeId == getRecordTypeId(RecordType.CustomerClaim) &&
      c.Status == STATUS_WAITING_FOR_TRANSFER
    ) {
      //Check if there are Settlements for this cases
      List<Settlement__c> settlementsForClaim = SettlementsSelector.newInstance()
        .selectByClaimId(new Set<Id>{ c.LIA_Claim__c });
      if (settlementsForClaim.size() < 1) {
        return;
      }

      //Get Email Draft for this case
      List<EmailMessage> draftEmailForCase = EmailMessagesSelector.newInstance()
        .selectByParentIdAndStatus(
          new Set<Id>{ c.Id },
          new Set<Id>{ c.OwnerId },
          EmailMessages.STATUS_DRAFT
        );

      //Only send email if not test
      if (draftEmailForCase.size() == 1) {
        EmailMessage existingDraftEmail = draftEmailForCase[0];
        Boolean sendSuccess = false;
        String errorMsg = '';
        List<Case> caseToUpdate = CasesSelector.newInstance()
          .selectById(new Set<Id>{ c.Id });
        try {
          fflib_ISObjectUnitOfWork uowTry = SAS_Service_Application.UnitOfWork.newInstance();
          Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
          emailToSend.setSenderDisplayName(existingDraftEmail.FromAddress);
          emailToSend.setToAddresses(existingDraftEmail.ToAddress.split(';'));
          emailToSend.setReplyTo(existingDraftEmail.FromAddress);
          if (existingDraftEmail.CcAddress != null) {
            emailToSend.setCcAddresses(existingDraftEmail.CcAddress.split(';'));
          }
          if (existingDraftEmail.BccAddress != null) {
            emailToSend.setBccAddresses(
              existingDraftEmail.BccAddress.split(';')
            );
          }
          emailToSend.setSubject(existingDraftEmail.Subject);
          emailToSend.setHtmlBody(existingDraftEmail.HtmlBody);
          emailToSend.setPlainTextBody(existingDraftEmail.TextBody);
          emailToSend.setSaveAsActivity(true);
          emailToSend.setWhatId(c.Id);
          uowTry.registerEmail(emailToSend);
          uowTry.registerDeleted(existingDraftEmail);
          caseToUpdate[0].Status = STATUS_CLOSED;
          caseToUpdate[0].IsApproved__c = false;
          uowTry.registerDirty(caseToUpdate[0]);
          uowTry.commitWork();
          sendSuccess = true;
        } catch (Exception exc) {
          fflib_ISObjectUnitOfWork uowCatch = SAS_Service_Application.UnitOfWork.newInstance();
          caseToUpdate[0].Status = STATUS_IN_PROGRESS;
          caseToUpdate[0].IsApproved__c = false;
          uowCatch.registerDirty(caseToUpdate[0]);
          uowCatch.commitWork();
          sendSuccess = false;
          errorMsg = exc.getMessage();
        }

        String notificationTitle = sendSuccess
          ? 'Case closed'
          : 'Case could not be closed';
        String notificationBody = sendSuccess
          ? 'Case ' +
            c.CaseNumber +
            ' was closed and email was sent to the customer'
          : 'The draft email could not be sent to the customer. Please review the email and send it manually instead\n' +
            errorMsg;

        CustomNotificationType notificationType = [
          SELECT Id, DeveloperName
          FROM CustomNotificationType
          WHERE DeveloperName = 'SettlementUpdate'
        ];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(c.Id);
        notification.setTitle(notificationTitle);
        notification.setBody(notificationBody);
        notification.send(new Set<String>{ c.OwnerId });
      }
    }
  }

  /**
   * Associates a Case record with an EB account if one already exists
   * in Salesforce. Doesn't try to fetch EB account data from outside of SF
   * if it doesn't already exist in there.
   */
  /*public void associateWithExistingEBAccounts() {
    associateWithExistingEBAccountsNoUpdate();
    upsert Records;
  }

  private void associateWithExistingEBAccountsNoUpdate() {
    AccountsSelector accounts = (AccountsSelector) SAS_Service_Application.Selector.newInstance(
      Account.SObjectType
    );

    Set<String> euroBonusNumbers = new Set<String>();

    for (Case__c Case : (List<Case__c>) Records) {
      if (Case.EuroBonus_Number__c != null) {
        euroBonusNumbers.add(Case.EuroBonus_Number__c);
      }
    }

    List<Account> accountsFromSF = accounts.selectByEuroBonusNumber(
      euroBonusNumbers
    );

    for (Case__c Case : (List<Case__c>) Records) {
      if (Case.EuroBonus_Number__c != null) {
        for (Account account : accountsFromSF) {
          if (account.FCS_EBNumber__c == Case.EuroBonus_Number__c) {
            Case.Account__c = account.Id;
          }
        }
      }
    }
  }*/
}
