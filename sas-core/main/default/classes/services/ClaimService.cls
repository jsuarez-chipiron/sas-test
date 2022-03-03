public without sharing class ClaimService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Claims DK',
    'no-no' => 'Form - Claims NO',
    'se-sv' => 'Form - Claims SE',
    'default' => 'Form - Claims International'
  };
  private static ClaimsSelector claims = ClaimsSelector.newInstance();

  private static Group claimsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Customer_Claim'
  ];

  public static String createClaim(CaseFormJSON2Apex form) {
    Case caseToCreate = new Case(
      Initially_Provided_PNR__c = form.formData.euroBonusNumber,
      FCS_EBNumber__c = form.formData.euroBonusNumber,
      OwnerId = claimsQueue.Id,
      Origin = marketToOrigin.get(form.metaData.market) == null
        ? marketToOrigin.get('default')
        : marketToOrigin.get(form.metaData.market),
      SuppliedEmail = form.formData.email,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL, // TODO: Get correct record type.
      Subject = 'Customer claim' // TODO: What subject?
    );

    // Auto-response emails are not triggered by default for cases created
    // through Apex. Setting the triggerAutoResponseEmail header forces
    // them to be sent.
    Database.DMLOptions DMLOptions = new Database.DMLOptions();
    DMLOptions.EmailHeader.triggerAutoResponseEmail = true;

    database.insert(caseToCreate, DMLOptions);

    LIA_Claim__c claimToCreate = new LIA_Claim__c(
      Address_line_1__c = form.formData.address,
      Bank_Account_Number__c = form.formData.bankAccountNumber,
      Bank_Account_Holder_Name__c = form.formData.bankAccountHolderName,
      Bank_Country__c = form.formData.bankCountry == null
        ? null
        : form.formData.bankCountry,
      Bank_Name__c = form.formData.bankName,
      BIC_Swift__c = form.formData.bankBic,
      Case__c = caseToCreate.Id,
      City__c = form.formData.city,
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
      Country__c = form.formData.country == null ? null : form.formData.country,
      Currency__c = form.formData.preferredCurrency == null
        ? null
        : form.formData.preferredCurrency,
      Customer_Claim_Category__c = 'Flight disruptions' /* form.formData.claimCategory == null
        ? null
        : form.formData.claimCategory,*/,
      EuroBonus_Number__c = form.formData.euroBonusNumber,
      Flight_Date__c = form.formData.departureDate == null
        ? null
        : Date.valueOf(form.formData.departureDate),
      Flight_Number__c = form.formData.flightNumber,
      Ticket_Number__c = form.formData.ticketNumber,
      Liability_PNR__c = form.formData.bookingReference,
      Phone_Number__c = form.formData.phone, // TODO: Check how to handle this without failing.
      Postal_Code__c = form.formData.postalCode,
      PIR__c = form.formData.passengerIrregularityReportNumber,
      Total_delay_to_final_destination__c = form.formData.delayLength == null
        ? null
        : form.formData.delayLength,
      Type_of_Customer__c = 'Private customer' // TODO: Fix me.
    );
    insert claimToCreate;

    List<SObject> objectsToCreate = new List<SObject>();

    if (form.formData.travelers != null) {
      for (CaseFormJSON2Apex.Traveler t : form.formData.travelers) {
        Customer__c customerToCreate = new Customer__c(
          Claim__c = claimToCreate.Id,
          First_Name__c = t.firstName,
          Last_Name__c = t.lastName
        );
        objectsToCreate.add(customerToCreate);
      }
    }

    if (form.formData.expenses != null) {
      for (CaseFormJSON2Apex.Expense e : form.formData.expenses) {
        Claim_Expense__c expenseToCreate = new Claim_Expense__c(
          Claim__c = claimToCreate.Id,
          Amount__c = e.amount,
          Currency__c = e.expenseCurrency,
          Type__c = e.expenseType
        );
        objectsToCreate.add(expenseToCreate);
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
      }
    }

    if (objectsToCreate.size() > 0) {
      insert objectsToCreate;
    }

    Case insertedCase = [
      SELECT CaseNumber
      FROM Case
      WHERE Id = :caseToCreate.Id
    ];

    return insertedCase.CaseNumber;
  }

  @future(callout=true)
  public static void checkIfClaimsExistInCARE(
    Id claimId,
    String bookingReference
  ) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();

    LIA_Claim__c claim = claims.selectById(new Set<Id>{ claimId })[0];
    claim.Claims_Exist_In_CARE_For_PNR__c = ClaimsIntegrationService.checkIfClaimsExistForBookingReference(
      bookingReference
    );
    claim.Last_Checked_Claims_From_CARE__c = Datetime.now();

    uow.registerDirty(claim);
    uow.commitWork();
  }
}
