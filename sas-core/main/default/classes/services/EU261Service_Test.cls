@IsTest
private class EU261Service_Test {
  private static final String NOT_ELIGIBLE_FLIGHT_TEDS_ID = 'SK0002-20220817';
  private static final Date NOT_ELIGIBLE_FLIGHT_DATE = Date.parse('2022-08-17');
  private static final String NOT_ELIGIBLE_FLIGHT_NUMBER = 'SK0002';
  private static final String NOT_ELIGIBLE_REBOOKED_FLIGHT_TEDS_ID = 'SK0003-20220817';
  private static final List<String> NOT_ELIGIBLE_FLIGHT_TEDS_IDS = new List<String>{
    NOT_ELIGIBLE_FLIGHT_TEDS_ID,
    NOT_ELIGIBLE_REBOOKED_FLIGHT_TEDS_ID
  };

  private static final String ELIGIBLE_FLIGHT_NUMBER = 'SK0001';
  private static final String ELIGIBLE_FLIGHT_TEDS_ID = 'SK0001-20220817';
  private static final String ELIGIBLE_REBOOKED_FLIGHT_TEDS_ID = 'SK0001-20220818';
  private static final List<String> ELIGIBLE_FLIGHT_TEDS_IDS = new List<String>{
    ELIGIBLE_FLIGHT_TEDS_ID,
    ELIGIBLE_REBOOKED_FLIGHT_TEDS_ID
  };

  private static final String CARE_DUPLICATE_BOOKING_REFERENCE = 'CAREDU';
  private static final String DUPLICATE_BOOKING_REFERENCE = 'DUPLIC';

  @TestSetup
  static void setup() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Cases.bypassTrigger = true;

    TestDataFactories.insertEmailTemplates(
      new Set<String>{
        EU261Service.AUTOMATION_APPROVED_EMAIL_TEMPLATE_NAME,
        EU261Service.AUTOMATION_REJECTED_EMAIL_TEMPLATE_NAME
      }
    );

    List<SObject> objectsToCreate = new List<SObject>();

    objectsToCreate.add(
      new Exchange_Rate__c(
        From_Currency__c = 'EUR',
        To_Currency__c = 'SEK',
        Rate__c = 10,
        Date__c = Date.valueOf('2022-10-31'),
        Name = 'EUR-SEK'
      )
    );

    objectsToCreate.add(
      new Exchange_Rate__c(
        From_Currency__c = 'SEK',
        To_Currency__c = 'EUR',
        Rate__c = 0.1,
        Date__c = Date.valueOf('2022-10-31'),
        Name = 'EUR-SEK'
      )
    );

