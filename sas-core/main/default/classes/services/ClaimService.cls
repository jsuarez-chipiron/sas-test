public without sharing class ClaimService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Claims DK',
    'no-no' => 'Form - Claims NO',
    'se-sv' => 'Form - Claims SE',
    'default' => 'Form - Claims International'
  };

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
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

  private static ClaimsSelector claimsSel = ClaimsSelector.newInstance();

  private static Group claimsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Customer_Claim'
  ];

  public static String createClaim(CaseFormJSON2Apex form) {
    String ebNumber;

    try {
      ebNumber = Accounts.parseIntoEuroBonusNumber(
        form.formData.euroBonusNumber
      );
    } catch (Exception e) {
      // Failed to parse, we can ignore this and leave the EB number as blank.
    }

    Case caseToCreate = new Case(
      Initially_Provided_PNR__c = form.formData.bookingReference,
      Description = form.formData.comment,
      FCS_EBNumber__c = ebNumber,
      OwnerId = claimsQueue.Id,
      Origin = marketToOrigin.get(form.metaData.market) == null
        ? marketToOrigin.get('default')
        : marketToOrigin.get(form.metaData.market),
      SuppliedEmail = form.formData.email,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Claim, PNR: ' + form.formData.bookingReference
    );

    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    Case insertedCase = [
      SELECT CaseNumber
      FROM Case
      WHERE Id = :caseToCreate.Id
    ];

    LIA_Claim__c claimToCreate = new LIA_Claim__c(
      Address_line_1__c = form.formData.address,
      Bank_Account_Holder_Name__c = form.formData.bankAccountHolderName,
      Bank_Name__c = form.formData.bankName,
      BIC_Swift__c = form.formData.bankBic,
      Case__c = caseToCreate.Id,
      City__c = form.formData.city,
      Comment__c = form.formData.comment,
      Company_Code__c = form.formData.companyCode,
      Company_Name__c = form.formData.companyName,
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
      Name = insertedCase.CaseNumber,
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
      RecordTypeId = Claims.getRecordTypeId(Claims.RecordType.CustomerClaim),
      Total_delay_to_final_destination__c = jsonToPicklist.get(
        form.formData.delayLength
      ),
      Type_of_Customer__c = jsonToPicklist.get(form.formData.contactType)
    );

    if (!String.isBlank(form.formData.country)) {
      claimToCreate.Country__c = [
        SELECT Country_Name__c
        FROM Settlement_Country_Setting__mdt
        WHERE Country_Short_Code__c = :form.formData.country
      ]
      .Country_Name__c;
    }

    if (!String.isBlank(form.formData.bankCountry)) {
      claimToCreate.Bank_Country__c = [
        SELECT Country_Name__c
        FROM Settlement_Country_Setting__mdt
        WHERE Country_Short_Code__c = :form.formData.bankCountry
      ]
      .Country_Name__c;
    }

    if (!String.isBlank(form.formData.bankAccountNumber)) {
      if (!String.isBlank(form.formData.bankRoutingNumber)) {
        // US bank account numbers should be sent to Racer as {accountNumber}ABA{routingNumber}
        // Other countries have only an account number.
        claimToCreate.Bank_Account_Number__c =
          form.formData.bankAccountNumber.replace(' ', '') +
          'ABA' +
          form.formData.bankRoutingNumber.replace(' ', '');
      } else {
        claimToCreate.Bank_Account_Number__c = form.formData.bankAccountNumber.replace(
          ' ',
          ''
        );
      }
    }

    insert claimToCreate;

    ContentVersionsSelector contentVersions = ContentVersionsSelector.newInstance();

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

    if (form.formData.travelers != null) {
      for (CaseFormJSON2Apex.Traveler t : form.formData.travelers) {
        Customer__c customerToCreate = new Customer__c(
          Claim__c = claimToCreate.Id,
          First_Name__c = t.firstName == null ? ' ' : t.firstName,
          Last_Name__c = t.lastName == null ? ' ' : t.lastName
        );
        objectsToCreate.add(customerToCreate);
      }
    }

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

    if (form.formData.rebookedFlights != null) {
      for (CaseFormJSON2Apex.Flight f : form.formData.rebookedFlights) {
        Claim_Rebooked_Flight__c flightToCreate = new Claim_Rebooked_Flight__c(
          Claim__c = claimToCreate.Id,
          Departure_Date__c = Date.valueOf(f.departureDate),
          Flight_Number__c = f.flightNumber
        );
        objectsToCreate.add(flightToCreate);

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

    List<ContentVersion> contentToLink = contentVersions.selectById(contentIds);
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

    insertedCase.LIA_Claim__c = claimToCreate.Id;
    update insertedCase;

    return insertedCase.CaseNumber;
  }

  public static String createCompensationCardClaim(CaseFormJSON2Apex form) {
    //new Case();
    //new LIA_Claim__c();

    //return insertedCase.CaseNumber;
    return '';
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
  @future(callout=true)
  public static void attemptToRedeemCompensationCardClaim(Id claimId) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    LIA_Claim__c claim = ClaimsSelector.newInstance()
      .selectById(new Set<Id>{ claimId })[0];

    Compensation_Card__c validatedCompensationCard;

    Boolean cardHasBeenPaidOut = CompensationCards.hasBeenPaidOut(
      claim.Compensation_Card_Number__c,
      claim.Liability_PNR__c
    );

    Boolean canBeRedeemed = false;
    if (!cardHasBeenPaidOut) {
      try {
        // Check Voucher API whether this is a valid compensation card number and
        // a matching PNR.
        VoucherValidateResponse response = VoucherIntegrationService.newInstance()
          .validateVoucher(
            claim.Compensation_Card_Number__c,
            claim.Liability_PNR__c
          );
        validatedCompensationCard = CompensationCards.createFromValidVoucher(
          claim.Compensation_Card_Number__c,
          response,
          claim.Id,
          uow
        );
        canBeRedeemed = true;
      } catch (VoucherIntegrationService.InvalidVoucherException e) {
        C_Log.log(
          C_Log.Severity.Info,
          'Invalid compensation card redeem request.',
          null,
          'Claims',
          null
        );
      } catch (Exception e) {
        // TODO: Error handling? Can we reject the claim or should we ask the customer to try again?
        C_Log.log(
          C_Log.Severity.Error,
          'Uncaught exception while redeeming a compensation card.',
          e.getStackTraceString(),
          'Claims',
          null
        );
      }
    }

    if (canBeRedeemed) {
      Settlements.createFromCompensationCard(
        new List<LIA_Claim__c>{ claim },
        new Map<Id, Compensation_Card__c>{
          claim.Id => validatedCompensationCard
        },
        uow
      );
      uow.commitWork();

      try {
        fflib_ISObjectUnitOfWork uow2 = SAS_Service_Application.UnitOfWork.newInstance();
        Claims.newInstance(new List<LIA_Claim__c>{ claim }).settle(uow2);
        Cases.newInstance(
            CasesSelector.newInstance().selectById(new Set<Id>{ claim.Case__c })
          )
          .close(uow2);
        // TODO: Send email Email.toEmail.

        uow2.commitWork();
      } catch (Exception e) {
        // Different logic for validation error than for others.
        // Something failed
        fflib_ISObjectUnitOfWork uow3 = SAS_Service_Application.UnitOfWork.newInstance();
        Settlements.newInstance(
            SettlementsSelector.newInstance()
              .selectByClaimId(new Set<Id>{ claim.Id })
          )
          .markAsFailed(e.getMessage(), uow3);

        uow3.commitWork();
      }
    } else {
      fflib_ISObjectUnitOfWork rejectedUow = SAS_Service_Application.UnitOfWork.newInstance();
      // Claims.newInstance(new List<LIA_Claim__c>{ claim }).reject(rejectedUow);
      Cases.newInstance(
          CasesSelector.newInstance().selectById(new Set<Id>{ claim.Case__c })
        )
        .close(uow2);
      rejectedUow.commitWork();
      // TODO: Send email
    }
  }

  @future(callout=true)
  public static void checkIfClaimsExistInCARE(
    Id claimId,
    String bookingReference
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    LIA_Claim__c claim = claimsSel.selectById(new Set<Id>{ claimId })[0];
    claim.Claims_Exist_In_CARE_For_PNR__c = ClaimsIntegrationService.checkIfClaimsExistForBookingReference(
      bookingReference
    );
    claim.Last_Checked_Claims_From_CARE__c = Datetime.now();

    uow.registerDirty(claim);
    uow.commitWork();
  }
}
