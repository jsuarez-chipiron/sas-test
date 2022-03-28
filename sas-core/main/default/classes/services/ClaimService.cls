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
    'accident-and-injury' => 'Accident &amp; injury',
    'accommodation' => 'Accommodation',
    'baggage-damaged' => 'Baggage damaged',
    'baggage-delayed' => 'Baggage delayed/lost',
    'baggage' => 'Baggage',
    'booking-error' => 'Booking error',
    'cabin-environment' => 'Cabin environment',
    'complaint-about-refund' => 'Complaint about a refund',
    'corporate' => 'Corporate customer',
    'denied-boarding' => 'Denied boarding',
    'downgrading' => 'Downgrading',
    'eurobonus' => 'EuroBonus Points',
    'extra-baggage' => 'Extra baggage',
    'flight-cancellation' => 'Flight cancellation',
    'flight-delay' => 'Flight delay',
    'flight-disruptions' => 'Flight disruptions',
    'food' => 'Food',
    'foodborne-illness' => 'Foodborne illness',
    'gate-issues' => 'Gate issues',
    'in-flight-meal' => 'In-flight meal',
    'in-flight-service' => 'In-flight service',
    'lounge' => 'Lounge',
    'missed-connection' => 'Missed connection',
    'monetary' => 'Monetary',
    'never-arrived' => 'Never arrived',
    'other-representative' => 'Other representative',
    'other' => 'Other',
    'personal-injury' => 'Personal injury',
    'phone-calls' => 'Phone calls',
    'prepaid-seat' => 'Prepaid seat',
    'private' => 'Private customer',
    'problems-at-the-airport' => 'Problems at the airport',
    'problems-during-flight' => 'Problems during flight',
    'problems-with-my-booking' => 'Problems with my booking',
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
    Case caseToCreate = new Case(
      Initially_Provided_PNR__c = form.formData.bookingReference,
      Description = form.formData.comment,
      FCS_EBNumber__c = form.formData.euroBonusNumber,
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
        : form.formData.personWithReducedMobility,
      Contact_Email__c = form.formData.email,
      Contact_First_Name__c = form.formData.firstName,
      Contact_Last_Name__c = form.formData.lastName,
      Currency__c = form.formData.preferredCurrency == null
        ? null
        : form.formData.preferredCurrency.toUppercase(),
      Customer_Claim_Category__c = jsonToPicklist.get(
        form.formData.claimCategory
      ),
      Customer_Claim_Type__c = jsonToPicklist.get(form.formData.claimType),
      Customer_s_Reference__c = form.formData.referenceNumber,
      EuroBonus_Number__c = form.formData.euroBonusNumber,
      Flight_Date__c = form.formData.departureDate == null
        ? null
        : Date.valueOf(form.formData.departureDate),
      Flight_Number__c = form.formData.flightNumber,
      Name = insertedCase.CaseNumber,
      Ticket_Number__c = form.formData.ticketNumber,
      Liability_PNR__c = form.formData.bookingReference,
      Phone_Number__c = form.formData.phone,
      Postal_Code__c = form.formData.postalCode,
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

    if (form.formData.country != null) {
      claimToCreate.Country__c = [
        SELECT Country_Name__c
        FROM Settlement_Country_Setting__mdt
        WHERE Country_Short_Code__c = :form.formData.country
      ]
      .Country_Name__c;
    }

    if (form.formData.bankCountry != null) {
      claimToCreate.Bank_Country__c = [
        SELECT Country_Name__c
        FROM Settlement_Country_Setting__mdt
        WHERE Country_Short_Code__c = :form.formData.bankCountry
      ]
      .Country_Name__c;
    }

    if (form.formData.bankAccountNumber != null) {
      if (form.formData.bankRoutingNumber != null) {
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
        contentIds.add(Id.valueOf(contentId));
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
            fileIdsToObjects.put(contentId, expenseToCreate);
            contentIds.add(Id.valueOf(contentId));
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
            fileIdsToObjects.put(contentId, flightToCreate);
            contentIds.add(Id.valueOf(contentId));
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