    Flight__c eligibleCancelledFlight = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = ELIGIBLE_FLIGHT_TEDS_ID,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0)
    );
    Flight__c replacementForEligibleCancelledFlight = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = ELIGIBLE_REBOOKED_FLIGHT_TEDS_ID,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0)
    );
    Flight__c notEligibleCancelledFlight = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = NOT_ELIGIBLE_FLIGHT_TEDS_ID,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 2, 1, 0)
    );
    Flight__c replacementForNotEligibleCancelledFlight = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = NOT_ELIGIBLE_REBOOKED_FLIGHT_TEDS_ID,
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 17, 1, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 17, 3, 1, 0)
    );
    objectsToCreate.add(eligibleCancelledFlight);
    objectsToCreate.add(replacementForEligibleCancelledFlight);
    objectsToCreate.add(notEligibleCancelledFlight);
    objectsToCreate.add(replacementForNotEligibleCancelledFlight);

    objectsToCreate.add(
      new Airport__c(
        City__c = 'Helsinki',
        Country_Code__c = 'FI',
        Country_Name__c = 'Finland',
        TEDS_Identifier__c = 'HEL',
        Is_EU261_Applicable__c = true,
        Latitude__c = 60.317199707031,
        Longitude__c = 24.963300704956
      )
    );
    objectsToCreate.add(
      new Airport__c(
        City__c = 'Copenhagen',
        Country_Code__c = 'DK',
        Country_Name__c = 'Denmark',
        TEDS_Identifier__c = 'CPH',
        Is_EU261_Applicable__c = true,
        Latitude__c = 55.617900848389,
        Longitude__c = 12.656000137329
      )
    );

    List<Booking__c> bookings = new List<Booking__c>();
    List<Segment__c> segments = new List<Segment__c>();
    List<Passenger__c> passengers = new List<Passenger__c>();

    List<String> simpleBookingReferences = new List<String>();
    simpleBookingReferences.add(CARE_DUPLICATE_BOOKING_REFERENCE);
    simpleBookingReferences.add(DUPLICATE_BOOKING_REFERENCE);

    for (Integer i = 0; i < 14; i++) {
      simpleBookingReferences.add(String.valueOf(i).leftPad(6, '0'));
    }

    for (String pnr : simpleBookingReferences) {
      bookings.add(
        new Booking__c(
          Booking_Reference__c = pnr,
          TEDS_Identifier__c = pnr,
          Type__c = 'OneWay'
        )
      );
    }

    objectsToCreate.addAll(bookings);
    insert objectsToCreate;

    for (Booking__c b : bookings) {
      segments.add(
        new Segment__c(
          Booking__c = b.Id,
          Flight__c = eligibleCancelledFlight.Id,
          Seat__c = '1A',
          Trip_Type__c = 'Cancelled'
        )
      );
      segments.add(
        new Segment__c(
          Booking__c = b.Id,
          Flight__c = replacementForEligibleCancelledFlight.Id,
          Seat__c = '1A',
          Trip_Type__c = 'Outbound'
        )
      );

      passengers.add(
        new Passenger__c(
          Booking__c = b.Id,
          Identifier__c = 'P1',
          First_Name__c = 'Sven',
          Last_Name__c = 'Svensson'
        )
      );
    }

    FlightIrregularities__c eligibleIrregularity = new FlightIrregularities__c(
      Flight__c = eligibleCancelledFlight.Id,
      Code__c = 'TECH',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = DateTime.newInstance(2022, 8, 10, 0, 1, 0)
    );
    FlightIrregularities__c notEligibleIrregularity = new FlightIrregularities__c(
      Flight__c = notEligibleCancelledFlight.Id,
      Code__c = 'TECH',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = DateTime.newInstance(2022, 8, 10, 0, 1, 0)
    );

    List<SObject> toInsert = new List<SObject>();
    toInsert.addAll(segments);
    toInsert.addAll(passengers);
    toInsert.add(eligibleIrregularity);
    toInsert.add(notEligibleIrregularity);
    insert toInsert;

    List<TestDataFactories.CasesClaims> allClaims = new List<TestDataFactories.CasesClaims>();

    for (String pnr : simpleBookingReferences) {
      allClaims.add(createDefaultTestClaim(pnr, null));
    }
    allClaims.add(createDefaultTestClaim(DUPLICATE_BOOKING_REFERENCE, null));

    createCaseToBookings(allClaims);

    Cases.bypassTrigger = false;
  }

  private static void createCaseToBookings(
    List<TestDataFactories.CasesClaims> casesClaims
  ) {
    List<String> pnrs = new List<String>();

    for (TestDataFactories.CasesClaims c : casesClaims) {
      pnrs.add(c.cases[0].Initially_Provided_PNR__c);
    }

    List<Booking__c> bookings = [
      SELECT Id, Booking_Reference__c
      FROM Booking__c
      WHERE Booking_Reference__c IN :pnrs
    ];

    List<SObject> toInsert = new List<SObject>();

    for (Booking__c b : bookings) {
      for (TestDataFactories.CasesClaims c : casesClaims) {
        if (c.cases[0].Initially_Provided_PNR__c == b.Booking_Reference__c) {
          toInsert.add(
            new CaseToBooking__c(Booking__c = b.Id, Case__c = c.cases[0].Id)
          );
        }
      }
    }

    insert toInsert;
  }

  private static TestDataFactories.CasesClaims createDefaultTestClaim(
    String bookingReference,
    Map<Schema.SObjectField, Object> extraClaimFields
  ) {
    Map<Schema.SObjectField, Object> claimFields = new Map<Schema.SObjectField, Object>{
      LIA_Claim__c.Address_line_1__c => 'Frösundaviks allé 1',
      LIA_Claim__c.Bank_Account_Holder_Name__c => 'Test testsson',
      LIA_Claim__c.Bank_Account_Number__c => 'SE7280000810340009783242',
      LIA_Claim__c.Bank_Country__c => 'Sweden',
      LIA_Claim__c.BIC_Swift__c => 'CITIUS33',
      LIA_Claim__c.City__c => 'Solna',
      LIA_Claim__c.Contact_Email__c => 'test@example.com',
      LIA_Claim__c.Contact_First_Name__c => 'Sven',
      LIA_Claim__c.Contact_Last_Name__c => 'Svensson',
      LIA_Claim__c.Country__c => 'Sweden',
      LIA_Claim__c.Currency__c => 'SEK',
      LIA_Claim__c.Customer_Claim_Category__c => 'Flight disruptions',
      LIA_Claim__c.Customer_Claim_Type__c => 'Flight cancellation',
      LIA_Claim__c.EuroBonus_Number__c => '123456789',
      LIA_Claim__c.Flight_Number__c => 'SK0001',
      LIA_Claim__c.Flight_Date__c => Date.parse('2022-08-17'),
      LIA_Claim__c.Liability_PNR__c => bookingReference,
      LIA_Claim__c.Postal_Code__c => '11200',
      LIA_Claim__c.Preferred_Compensation_Method__c => 'Monetary',
      LIA_Claim__c.RecordTypeId => Claim.getRecordTypeIdByEnum(
        Claim.RecordType.CustomerClaim
      ),
      LIA_Claim__c.Type_of_Customer__c => 'Private customer'
    };
    if (extraClaimFields != null) {
      claimFields.putAll(extraClaimFields);
    }

    TestDataFactories.CasesClaims toReturn = TestDataFactories.createCasesWithClaims(
      1,
      new Map<Schema.SObjectField, Object>{
        Case.Initially_Provided_PNR__c => bookingReference
      },
      claimFields
    );

    insert new Customer__c(
      First_Name__c = 'Sven',
      Last_Name__c = toReturn.claims[0].Contact_Last_Name__c,
      Claim__c = toReturn.claims[0].Id
    );

    return toReturn;
  }

  private class Result {
    /**
     * Cases from DB after EU261 processing
     */
    public List<Case> cases;
    /**
     * Claims from DB after EU261 processing
     */
    public List<LIA_Claim__c> claims;
    /**
     * Settlements from DB after EU261 processing
     */
    public List<Settlement__c> settlements;
  }

  private static Result runProcessingFor(
    List<String> bookingReferences,
    EU261Service.Config serviceConfig
  ) {
    Set<Id> claimIds = (new Map<Id, LIA_Claim__c>(
        [
          SELECT Id
          FROM LIA_Claim__c
          WHERE Liability_PNR__c IN :bookingReferences
        ]
      ))
      .keySet();

    EU261Service es = EU261Service.newInstance();
    if (serviceConfig != null) {
      es.config = serviceConfig;
    } else {
      es.config.enabledSettlements = true;
      es.config.enabledRejections = true;
      es.config.enabledSemiAutomation = true;
      es.config.percentageRequiringManualApproval = 0;
    }

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    es.processEU261Claims(claimIds);
    Test.stopTest();

    Result res = new Result();

    res.settlements = SettlementsSelector.newInstance()
      .selectByClaimId(claimIds);
    res.cases = [
      SELECT Id, EU261_Handling_Instructions__c, Status
      FROM Case
      WHERE LIA_Claim__c IN :claimIds
    ];
    res.claims = ClaimsSelector.newInstance().selectById(claimIds);

    return res;
  }
  private static Result runProcessingFor(List<String> bookingReferences) {
    return runProcessingFor(bookingReferences, null);
  }

  @IsTest
  static void nothingShouldBeCreatedIfAutomationIsDisabled() {
    EU261Service.Config config = new EU261Service.Config();
    config.enabledRejections = false;
    config.enabledSemiAutomation = false;
    config.enabledSettlements = false;
    Result res = runProcessingFor(
      new List<String>{ '000001', '000002', '000003' },
      config
    );

    System.assertEquals(
      0,
      res.settlements.size(),
      'No settlements should have been created when automation is disabled.'
    );
    System.assertEquals(
      3,
      res.claims.size(),
      'Should have found the correct number of claims.'
    );
    System.assertEquals(
      3,
      res.cases.size(),
      'Should have found the correct number of cases.'
    );

    for (Case c : res.cases) {
      System.assertEquals(
        Cases.STATUS_NEW,
        c.Status,
        'All cases should still be in new'
      );
    }
  }

  @IsTest
  static void ineligibleClaimsAreRejectedAutomatically() {
    List<String> testPnrs = new List<String>{ 'REJEC1', 'REJEC2' };
    Id originalFlightId;
    Id rebookedFlightId;
    for (Flight__c f : [
      SELECT Id, TEDS_Identifier__c
      FROM Flight__c
      WHERE TEDS_Identifier__c IN :NOT_ELIGIBLE_FLIGHT_TEDS_IDS
    ]) {
      if (f.TEDS_Identifier__c == NOT_ELIGIBLE_FLIGHT_TEDS_ID) {
        originalFlightId = f.Id;
      } else {
        rebookedFlightId = f.Id;
      }
    }

    List<Booking__c> bookings = new List<Booking__c>();
    List<Segment__c> segments = new List<Segment__c>();
    List<Passenger__c> passengers = new List<Passenger__c>();

    for (String pnr : testPnrs) {
      bookings.add(
        new Booking__c(
          Booking_Reference__c = pnr,
          TEDS_Identifier__c = pnr,
          Type__c = 'OneWay'
        )
      );
    }

    insert bookings;

    for (Booking__c b : bookings) {
      segments.add(
        new Segment__c(
          Booking__c = b.Id,
          Flight__c = originalFlightId,
          Seat__c = '1A',
          Trip_Type__c = 'Cancelled'
        )
      );
      segments.add(
        new Segment__c(
          Booking__c = b.Id,
          Flight__c = rebookedFlightId,
          Seat__c = '1A',
          Trip_Type__c = 'Outbound'
        )
      );

      passengers.add(
        new Passenger__c(
          Booking__c = b.Id,
          Identifier__c = 'P1',
          First_Name__c = 'Sven',
          Last_Name__c = 'Svensson'
        )
      );
    }

    List<SObject> toInsert = new List<SObject>();
    toInsert.addAll(segments);
    toInsert.addAll(passengers);
    insert toInsert;

    Cases.bypassTrigger = true;
    List<TestDataFactories.CasesClaims> allClaims = new List<TestDataFactories.CasesClaims>();

    for (String pnr : testPnrs) {
      allClaims.add(
        createDefaultTestClaim(
          pnr,
          new Map<Schema.SObjectField, Object>{
            LIA_Claim__c.Flight_Number__c => NOT_ELIGIBLE_FLIGHT_NUMBER,
            LIA_Claim__c.Flight_Date__c => NOT_ELIGIBLE_FLIGHT_DATE
          }
        )
      );
    }

    createCaseToBookings(allClaims);
    Cases.bypassTrigger = false;

    Result res = runProcessingFor(testPnrs);

    System.assertEquals(
      0,
      res.settlements.size(),
      'No settlements should have been created for rejected claims.'
    );
    System.assertEquals(
      2,
      res.claims.size(),
      'All processed claims should have been rejected.'
    );
    System.assertEquals(
      2,
      res.cases.size(),
      'Cases should exist for all claims.'
    );

    for (LIA_Claim__c cl : res.claims) {
      System.assertEquals(
        'Ineligible for compensation',
        cl.EU261_Handling_Status__c,
        'Handling status should have been set to ineligible for compensation'
      );
    }

    for (Case c : res.cases) {
      System.assertEquals(
        'Closed',
        c.Status,
        'Rejected cases should have been closed'
      );
    }
  }

  @IsTest
  static void eligibleAndSimpleClaimsAreSettledCorrectly() {
    List<String> testPnrs = new List<String>{
      'VALID1',
      'VALID2',
      'VALID3',
      'VALID4'
    };
    Id originalFlightId;
    Id rebookedFlightId;
    for (Flight__c f : [
      SELECT Id, TEDS_Identifier__c
      FROM Flight__c
      WHERE TEDS_Identifier__c IN :ELIGIBLE_FLIGHT_TEDS_IDS
    ]) {
      if (f.TEDS_Identifier__c == ELIGIBLE_FLIGHT_TEDS_ID) {
        originalFlightId = f.Id;
      } else {
        rebookedFlightId = f.Id;
      }
    }

    List<Booking__c> bookings = new List<Booking__c>();
    List<Segment__c> segments = new List<Segment__c>();
    List<Passenger__c> passengers = new List<Passenger__c>();

    for (String pnr : testPnrs) {
      bookings.add(
        new Booking__c(
          Booking_Reference__c = pnr,
          TEDS_Identifier__c = pnr,
          Type__c = 'OneWay'
        )
      );
    }

    insert bookings;

    for (Booking__c b : bookings) {
      segments.add(
        new Segment__c(
          Booking__c = b.Id,
          Flight__c = originalFlightId,
          Seat__c = '1A',
          Trip_Type__c = 'Cancelled'
        )
      );
      segments.add(
        new Segment__c(
          Booking__c = b.Id,
          Flight__c = rebookedFlightId,
          Seat__c = '1A',
          Trip_Type__c = 'Outbound'
        )
      );

      passengers.add(
        new Passenger__c(
          Booking__c = b.Id,
          Identifier__c = 'P1',
          First_Name__c = 'Sven',
          Last_Name__c = 'Svensson'
        )
      );
    }

    List<SObject> toInsert = new List<SObject>();
    toInsert.addAll(segments);
    toInsert.addAll(passengers);
    insert toInsert;

    Cases.bypassTrigger = true;

    TestDataFactories.CasesClaims testClaimInEUR = createDefaultTestClaim(
      'VALID1',
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Bank_Account_Number__c => 'FI1410093000123458',
        LIA_Claim__c.Bank_Country__c => 'Finland',
        LIA_Claim__c.Country__c => 'Finland',
        LIA_Claim__c.Currency__c => 'EUR'
      }
    );

    TestDataFactories.CasesClaims testClaimInSEK = createDefaultTestClaim(
      'VALID2',
      null
    );

    TestDataFactories.CasesClaims testClaimInEBPoints = createDefaultTestClaim(
      'VALID3',
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Preferred_Compensation_Method__c => 'EuroBonus Points'
      }
    );

    TestDataFactories.CasesClaims testClaimInVoucher = createDefaultTestClaim(
      'VALID4',
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Preferred_Compensation_Method__c => 'Voucher'
      }
    );

    createCaseToBookings(
      new List<TestDataFactories.CasesClaims>{
        testClaimInEUR,
        testClaimInSEK,
        testClaimInEBPoints,
        testClaimInVoucher
      }
    );
    Cases.bypassTrigger = false;

    Result res = runProcessingFor(testPnrs);

    System.assertEquals(4, res.claims.size(), 'All claims should be found.');
    for (LIA_Claim__c cl : res.claims) {
      System.assertEquals(
        'Eligible for compensation',
        cl.EU261_Handling_Status__c,
        'Handling status should have been set to eligible for compensation'
      );
    }

    System.assertEquals(
      4,
      res.cases.size(),
      'Cases should exist for all claims.'
    );
    for (Case c : res.cases) {
      System.assertEquals(
        'Closed',
        c.Status,
        'Valid claim cases should be closed after processing.'
      );
    }

    System.assertEquals(
      4,
      res.settlements.size(),
      'Three settlements should have been created for the claims.'
    );

    for (Settlement__c s : res.settlements) {
      if (s.Claim__c == testClaimInEUR.claims[0].Id) {
        System.assertEquals(
          Settlements.STATUS_WAITING_FOR_TRANSFER,
          s.Settlement_Status__c,
          'Monetary settlement should be waiting for transfer after processing.'
        );
        System.assertEquals(
          Settlements.getRecordTypeId(Settlements.RecordType.Monetary),
          s.RecordTypeId,
          'Settlement type should be monetary if customer has requested compensation as monetary.'
        );
        System.assertEquals(
          250,
          s.Amount__c,
          'Settlement amount in euros should match the original compensation amount.'
        );
        System.assertEquals(
          'EUR',
          s.Currency__c,
          'Monetary settlement should be in euros to Finland.'
        );
      } else if (s.Claim__c == testClaimInSEK.claims[0].Id) {
        System.assertEquals(
          Settlements.STATUS_WAITING_FOR_TRANSFER,
          s.Settlement_Status__c,
          'Monetary settlement should be waiting for transfer after processing.'
        );
        System.assertEquals(
          Settlements.getRecordTypeId(Settlements.RecordType.Monetary),
          s.RecordTypeId,
          'Settlement type should be monetary if customer has requested compensation as monetary.'
        );
        System.assertEquals(
          2500,
          s.Amount__c,
          'Settlement amount in SEK should be equal to exchange rate EUR-SEK times the settlement in euros.'
        );
        System.assertEquals(
          'SEK',
          s.Currency__c,
          'Settlement currency should SEK for Sweden.'
        );
      } else if (s.Claim__c == testClaimInEBPoints.claims[0].Id) {
        System.assertEquals(
          Settlements.STATUS_FAILED,
          s.Settlement_Status__c,
          'Points settlement will fail in testing because it is processed in the same transaction. Savepoints have been created before the normally async callout.'
        );
        System.assertEquals(
          Settlements.getRecordTypeId(Settlements.RecordType.EBPoints),
          s.RecordTypeId,
          'Settlement type should be EB points if customer has requested compensation in points.'
        );
        System.assertEquals(
          25000,
          s.EuroBonus_Points__c,
          'EB points should be equal to 100 times the settlement in euros.'
        );
      } else if (s.Claim__c == testClaimInVoucher.claims[0].Id) {
        System.assertEquals(
          Settlements.STATUS_FAILED,
          s.Settlement_Status__c,
          'Voucher settlement will fail in testing because it is processed in the same transaction. Savepoints have been created before the normally async callout.'
        );
        System.assertEquals(
          Settlements.getRecordTypeId(Settlements.RecordType.Voucher),
          s.RecordTypeId,
          'Settlement type should be voucher if customer has requested compensation as voucher.'
        );
        System.assertEquals(
          500,
          s.Amount__c,
          'Voucher settlements should be double the normal amount.'
        );
        System.assertEquals(
          'EUR',
          s.Currency__c,
          'Voucher settlements should always be in euros.'
        );
      } else {
        System.assert(false, 'Found a non-matching settlement.');
      }
    }
  }
  @IsTest
  static void eligibleClaimsWithLowExpensesAreSettledCorrectly() {
    List<String> testPnrs = new List<String>{ '000008', '000009', '000010' };
    List<LIA_Claim__c> cls = [
      SELECT Id, Case__c, Liability_PNR__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c IN :testPnrs
    ];
    LIA_Claim__c oneExpenseSEKClaim = cls[0];
    LIA_Claim__c oneExpenseEURClaim = cls[1];
    LIA_Claim__c twoExpensesClaim = cls[2];

    Claim_Expense__c singleExpenseSEK = new Claim_Expense__c(
      Amount__c = 5,
      Claim__c = oneExpenseSEKClaim.Id,
      Currency__c = 'SEK',
      Type__c = 'Food'
    );

    Claim_Expense__c singleExpenseEUR = new Claim_Expense__c(
      Amount__c = 5,
      Claim__c = oneExpenseEURClaim.Id,
      Currency__c = 'EUR',
      Type__c = 'Food'
    );

    Claim_Expense__c twoExpensesOne = new Claim_Expense__c(
      Amount__c = 30,
      Claim__c = twoExpensesClaim.Id,
      Currency__c = 'SEK',
      Type__c = 'Food'
    );
    Claim_Expense__c twoExpensesTwo = new Claim_Expense__c(
      Amount__c = 300,
      Claim__c = twoExpensesClaim.Id,
      Currency__c = 'SEK',
      Type__c = 'Transportation'
    );

    insert new List<SObject>{
      singleExpenseSEK,
      singleExpenseEUR,
      twoExpensesOne,
      twoExpensesTwo
    };

    EU261Service.Config config = new EU261Service.Config();
    config.enabledRejections = true;
    config.enabledSemiAutomation = true;
    config.enabledSettlements = true;
    config.expenseLimitFood = new Money(100, Money.CurrencyCode.SEK);
    config.expenseLimitTransportation = new Money(1000, Money.CurrencyCode.SEK);
    config.expenseLimitTotal = new Money(10000, Money.CurrencyCode.SEK);
    config.percentageRequiringManualApproval = 0;

    Result res = runProcessingFor(testPnrs, config);

    System.assertEquals(
      6,
      res.settlements.size(),
      'There should be two settlements per claim.'
    );

    Integer countCompensationSettlements = 0;
    for (Settlement__c s : res.settlements) {
      if (s.Amount__c == 2500) {
        countCompensationSettlements++;
      } else if (s.Claim__c == oneExpenseSEKClaim.Id) {
        System.assertEquals(
          'SEK',
          s.Currency__c,
          'Settlement currency should match customers bank country.'
        );
        System.assertEquals(
          5,
          s.Amount__c,
          'Amount for SEK expenses should be the same.'
        );
      } else if (s.Claim__c == oneExpenseEURClaim.Id) {
        System.assertEquals(
          'SEK',
          s.Currency__c,
          'Settlement currency should match customers bank country.'
        );
        System.assertEquals(
          50,
          s.Amount__c,
          'Amount for euro expenses should be multiplied by conversion rate.'
        );
      } else {
        System.assertEquals(
          'SEK',
          s.Currency__c,
          'Settlement currency should match customers bank country.'
        );
        System.assertEquals(
          330,
          s.Amount__c,
          'Amount for claim with two settlements should be their sum.'
        );
      }
    }

    System.assertEquals(
      3,
      countCompensationSettlements,
      'Three of the settlements should be compensation settlements.'
    );

    // System.assertEquals(expected, actual, '');
  }

  @IsTest
  static void eligibleClaimsWithMoreThanOnePassengerAreSettledCorrectly() {
    String testPnr = '000012';

    Id originalFlightId;
    Id rebookedFlightId;

    for (Flight__c f : [
      SELECT Id, TEDS_Identifier__c
      FROM Flight__c
      WHERE TEDS_Identifier__c IN :ELIGIBLE_FLIGHT_TEDS_IDS
    ]) {
      if (f.TEDS_Identifier__c == ELIGIBLE_FLIGHT_TEDS_ID) {
        originalFlightId = f.Id;
      } else {
        rebookedFlightId = f.Id;
      }
    }

    LIA_Claim__c testClaim = [
      SELECT Id, Case__c, Liability_PNR__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c = :testPnr
    ][0];

    Booking__c b = [
      SELECT Id
      FROM Booking__c
      WHERE Booking_Reference__c = :testPnr
    ];

    List<SObject> toInsert = new List<SObject>();

    toInsert.add(
      new Customer__c(
        Claim__c = testClaim.Id,
        First_Name__c = 'Viktor',
        Last_Name__c = 'Svensson'
      )
    );

    toInsert.add(
      new Passenger__c(
        Booking__c = b.Id,
        First_Name__c = 'Viktor',
        Last_Name__c = 'Svensson',
        Identifier__c = 'PT2'
      )
    );

    toInsert.add(
      new Segment__c(
        Booking__c = b.Id,
        Flight__c = originalFlightId,
        Seat__c = '2A',
        Trip_Type__c = 'Cancelled'
      )
    );
    toInsert.add(
      new Segment__c(
        Booking__c = b.Id,
        Flight__c = rebookedFlightId,
        Seat__c = '2A',
        Trip_Type__c = 'Outbound'
      )
    );

    insert toInsert;
    Result res = runProcessingFor(new List<String>{ testPnr });

    System.assertEquals(1, res.claims.size(), 'There should one claim.');
    System.assertEquals(
      'Eligible for compensation',
      res.claims[0].EU261_Handling_Status__c,
      'Handling status should have been set to eligible for compensation'
    );

    System.assertEquals(1, res.cases.size(), 'There should be one case.');
    System.assertEquals(
      'Closed',
      res.cases[0].Status,
      'Valid claim cases should be closed after processing.'
    );

    System.assertEquals(
      1,
      res.settlements.size(),
      'There should be only one settlement for two customers.'
    );

    Settlement__c s = res.settlements[0];

    List<Settlement_Item__c> settlementItemsForClaim = [
      SELECT Id, Amount__c, Customer_Name__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :s.Id
    ];

    System.assertEquals(
      2,
      settlementItemsForClaim.size(),
      'There should be one settlement item per claim customer.'
    );

    System.assertEquals(
      Settlements.STATUS_WAITING_FOR_TRANSFER,
      s.Settlement_Status__c,
      'Monetary settlement should be waiting for transfer after processing.'
    );
    System.assertEquals(
      Settlements.getRecordTypeId(Settlements.RecordType.Monetary),
      s.RecordTypeId,
      'Settlement type should be monetary if customer has requested compensation as monetary.'
    );
    System.assertEquals(
      5000,
      s.Amount__c,
      'Settlement amount in euros should match the original compensation amount.'
    );
    System.assertEquals(
      'SEK',
      s.Currency__c,
      'Monetary settlement should be in SEK.'
    );

    for (Settlement_Item__c si : settlementItemsForClaim) {
      System.assertEquals(
        2500,
        si.Amount__c,
        'Settlement item amount should be equal to individuals compensation.'
      );
      if (si.Customer_Name__c == 'Viktor Svensson') {
        System.assertEquals(
          'Viktor Svensson',
          si.Customer_Name__c,
          'Settlement item customer names should be based on customer names from claim.'
        );
      } else {
        System.assertEquals(
          'Sven Svensson',
          si.Customer_Name__c,
          'Settlement item customer names should be based on customer names from claim.'
        );
      }
    }
  }

  @IsTest
  static void eligibleClaimsCanEndUpInApproval() {
    EU261Service.Config config = new EU261Service.Config();
    config.enabledRejections = true;
    config.enabledSemiAutomation = true;
    config.enabledSettlements = true;
    config.percentageRequiringManualApproval = 100;

    Result res = runProcessingFor(new List<String>{ '000004' }, config);

    System.assertEquals(
      1,
      res.settlements.size(),
      'Settlement should have been prepared.'
    );
    System.assertEquals(
      1,
      res.claims.size(),
      'Should have found the correct number of claims.'
    );
    System.assertEquals(
      1,
      res.cases.size(),
      'Should have found the correct number of cases.'
    );

    for (Case c : res.cases) {
      System.assertEquals(
        Cases.STATUS_WAITING_FOR_APPROVAL,
        c.Status,
        'Case should be waiting for approval'
      );
    }
    for (Settlement__c s : res.settlements) {
      System.assertEquals(
        Settlements.STATUS_WAITING_FOR_APPROVAL,
        s.Settlement_Status__c,
        'Settlement should be waiting for approval'
      );
    }
  }

  @IsTest
  static void highExpensesCanBeSemiAutomated() {
    List<String> testPnrs = new List<String>{ '000005', '000006', '000007' };
    List<LIA_Claim__c> cls = [
      SELECT Id, Case__c, Liability_PNR__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c IN :testPnrs
    ];
    LIA_Claim__c claimOverFoodLimit;
    LIA_Claim__c claimOverTotalLimit;
    LIA_Claim__c validClaim;
    for (LIA_Claim__c cl : cls) {
      if (cl.Liability_PNR__c == '000005') {
        claimOverFoodLimit = cl;
      } else if (cl.Liability_PNR__c == '000006') {
        claimOverTotalLimit = cl;
      } else {
        validClaim = cl;
      }
    }

    Claim_Expense__c foodOverLimitExpense = new Claim_Expense__c(
      Amount__c = 20,
      Claim__c = claimOverFoodLimit.Id,
      Currency__c = 'SEK',
      Type__c = 'Food'
    );

    Claim_Expense__c foodUnderLimitExpense = new Claim_Expense__c(
      Amount__c = 8,
      Claim__c = claimOverTotalLimit.Id,
      Currency__c = 'SEK',
      Type__c = 'Food'
    );
    Claim_Expense__c transportationUnderLimitExpense = new Claim_Expense__c(
      Amount__c = 93,
      Claim__c = claimOverTotalLimit.Id,
      Currency__c = 'SEK',
      Type__c = 'Transportation'
    );

    Claim_Expense__c foodUnderLimitExpenseForValidClaim = new Claim_Expense__c(
      Amount__c = 8,
      Claim__c = validClaim.Id,
      Currency__c = 'SEK',
      Type__c = 'Food'
    );

    insert new List<SObject>{
      foodOverLimitExpense,
      foodUnderLimitExpense,
      transportationUnderLimitExpense,
      foodUnderLimitExpenseForValidClaim
    };

    EU261Service.Config config = new EU261Service.Config();
    config.enabledRejections = true;
    config.enabledSemiAutomation = true;
    config.enabledSettlements = true;
    config.expenseLimitFood = new Money(10, Money.CurrencyCode.SEK);
    config.expenseLimitTransportation = new Money(95, Money.CurrencyCode.SEK);
    config.expenseLimitTotal = new Money(100, Money.CurrencyCode.SEK);
    config.percentageRequiringManualApproval = 0;

    Result res = runProcessingFor(testPnrs, config);

    System.assertEquals(
      4,
      res.settlements.size(),
      'There should be one compensation settlement for each claim and a reimbursement one for the valid one.'
    );
    System.assertEquals(
      3,
      res.claims.size(),
      'Should have found the correct number of claims.'
    );
    System.assertEquals(
      3,
      res.cases.size(),
      'Should have found the correct number of cases.'
    );

    for (Case c : res.cases) {
      if (c.Id == validClaim.Case__c) {
        System.assertEquals(
          Cases.STATUS_CLOSED,
          c.Status,
          'Valid case should be closed.'
        );
      } else {
        System.assertEquals(
          Cases.STATUS_NEW,
          c.Status,
          'High expenses cases should be waiting for approval.'
        );
      }
    }
    for (LIA_Claim__c cl : res.claims) {
      Claim c = new Claim(cl);
      if (cl.Id == validClaim.Id) {
        System.assertEquals(
          Claim.EU261HandlingStatus.EligibleForCompensation,
          c.eu261HandlingStatus,
          'Valid claim should be eligible for compensation.'
        );
      } else {
        System.assertEquals(
          Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
          c.eu261HandlingStatus,
          'Claims with high expenses should be possibly eligible for compensation.'
        );
      }
    }
    for (Settlement__c s : res.settlements) {
      if (s.Claim__c == validClaim.Id) {
        System.assertEquals(
          Settlements.STATUS_WAITING_FOR_TRANSFER,
          s.Settlement_Status__c,
          'Settlement for valid case should be waiting for transfer.'
        );
      } else {
        System.assertEquals(
          Settlements.STATUS_IN_PROGRESS,
          s.Settlement_Status__c,
          'Settlement should be in progress.'
        );
      }
    }
  }

  @IsTest
  static void claimsRequiringPowerOfAttorneyCanBeSemiAutomated() {
    String testPnr = '000013';

    Id originalFlightId;
    Id rebookedFlightId;

    for (Flight__c f : [
      SELECT Id, TEDS_Identifier__c
      FROM Flight__c
      WHERE TEDS_Identifier__c IN :ELIGIBLE_FLIGHT_TEDS_IDS
    ]) {
      if (f.TEDS_Identifier__c == ELIGIBLE_FLIGHT_TEDS_ID) {
        originalFlightId = f.Id;
      } else {
        rebookedFlightId = f.Id;
      }
    }

    LIA_Claim__c testClaim = [
      SELECT Id, Case__c, Liability_PNR__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c = :testPnr
    ][0];

    Booking__c b = [
      SELECT Id
      FROM Booking__c
      WHERE Booking_Reference__c = :testPnr
    ];

    List<SObject> toInsert = new List<SObject>();

    toInsert.add(
      new Customer__c(
        Claim__c = testClaim.Id,
        First_Name__c = 'Sven',
        Last_Name__c = 'Testsson'
      )
    );

    toInsert.add(
      new Passenger__c(
        Booking__c = b.Id,
        First_Name__c = 'Sven',
        Last_Name__c = 'Testsson',
        Identifier__c = 'PT2'
      )
    );

    toInsert.add(
      new Segment__c(
        Booking__c = b.Id,
        Flight__c = originalFlightId,
        Seat__c = '2A',
        Trip_Type__c = 'Cancelled'
      )
    );
    toInsert.add(
      new Segment__c(
        Booking__c = b.Id,
        Flight__c = rebookedFlightId,
        Seat__c = '2A',
        Trip_Type__c = 'Outbound'
      )
    );

    insert toInsert;
    Result res = runProcessingFor(new List<String>{ testPnr });

    System.assertEquals(1, res.claims.size(), 'There should one claim.');
    System.assertEquals(
      'Possibly eligible for compensation',
      res.claims[0].EU261_Handling_Status__c,
      'Handling status should have been set to eligible for compensation'
    );

    System.assertEquals(1, res.cases.size(), 'There should be one case.');
    System.assertEquals(
      'New',
      res.cases[0].Status,
      'Case should still be in new'
    );

    System.assertEquals(1, res.cases.size(), 'There should be one case.');
    System.assert(
      res.cases[0].EU261_Handling_Instructions__c != null,
      'There should be eu261 handling instructions in the case.'
    );

    System.assertEquals(
      1,
      res.settlements.size(),
      'There should be only one settlement for two customers.'
    );

    Settlement__c s = res.settlements[0];

    List<Settlement_Item__c> settlementItemsForClaim = [
      SELECT Id, Amount__c, Customer_Name__c
      FROM Settlement_Item__c
      WHERE Settlement__c = :s.Id
    ];

    System.assertEquals(
      2,
      settlementItemsForClaim.size(),
      'There should be one settlement item per claim customer.'
    );

    System.assertEquals(
      Settlements.STATUS_IN_PROGRESS,
      s.Settlement_Status__c,
      'Settlement should bein progress after processing.'
    );
    System.assertEquals(
      Settlements.getRecordTypeId(Settlements.RecordType.Monetary),
      s.RecordTypeId,
      'Settlement type should be monetary if customer has requested compensation as monetary.'
    );
    System.assertEquals(
      5000,
      s.Amount__c,
      'Settlement amount in euros should match the original compensation amount.'
    );
    System.assertEquals(
      'SEK',
      s.Currency__c,
      'Monetary settlement should be in SEK.'
    );

    for (Settlement_Item__c si : settlementItemsForClaim) {
      System.assertEquals(
        2500,
        si.Amount__c,
        'Settlement item amount should be equal to individuals compensation.'
      );
      if (si.Customer_Name__c == 'Sven Svensson') {
        System.assertEquals(
          'Sven Svensson',
          si.Customer_Name__c,
          'Settlement item customer names should be based on customer names from claim.'
        );
      } else {
        System.assertEquals(
          'Sven Testsson',
          si.Customer_Name__c,
          'Settlement item customer names should be based on customer names from claim.'
        );
      }
    }
  }

  /*@IsTest
  static void invalidSettlementsCanBeSemiAutomated() {
    List<String> testPnrs = new List<String>{ '000011' };
    LIA_Claim__c cls = [
      SELECT Id, Case__c, Liability_PNR__c, Bank_Account_Number__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c IN :testPnrs
    ][0];

    cls.Bank_Account_Number__c = 'INVALID';
    update cls;

    Result res = runProcessingFor(testPnrs);

    System.assertEquals(
      Cases.STATUS_NEW,
      res.cases[0].Status,
      'Case should be still in new.'
    );

    System.assertEquals(
      1,
      res.settlements.size(),
      'Settlement should have been created for the claim.'
    );
    System.assertEquals(
      Settlements.STATUS_IN_PROGRESS,
      res.settlements[0].Settlement_Status__c,
      'Settlement should have been created for the claim.'
    );
  }*/

  @IsTest
  static void duplicatesCanBeSemiAutomated() {
    List<String> testPnrs = new List<String>{
      DUPLICATE_BOOKING_REFERENCE,
      CARE_DUPLICATE_BOOKING_REFERENCE
    };

    // We can have duplicates either from other claims or from CARE data

    insert new CARE_Claim__c(
      Booking_Reference__c = CARE_DUPLICATE_BOOKING_REFERENCE,
      Flight_Number__c = ELIGIBLE_FLIGHT_NUMBER
    );

    Result res = runProcessingFor(testPnrs);

    System.assertEquals(
      3,
      res.claims.size(),
      'Three claims should have been processed by the duplicate PNR and CARE duplicate PNR'
    );
    for (LIA_Claim__c cl : res.claims) {
      Claim c = new Claim(cl);
      System.assertEquals(
        Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
        c.eu261HandlingStatus,
        'Duplicate claims should be possibly eligible compensation'
      );
    }

    System.assertEquals(
      3,
      res.cases.size(),
      'Same number of cases as claims should exist.'
    );
    for (Case c : res.cases) {
      System.assertEquals(
        Cases.STATUS_NEW,
        c.Status,
        'Case should be still in new.'
      );
    }

    System.assertEquals(
      3,
      res.settlements.size(),
      'There should be one settlement per claim.'
    );
    for (Settlement__c s : res.settlements) {
      System.assertEquals(
        Settlements.STATUS_IN_PROGRESS,
        res.settlements[0].Settlement_Status__c,
        'Settlement should have been created for the claim.'
      );
    }
  }

  @IsTest
  static void compensationAndReimbursementCanHaveDifferentPaymentMethods() {
    String testPnr = 'EXPEN1';
    Id originalFlightId;
    Id rebookedFlightId;
    for (Flight__c f : [
      SELECT Id, TEDS_Identifier__c
      FROM Flight__c
      WHERE TEDS_Identifier__c IN :ELIGIBLE_FLIGHT_TEDS_IDS
    ]) {
      if (f.TEDS_Identifier__c == ELIGIBLE_FLIGHT_TEDS_ID) {
        originalFlightId = f.Id;
      } else {
        rebookedFlightId = f.Id;
      }
    }

    Booking__c b = new Booking__c(
      Booking_Reference__c = testPnr,
      TEDS_Identifier__c = testPnr,
      Type__c = 'OneWay'
    );

    insert b;

    List<SObject> toInsert = new List<SObject>();

    toInsert.add(
      new Segment__c(
        Booking__c = b.Id,
        Flight__c = originalFlightId,
        Seat__c = '1A',
        Trip_Type__c = 'Cancelled'
      )
    );
    toInsert.add(
      new Segment__c(
        Booking__c = b.Id,
        Flight__c = rebookedFlightId,
        Seat__c = '1A',
        Trip_Type__c = 'Outbound'
      )
    );
    toInsert.add(
      new Passenger__c(
        Booking__c = b.Id,
        Identifier__c = 'P1',
        First_Name__c = 'Sven',
        Last_Name__c = 'Svensson'
      )
    );

    insert toInsert;

    Cases.bypassTrigger = true;
    TestDataFactories.CasesClaims testClaim = createDefaultTestClaim(
      testPnr,
      new Map<Schema.SObjectField, Object>{
        LIA_Claim__c.Preferred_Reimbursement_Method__c => 'EuroBonus Points'
      }
    );
    Cases.bypassTrigger = false;

    Claim_Expense__c expenseOne = new Claim_Expense__c(
      Amount__c = 30,
      Claim__c = testClaim.claims[0].Id,
      Currency__c = 'SEK',
      Type__c = 'Food'
    );
    Claim_Expense__c expenseTwo = new Claim_Expense__c(
      Amount__c = 300,
      Claim__c = testClaim.claims[0].Id,
      Currency__c = 'SEK',
      Type__c = 'Transportation'
    );

    insert new List<SObject>{ expenseOne, expenseTwo };

    createCaseToBookings(new List<TestDataFactories.CasesClaims>{ testClaim });

    EU261Service.Config config = new EU261Service.Config();
    config.enabledRejections = true;
    config.enabledSemiAutomation = true;
    config.enabledSettlements = true;
    config.expenseLimitFood = new Money(100, Money.CurrencyCode.SEK);
    config.expenseLimitTransportation = new Money(1000, Money.CurrencyCode.SEK);
    config.expenseLimitTotal = new Money(10000, Money.CurrencyCode.SEK);
    config.percentageRequiringManualApproval = 0;

    Result res = runProcessingFor(new List<String>{ testPnr }, config);

    System.assertEquals(
      1,
      res.claims.size(),
      'There should be only one claim processed.'
    );
    System.assertEquals(
      2,
      res.settlements.size(),
      'Two settlements should have been created: One for compensation and one for reimbursement.'
    );

    for (Settlement__c s : res.settlements) {
      if (s.Amount__c == null) {
        System.assertEquals(
          3300,
          s.EuroBonus_Points__c,
          'Reimbursement should be in points with the correct amount.'
        );
      } else {
        System.assertEquals(
          2500,
          s.Amount__c,
          'Compensation should be in SEK.'
        );
      }
    }
  }
}
