public without sharing class ClaimService {
  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    // TODO: Remove when we deprecate old forms
    '0-2' => '0-2',
    '2-3' => '2-3',
    '3-4' => '3-4',
    '4+' => '4+',
    'accident-and-injury' => 'Accident & injury',
    'accommodation' => 'Accommodation',
    'airport-experience' => 'Airport experience',
    'baggage-damaged' => 'Baggage damaged',
    'baggage-delayed' => 'Baggage delayed/lost',
    'baggage' => 'Baggage',
    'booking' => 'Booking',
    'booking-error' => 'Booking error',
    'cabin-environment' => 'Cabin environment',
    'claims-management-company' => 'Claim firm',
    'complaint-about-refund' => 'Complaint about a refund',
    'corporate' => 'Corporate customer',
    'denied-boarding' => 'Denied boarding',
    'downgrading' => 'Downgrading',
    'eurobonus' => 'EuroBonus Points',
    'extra-baggage' => 'Extra baggage',
    'flight-cancellation' => 'Flight cancellation',
    'flight-delay' => 'Flight delay',
    'flight-disruptions' => 'Flight disruptions',
    'flight-experience' => 'Flight experience',
    'food' => 'Food',
    'gate-issues' => 'Gate issues',
    'insurance-company' => 'Insurance company',
    'in-flight-meal' => 'In-flight meal',
    'in-flight-service' => 'In-flight service',
    'less-than-21-days' => 'Less than 21 days',
    'lounge' => 'Lounge',
    'meals-drinks' => 'Meals/Drinks',
    'missed-connection' => 'Missed connection',
    'missing-items' => 'Items missing from checked-in baggage',
    'monetary' => 'Monetary',
    'more-than-21-days' => '21 days or more',
    'never-arrived' => 'Never arrived',
    'other-representative' => 'Other representative',
    'other' => 'Other',
    'personal-injury' => 'Personal injury',
    'phone-calls' => 'Phone calls',
    'prepaid-seat' => 'Prepaid seat',
    'private' => 'Private customer',
    'regression' => 'Regression',
    'special-assistance' => 'Special assistance',
    'transportation' => 'Transportation',
    'travel-agency' => 'Travel agency',
    'travel-document-control' => 'Travel document control',
    'travel-extras-bought-not-rendered' => 'Travel extras bought not rendered',
    'voucher' => 'Voucher',
    'wifi' => 'WiFi'
  };

  public static final String COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME = 'compensation_card_success';
  public static final String COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME = 'compensation_card_failure';
  public static final String COMPENSATION_CARD_REPLY_TO_ADDRESS = 'customercare@sas.se';
  public static final String COMPENSATION_CARD_OMNI_QUEUE_NAME = 'Claims_Compensation_Card'; //TODO: Switch to compensation card
  public static final String APPROVAL_QUEUE_NAME = 'Approvers';

  public static ClaimService newInstance() {
    return (ClaimService) SAS_Service_Application.Service.newInstance(
      ClaimService.class
    );
  }

  public class MissingArgumentsException extends Exception {
  }

  public static String createClaim(CreateClaimRequest request) {
    Claims c = Claims.createFromClaims(
      new List<Claim>{ createClaimRecord(request) }
    );
    c.upsertToDB();

    Claim claimToCreate = c.objects[0];

    List<SObject> objectsToCreate = new List<SObject>();
    Map<Id, SObject> fileIdsToObjects = new Map<Id, SObject>();

    String travelersRichTextForAutoResponseEmail = '';
    for (CreateClaimRequest.Traveler traveler : request.travelers) {
      ClaimCustomer cust = createCustomer(traveler, claimToCreate);
      objectsToCreate.add(cust.underlyingSObject);

      travelersRichTextForAutoResponseEmail += traveler.toString() + '<br>';
    }

    String expensesRichTextForAutoResponseEmail = '';
    for (CreateClaimRequest.Expense expense : request.expenses) {
      ClaimExpense exp = createClaimExpense(expense, claimToCreate);
      objectsToCreate.add(exp.underlyingSObject);

      expensesRichTextForAutoResponseEmail += expense.toString() + '<br>';

      for (Id contentId : expense.contentVersionIds) {
        fileIdsToObjects.put(contentId, exp.underlyingSObject);
      }
    }

    String rebookedFlightsRichTextForAutoResponseEmail = '';
    for (CreateClaimRequest.RebookedFlight flight : request.rebookedFlights) {
      ClaimRebookedFlight rf = createRebookedFlight(flight, claimToCreate);
      objectsToCreate.add(rf.underlyingSObject);

      rebookedFlightsRichTextForAutoResponseEmail += flight.toString() + '<br>';

      for (Id contentId : flight.contentVersionIds) {
        fileIdsToObjects.put(contentId, rf.underlyingSObject);
      }
    }

    if (objectsToCreate.size() > 0) {
      insert objectsToCreate;
    }

    for (Id contentId : request.filesToLink) {
      fileIdsToObjects.put(contentId, claimToCreate.underlyingSObject);
    }

    insert constructContentLinks(fileIdsToObjects, claimToCreate.id);

    Case caseToCreate = createCaseRecord(request, claimToCreate);
    caseToCreate.Claim_Expenses__c = expensesRichTextForAutoResponseEmail;
    caseToCreate.Claim_Rebooked_Flights__c = rebookedFlightsRichTextForAutoResponseEmail;
    caseToCreate.Claim_Travelers__c = travelersRichTextForAutoResponseEmail;

    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    Case insertedCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseToCreate.Id })[0];

    // We need to do this dance because we want claim name to match the case
    // number, and they to be linked to each other.
    claimToCreate.parentCaseId = insertedCase.Id;
    claimToCreate.Name = insertedCase.CaseNumber;
    c.upsertToDB();

    System.enqueueJob(
      new CaseService.AssignPriorityAndRouteToQueueAsync(
        new Set<Id>{ insertedCase.Id }
      )
    );

    return insertedCase.CaseNumber;
  }

  public static String createCompensationCardClaim(
    RedeemCompensationCardRequest request
  ) {
    Claims c = Claims.createFromClaims(
      new List<Claim>{ createClaimRecord(request) }
    );
    c.upsertToDB();

    Claim claimToCreate = c.objects[0];

    ClaimCustomer cust = new ClaimCustomer(claimToCreate);
    cust.firstName = request.contact.firstName == null
      ? ' '
      : request.contact.firstName;
    cust.lastName = request.contact.lastName == null
      ? ' '
      : request.contact.lastName;
    cust.updateSObjectFields();
    insert cust.underlyingSObject;

    Case caseToCreate = createCaseRecord(request, claimToCreate);
    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    Case insertedCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseToCreate.Id })[0];

    claimToCreate.parentCaseId = insertedCase.Id;
    claimToCreate.Name = insertedCase.CaseNumber;
    c.upsertToDB();

    List<Feature_Switch__mdt> automationSwitch = [
      SELECT Active__c
      FROM Feature_Switch__mdt
      WHERE QualifiedApiName = 'Process_Compensation_Cards_Automatically'
    ];

    if (
      automationSwitch == null ||
      automationSwitch.size() > 0 && automationSwitch[0].Active__c
    ) {
      System.enqueueJob(new RedeemCompensationCardClaim(claimToCreate.id));
    }

    return insertedCase.CaseNumber;
  }

  public static String createClaim(CaseFormJSON2Apex form) {
    // TODO: Remove when we deprecate old forms
    LIA_Claim__c claimToCreate = createClaimRecord(form);

    insert claimToCreate;

    Set<Id> contentIds = new Set<Id>();

    if (form.formData.contentVersionIds != null) {
      for (String contentId : form.formData.contentVersionIds) {
        if (!String.isBlank(contentId)) {
          contentIds.add(Id.valueOf(contentId));
        }
      }
    }
    List<SObject> objectsToCreate = new List<SObject>();
    List<Claim_Expense__c> expenses = new List<Claim_Expense__c>();
    List<Claim_Rebooked_Flight__c> rebookedFlights = new List<Claim_Rebooked_Flight__c>();
    Map<Id, SObject> fileIdsToObjects = new Map<Id, SObject>();

    String travelersRichTextForCase = '';
    if (form.formData.travelers != null) {
      for (CaseFormJSON2Apex.Traveler t : form.formData.travelers) {
        Customer__c customerToCreate = new Customer__c(
          Claim__c = claimToCreate.Id,
          First_Name__c = t.firstName == null ? ' ' : t.firstName,
          Last_Name__c = t.lastName == null ? ' ' : t.lastName
        );
        objectsToCreate.add(customerToCreate);

        travelersRichTextForCase +=
          customerToCreate.First_Name__c +
          ' ' +
          customerToCreate.Last_Name__c +
          '<br>';
      }
    }

    String expensesRichTextForCase = '';
    if (form.formData.expenses != null) {
      for (CaseFormJSON2Apex.Expense e : form.formData.expenses) {
        Claim_Expense__c expenseToCreate = new Claim_Expense__c(
          Claim__c = claimToCreate.Id,
          Amount__c = e.amount == null ? 0 : e.amount,
          Currency__c = e.expenseCurrency == null
            ? null
            : e.expenseCurrency.toUpperCase(),
          Type__c = jsonToPicklist.get(e.expenseType)
        );
        objectsToCreate.add(expenseToCreate);

        expensesRichTextForCase +=
          expenseToCreate.Type__c +
          ': ' +
          expenseToCreate.Amount__c +
          ' ' +
          expenseToCreate.Currency__c +
          '<br>';

        if (e.receiptFileId != null) {
          for (String contentId : e.receiptFileId) {
            if (!String.isBlank(contentId)) {
              fileIdsToObjects.put(contentId, expenseToCreate);
              contentIds.add(Id.valueOf(contentId));
            }
          }
        }
      }
    }

    String rebookedFlightsRichTextForCase = '';
    if (form.formData.rebookedFlights != null) {
      for (CaseFormJSON2Apex.Flight f : form.formData.rebookedFlights) {
        Claim_Rebooked_Flight__c flightToCreate = new Claim_Rebooked_Flight__c(
          Claim__c = claimToCreate.Id,
          Departure_Date__c = Date.valueOf(f.departureDate),
          Flight_Number__c = f.flightNumber
        );
        objectsToCreate.add(flightToCreate);

        rebookedFlightsRichTextForCase +=
          flightToCreate.Flight_Number__c +
          ' ' +
          f.departureDate +
          '<br>';

        if (f.boardingPassFileId != null) {
          for (String contentId : f.boardingPassFileId) {
            if (!String.isBlank(contentId)) {
              fileIdsToObjects.put(contentId, flightToCreate);
              contentIds.add(Id.valueOf(contentId));
            }
          }
        }
      }
    }

    if (objectsToCreate.size() > 0) {
      insert objectsToCreate;
    }

    List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();

    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance()
      .selectById(contentIds);
    for (ContentVersion content : contentToLink) {
      linksToCreate.add(
        new ContentDocumentLink(
          ContentDocumentId = content.ContentDocumentId,
          LinkedEntityId = claimToCreate.Id
        )
      );
      if (fileIdsToObjects.get(content.Id) != null) {
        linksToCreate.add(
          new ContentDocumentLink(
            ContentDocumentId = content.ContentDocumentId,
            LinkedEntityId = fileIdsToObjects.get(content.Id).Id
          )
        );
      }
    }

    if (linksToCreate.size() > 0) {
      insert linksToCreate;
    }

    Case caseToCreate = createCaseRecord(form, claimToCreate);
    caseToCreate.Claim_Expenses__c = expensesRichTextForCase;
    caseToCreate.Claim_Rebooked_Flights__c = rebookedFlightsRichTextForCase;
    caseToCreate.Claim_Travelers__c = travelersRichTextForCase;

    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    Case insertedCase = CasesSelector.newInstance()
      .selectById(new Set<Id>{ caseToCreate.Id })[0];

    claimToCreate.Case__c = insertedCase.Id;
    claimToCreate.Name = insertedCase.CaseNumber;
    update claimToCreate;

    System.enqueueJob(
      new CaseService.AssignPriorityAndRouteToQueueAsync(
        new Set<Id>{ insertedCase.Id }
      )
    );

    return insertedCase.CaseNumber;
  }

  public static String createCompensationCardClaim(CaseFormJSON2Apex form) {
    // TODO: Remove when we deprecate old forms
    LIA_Claim__c claimToCreate = createClaimRecord(form);
    claimToCreate.RecordTypeId = Claim.getRecordTypeIdByEnum(
      Claim.RecordType.CompensationCard
    );

    insert claimToCreate;

    Customer__c customerToCreate = new Customer__c(
      Claim__c = claimToCreate.Id,
      First_Name__c = form.formData.firstName == null
        ? ' '
        : form.formData.firstName,
      Last_Name__c = form.formData.lastName == null
        ? ' '
        : form.formData.lastName
    );

    insert customerToCreate;

    Case caseToCreate = createCaseRecord(form, claimToCreate);
    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    Case insertedCase = [
      SELECT Id, CaseNumber
      FROM Case
      WHERE Id = :caseToCreate.Id
    ];

    claimToCreate.Case__c = insertedCase.Id;
    claimToCreate.Name = insertedCase.CaseNumber;
    update claimToCreate;

    List<Feature_Switch__mdt> automationSwitch = [
      SELECT Active__c
      FROM Feature_Switch__mdt
      WHERE QualifiedApiName = 'Process_Compensation_Cards_Automatically'
    ];

    if (
      automationSwitch == null ||
      automationSwitch.size() > 0 && automationSwitch[0].Active__c
    ) {
      System.enqueueJob(new RedeemCompensationCardClaim(claimToCreate.Id));
    }

    return insertedCase.CaseNumber;
  }

  private static LIA_Claim__c createClaimRecord(CaseFormJSON2Apex form) {
    String ebNumber;

    try {
      ebNumber = Accounts.parseIntoEuroBonusNumber(
        form.formData.euroBonusNumber
      );
    } catch (Exception e) {
      ebNumber = '';
    }

    LIA_Claim__c claimToCreate = new LIA_Claim__c(
      Address_line_1__c = form.formData.address,
      Bank_Account_Holder_Name__c = form.formData.bankAccountHolderName,
      Bank_Name__c = form.formData.bankName,
      BIC_Swift__c = form.formData.bankBic,
      City__c = form.formData.city,
      Comment__c = form.formData.comment,
      Company_Code__c = form.formData.companyCode,
      Company_Name__c = form.formData.companyName,
      Compensation_Card_Number__c = form.formData.compensationCardId,
      Concerns_a_person_with_reduced_mobility__c = form.formData.personWithReducedMobility ==
        null
        ? false
        : form.formData.personWithReducedMobility,
      Concerns_an_unaccompanied_minor__c = form.formData.unaccompaniedMinor ==
        null
        ? false
        : form.formData.unaccompaniedMinor,
      Contact_Email__c = form.formData.email,
      Contact_First_Name__c = form.formData.firstName,
      Contact_Last_Name__c = form.formData.lastName,
      Currency__c = String.isBlank(form.formData.preferredCurrency)
        ? null
        : form.formData.preferredCurrency.toUppercase(),
      Customer_Claim_Category__c = jsonToPicklist.get(
        form.formData.claimCategory
      ),
      Customer_Claim_Type__c = jsonToPicklist.get(form.formData.claimType),
      Customer_s_Reference__c = form.formData.referenceNumber,
      Delay_Length__c = jsonToPicklist.get(form.formData.baggageDelayTime),
      EuroBonus_Number__c = ebNumber,
      Flight_Date__c = String.isBlank(form.formData.departureDate)
        ? null
        : Date.valueOf(form.formData.departureDate),
      Flight_Number__c = form.formData.flightNumber,
      Ticket_Number__c = form.formData.ticketNumber,
      Liability_PNR__c = form.formData.bookingReference,
      Phone_Number__c = form.formData.phone,
      Postal_Code__c = form.formData.postalCode,
      Purchase_Price__c = form.formData.baggagePurchasePrice,
      Purchase_Year__c = form.formData.baggagePurchaseYear,
      PIR__c = form.formData.passengerIrregularityReportNumber,
      Preferred_Compensation_Method__c = jsonToPicklist.get(
        form.formData.preferredCompensationMethod
      ),
      Preferred_Reimbursement_Method__c = jsonToPicklist.get(
        form.formData.preferredReimbursementMethod
      ),
      RecordTypeId = Claim.getRecordTypeIdByEnum(
        Claim.RecordType.CustomerClaim
      ),
      Total_delay_to_final_destination__c = jsonToPicklist.get(
        form.formData.delayLength
      ),
      Type_of_Customer__c = jsonToPicklist.get(form.formData.contactType)
    );

    if (!String.isBlank(form.formData.country)) {
      claimToCreate.Country__c = CountryUtils.getCountryNameByShortCode(
        form.formData.country
      );
    }

    if (!String.isBlank(form.formData.bankCountry)) {
      claimToCreate.Bank_Country__c = CountryUtils.getCountryNameByShortCode(
        form.formData.bankCountry
      );
    }

    if (!String.isBlank(form.formData.bankAccountNumber)) {
      if (!String.isBlank(form.formData.bankRoutingNumber)) {
        // US bank account numbers should be sent to Racer as {accountNumber}ABA{routingNumber}
        // Other countries have only an account number.
        claimToCreate.Bank_Account_Number__c =
          StringUtils.removeWhitespace(form.formData.bankAccountNumber) +
          'ABA' +
          StringUtils.removeWhitespace(form.formData.bankRoutingNumber);
      } else {
        claimToCreate.Bank_Account_Number__c = form.formData.bankAccountNumber.replace(
          ' ',
          ''
        );
      }
    }

    return claimToCreate;
  }

  private static Case createCaseRecord(
    CaseFormJSON2Apex form,
    LIA_Claim__c createdClaim
  ) {
    Map<String, String> marketToOrigin = new Map<String, String>{
      'dk-da' => 'Form - Claims DK',
      'no-no' => 'Form - Claims NO',
      'se-sv' => 'Form - Claims SE',
      'default' => 'Form - Claims International'
    };
    Map<String, String> compensationCardMarketToOrigin = new Map<String, String>{
      'dk-da' => 'Form - Compensation Card DK',
      'no-no' => 'Form - Compensation Card NO',
      'se-sv' => 'Form - Compensation Card SE',
      'default' => 'Form - Compensation Card International'
    };

    Group claimsQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{ 'Customer_Claim' })[0];

    String ebNumber;

    try {
      ebNumber = Accounts.parseIntoEuroBonusNumber(
        form.formData.euroBonusNumber
      );
    } catch (Exception e) {
      ebNumber = '';
    }

    String origin = null;

    if (form.formData.type == 'compensation-card') {
      origin = compensationCardMarketToOrigin.get(form.metaData.market) == null
        ? compensationCardMarketToOrigin.get('default')
        : compensationCardMarketToOrigin.get(form.metaData.market);
    } else {
      origin = marketToOrigin.get(form.metaData.market) == null
        ? marketToOrigin.get('default')
        : marketToOrigin.get(form.metaData.market);
    }

    String bookingReference = form.formData.bookingReference;
    if (!String.isBlank(form.formData.travelAgentBookingReference)) {
      bookingReference = form.formData.travelAgentBookingReference;
    }

    return new Case(
      Initially_Provided_PNR__c = form.formData.bookingReference,
      Description = form.formData.comment,
      FCS_EBNumber__c = ebNumber,
      LIA_Claim__c = createdClaim.Id,
      OwnerId = claimsQueue.Id,
      Origin = origin,
      SuppliedEmail = form.formData.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Claim, PNR: ' + bookingReference
    );
  }

  public class RedeemCompensationCardClaim implements Queueable, Database.AllowsCallouts {
    private Id claimId;
    public RedeemCompensationCardClaim(Id claimId) {
      this.claimId = claimId;
    }
    public void execute(QueueableContext ctx) {
      attemptToRedeemCompensationCardClaim(this.claimId);
    }
  }

  /**
   * Attempts to redeem the given compensation card claim. A compensation card
   * can be renewed if it is a valid compensation card as defined by by the
   * Vouchers API validate endpoint, and it has not yet been paid out.
   *
   * Information about whether a given compensation card has been paid out is
   * stored in Salesforce.
   *
   * Also closes the parent case for the claim, and emails the customer about
   * whether the card was redeemed successfully.
   */
  public static void attemptToRedeemCompensationCardClaim(Id claimId) {
    LIA_Claim__c claim = ClaimsSelector.newInstance()
      .selectById(new Set<Id>{ claimId })[0];

    Cases parentCase = Cases.newInstance(
      CasesSelector.newInstance().selectById(new Set<Id>{ claim.Case__c })
    );

    String caseId = parentCase.instanceRecords[0].Id;

    Boolean cardHasBeenPaidOut = RedeemedCompensationCards.hasBeenPaidOut(
      claim.Compensation_Card_Number__c,
      claim.Liability_PNR__c
    );

    if (cardHasBeenPaidOut) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
        caseId
      );
      emailToSend.setReplyTo(COMPENSATION_CARD_REPLY_TO_ADDRESS);

      parentCase.emailOwner(emailToSend, uow)
        .routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow)
        .close(uow);
      uow.commitWork();
    } else {
      Boolean canBeRedeemed = false;

      try {
        fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
        // Check Voucher API whether this is a valid compensation card number and
        // a matching PNR.
        VoucherValidateResponse response = VoucherIntegrationService.newInstance()
          .validateVoucher(
            claim.Compensation_Card_Number__c,
            claim.Liability_PNR__c
          );
        Redeemed_Compensation_Card__c validatedCompensationCard = RedeemedCompensationCards.createFromValidVoucher(
            response,
            claim,
            uow
          )
          .instanceRecords[0];
        Settlements.createFromCompensationCard(
          new List<LIA_Claim__c>{ claim },
          new Map<Id, Redeemed_Compensation_Card__c>{
            claim.Id => validatedCompensationCard
          },
          uow
        );
        uow.commitWork();
        canBeRedeemed = true;
      } catch (VoucherIntegrationService.InvalidVoucherException e) {
        fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

        C_Log.log(
          C_Log.Severity.Info,
          'Invalid compensation card redeem request.',
          null,
          'Claims',
          null
        );

        Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
          COMPENSATION_CARD_FAILURE_EMAIL_TEMPLATE_NAME,
          caseId
        );
        emailToSend.setReplyTo(COMPENSATION_CARD_REPLY_TO_ADDRESS);

        parentCase.emailOwner(emailToSend, uow)
          .routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow)
          .close(uow);

        uow.commitWork();
      } catch (Exception e) {
        // TODO: Error handling? Can we reject the claim or should we ask the customer to try again?
        C_Log.log(
          C_Log.Severity.Error,
          'Uncaught exception while redeeming a compensation card.',
          e.getStackTraceString(),
          'Claims',
          null
        );
        throw e;
      }

      if (canBeRedeemed) {
        try {
          fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

          Claims.newInstance(new List<LIA_Claim__c>{ claim }).settle(uow);

          Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
            COMPENSATION_CARD_SUCCESS_EMAIL_TEMPLATE_NAME,
            caseId
          );
          emailToSend.setReplyTo(COMPENSATION_CARD_REPLY_TO_ADDRESS);

          parentCase.emailOwner(emailToSend, uow)
            .routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow)
            .close(uow);

          uow.commitWork();
        } catch (Exception e) {
          fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
          Settlements.newInstance(
              SettlementsSelector.newInstance()
                .selectByClaimId(new Set<Id>{ claim.Id })
            )
            .markAsFailed(e.getMessage(), uow);
          parentCase.routeToQueue(COMPENSATION_CARD_OMNI_QUEUE_NAME, uow);
          CaseService.createChatterPost(
            parentCase.instanceRecords,
            e.getMessage(),
            uow
          );
          uow.commitWork();
        }
      }
    }
  }

  public static void fetchCAREClaimsFromEDW(
    String bookingReference,
    String pir,
    String caseId
  ) {
    String queryType;
    String queryText;

    // Skip querying CARE if the query has been done already.
    if (bookingReference != null && pir == null && caseId == null) {
      List<Executed_CARE_Query__c> foundQuery = [
        SELECT Id
        FROM Executed_CARE_Query__c
        WHERE Query_Text__c = :bookingReference AND Query_Type__c = 'PNR'
      ];

      if (foundQuery.size() > 0) {
        return;
      }

      queryType = 'PNR';
      queryText = bookingReference;
    } else if (bookingReference == null && pir != null && caseId == null) {
      List<Executed_CARE_Query__c> foundQuery = [
        SELECT Id
        FROM Executed_CARE_Query__c
        WHERE Query_Text__c = :pir AND Query_Type__c = 'PIR'
      ];

      if (foundQuery.size() > 0) {
        return;
      }

      queryType = 'PIR';
      queryText = pir;
    } else if (bookingReference == null && pir == null && caseId != null) {
      List<Executed_CARE_Query__c> foundQuery = [
        SELECT Id
        FROM Executed_CARE_Query__c
        WHERE Query_Text__c = :caseId AND Query_Type__c = 'CaseId'
      ];

      if (foundQuery.size() > 0) {
        return;
      }

      queryType = 'CaseId';
      queryText = caseId;
    }

    ClaimsIntegrationService.FetchCAREClaimsQuery query = new ClaimsIntegrationService.FetchCAREClaimsQuery();
    query.pnr = bookingReference;
    query.caseId = caseId;
    query.pir = pir;

    try {
      FetchCAREClaimsResponse response = ClaimsIntegrationService.fetchClaimsByQuery(
        query
      );

      if (queryType != null) {
        // Query type will be null if there were several fields queried. Let's not store those queries.
        Executed_CARE_Query__c ecq = new Executed_CARE_Query__c(
          Query_Text__c = queryText,
          Query_Type__c = queryType
        );

        insert ecq;
      }

      if (response == null) {
        return;
      }

      CAREClaims.create(response).upsertToDB();
    } catch (Exception e) {
      System.debug(e);
      C_Log.log(
        C_Log.Severity.Error,
        'Error when fetching CARE claims: ' + e.getMessage(),
        null,
        'CARE',
        null
      );
    }
  }

  public class FetchCAREClaimsFromEDWAsync implements Queueable, Database.AllowsCallouts {
    private String bookingReference;
    private String pir;
    private String caseId;

    public FetchCAREClaimsFromEDWAsync(
      String bookingReference,
      String pir,
      String caseId
    ) {
      this.bookingReference = bookingReference;
      this.caseId = caseId;
      this.pir = pir;
    }
    public void execute(QueueableContext ctx) {
      fetchCAREClaimsFromEDW(bookingReference, pir, caseId);
    }
  }

  private static Case createCaseRecord(
    CreateClaimRequest request,
    Claim createdClaim
  ) {
    Group claimsQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{ 'Customer_Claim' })[0];

    String bookingReference = request.bookingReference;
    if (!String.isBlank(request.travelAgentBookingReference)) {
      bookingReference = request.travelAgentBookingReference;
    }

    return new Case(
      Initially_Provided_PNR__c = request.bookingReference,
      Description = request.comment,
      FCS_EBNumber__c = request.contact.euroBonusNumber,
      LIA_Claim__c = createdClaim.id,
      OwnerId = claimsQueue.Id,
      Origin = request.origin,
      SuppliedEmail = request.contact.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Claim, PNR: ' + bookingReference
    );
  }

  private static Case createCaseRecord(
    RedeemCompensationCardRequest request,
    Claim createdClaim
  ) {
    Group claimsQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{ 'Customer_Claim' })[0];

      String bookingReference = request.bookingReference;
      if (!String.isBlank(request.travelAgentBookingReference)) {
        bookingReference = request.travelAgentBookingReference;
      }

    return new Case(
      Initially_Provided_PNR__c = request.bookingReference,
      FCS_EBNumber__c = request.contact.euroBonusNumber,
      LIA_Claim__c = createdClaim.id,
      OwnerId = claimsQueue.Id,
      Origin = request.origin,
      SuppliedEmail = request.contact.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Claim, PNR: ' + bookingReference
    );
  }

  private static Claim createClaimRecord(RedeemCompensationCardRequest r) {
    Claim newClaim = new Claim();

    newClaim.bankAccountHolderName = r.compensationDetails.bankAccountHolderName;
    newClaim.bankName = r.compensationDetails.bankName;
    newClaim.bankBicSwift = r.compensationDetails.bankBic;
    newClaim.bankCountry = r.compensationDetails.bankCountry;
    newClaim.bookingReference = r.bookingReference;
    newClaim.compensationCardNumber = r.compensationCardNumber;
    newClaim.contactAddressLine1 = r.contact.addressLine1;
    newClaim.contactAddressLine2 = r.contact.addressLine2;
    newClaim.contactCountry = r.contact.country;
    newClaim.contactCity = r.contact.city;
    newClaim.contactEmail = r.contact.email;
    newClaim.contactFirstName = r.contact.firstName;
    newClaim.contactLastName = r.contact.lastName;
    newClaim.contactPhone = r.contact.phone;
    newClaim.contactPostalCode = r.contact.postalCode;
    newClaim.contactType = Claim.ContactType.PrivateCustomer;
    newClaim.euroBonusNumber = r.contact.euroBonusNumber;
    newClaim.preferredCurrency = r.compensationDetails.preferredCurrency;
    newClaim.preferredCompensationMethod = r.compensationDetails.preferredCompensationMethod;
    newClaim.preferredReimbursementMethod = r.compensationDetails.preferredReimbursementMethod;
    newClaim.recordType = Claim.RecordType.CompensationCard;
    newClaim.referenceNumber = r.compensationDetails.referenceNumber;

    newClaim.updateSObjectFields();

    return newClaim;
  }

  private static Claim createClaimRecord(CreateClaimRequest r) {
    Claim newClaim = new Claim();

    newClaim.bankAccountHolderName = r.compensationDetails.bankAccountHolderName;
    newClaim.bankAccountNumber = r.compensationDetails.bankAccountNumber;
    newClaim.bankName = r.compensationDetails.bankName;
    newClaim.bankBicSwift = r.compensationDetails.bankBic;
    newClaim.bankCountry = r.compensationDetails.bankCountry;
    newClaim.contactCity = r.contact.city;
    newClaim.comment = r.comment;
    newClaim.companyCode = r.contact.companyCode;
    newClaim.companyName = r.contact.companyName;
    newClaim.personWithReducedMobility = r.personWithReducedMobility;
    newClaim.unaccompaniedMinor = r.unaccompaniedMinor;
    newClaim.contactAddressLine1 = r.contact.addressLine1;
    newClaim.contactAddressLine2 = r.contact.addressLine2;
    newClaim.contactEmail = r.contact.email;
    newClaim.contactFirstName = r.contact.firstName;
    newClaim.contactLastName = r.contact.lastName;
    newClaim.contactCountry = r.contact.country;
    newClaim.preferredCurrency = r.compensationDetails.preferredCurrency;
    newClaim.category = r.category;
    newClaim.type = r.type;
    newClaim.referenceNumber = r.compensationDetails.referenceNumber;
    newClaim.baggageDelayLength = r.baggageDelayLength;
    newClaim.euroBonusNumber = r.contact.euroBonusNumber;
    newClaim.departureDate = r.departureDate;
    newClaim.flightNumber = r.flightNumber;
    newClaim.ticketNumber = r.ticketNumber;
    newClaim.bookingReference = r.bookingReference;
    newClaim.contactPhone = r.contact.phone;
    newClaim.contactPostalCode = r.contact.postalCode;
    newClaim.baggagePurchasePrice = r.baggagePurchasePrice;
    newClaim.baggagePurchaseYear = r.baggagePurchaseYear;
    newClaim.pir = r.passengerIrregularityReportNumber;
    newClaim.preferredCompensationMethod = r.compensationDetails.preferredCompensationMethod;
    newClaim.preferredReimbursementMethod = r.compensationDetails.preferredReimbursementMethod;
    newClaim.recordType = r.recordType;
    newClaim.delayToDestination = r.delayLength;
    newClaim.contactType = r.contact.type;
    newClaim.travelAgentBookingReference = r.travelAgentBookingReference;

    newClaim.updateSObjectFields();

    return newClaim;
  }

  private static List<ContentDocumentLink> constructContentLinks(
    Map<Id, SObject> fileIdsToObjects,
    Id claimId
  ) {
    List<ContentDocumentLink> toReturn = new List<ContentDocumentLink>();

    List<ContentVersion> contentToLink = ContentVersionsSelector.newInstance()
      .selectById(fileIdsToObjects.keySet());

    for (ContentVersion content : contentToLink) {
      toReturn.add(
        new ContentDocumentLink(
          ContentDocumentId = content.ContentDocumentId,
          LinkedEntityId = claimId
        )
      );
      if (
        fileIdsToObjects.get(content.Id) != null &&
        fileIdsToObjects.get(content.Id).Id != claimId
      ) {
        toReturn.add(
          new ContentDocumentLink(
            ContentDocumentId = content.ContentDocumentId,
            LinkedEntityId = fileIdsToObjects.get(content.Id).Id
          )
        );
      }
    }

    return toReturn;
  }

  private static ClaimExpense createClaimExpense(
    CreateClaimRequest.Expense expense,
    Claim parentClaim
  ) {
    ClaimExpense ce = new ClaimExpense(parentClaim);
    ce.amount = expense.amount;
    ce.currencyOfAmount = expense.expenseCurrency;
    ce.type = expense.type;
    ce.updateSObjectFields();
    return ce;
  }

  private static ClaimCustomer createCustomer(
    CreateClaimRequest.Traveler traveler,
    Claim parentClaim
  ) {
    ClaimCustomer c = new ClaimCustomer(parentClaim);
    c.firstName = traveler.firstName;
    c.lastName = traveler.lastName;
    c.updateSObjectFields();
    return c;
  }

  private static ClaimRebookedFlight createRebookedFlight(
    CreateClaimRequest.RebookedFlight rebookedFlight,
    Claim parentClaim
  ) {
    ClaimRebookedFlight rf = new ClaimRebookedFlight(parentClaim);
    rf.departureDate = rebookedFlight.departureDate;
    rf.flightNumber = rebookedFlight.flightNumber;
    rf.updateSObjectFields();
    return rf;
  }
}
