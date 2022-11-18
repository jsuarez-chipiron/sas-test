// Tests for EU261Claim.evaluate()
@IsTest
private class EU261Claim_Test {
  private static Datetime departure = DateTime.newInstance(
    2020,
    10,
    10,
    1,
    1,
    1
  );

  private static EU261Service.Config config = new EU261Service.Config(
    new EU261_Automation_Configuration__mdt(
      Automatic_Rejection__c = false,
      Automatic_Settlement__c = false,
      Claim_Expense_Max_Amount__c = 0,
      Expense_Limit_Accommodation__c = 0,
      Expense_Limit_Food__c = 0,
      Expense_Limit_Phone_Calls__c = 0,
      Expense_Limit_Transportation__c = 0,
      Percentage_Sent_to_Control__c = 0
    )
  );

  private class BookingClaim {
    public Booking b;
    public Claim c;

    public BookingClaim(Booking b, Claim c) {
      this.b = b;
      this.c = c;
    }
  }

  private static BookingClaim getDefaultCancellationBookingClaim() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  @IsTest
  static void onlyOneWayAndRoundTripTicketsCanBeEvaluated() {
    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Datetime newDeparture = departure.addHours(4);
    Datetime returnDeparture = departure.addDays(4);
    Datetime dayReturnDeparture = departure.addHours(12);
    Datetime multiCityDeparture1 = departure.addDays(4);
    Datetime multiCityDeparture2 = multiCityDeparture1.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      returnDeparture,
      'HEL',
      'ARN'
    );
    Flight f4 = TestFlightFactory.create(
      'SK0004',
      dayReturnDeparture,
      'ARN',
      'HEL'
    );
    Flight f5 = TestFlightFactory.create(
      'SK0005',
      multiCityDeparture1,
      'HEL',
      'CPH'
    );
    Flight f6 = TestFlightFactory.create(
      'SK0006',
      multiCityDeparture2,
      'CPH',
      'JFK'
    );

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };
    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo4 = new TestSegmentFactory.SegmentsInfo(
      f4,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo5 = new TestSegmentFactory.SegmentsInfo(
      f5,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo6 = new TestSegmentFactory.SegmentsInfo(
      f6,
      departure.addDays(-60),
      null
    );

    // OneWay
    List<TestSegmentFactory.SegmentsInfo> segmentInfos1 = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };
    Booking oneWay = TestBookingFactory.createValidForClaim(c);
    oneWay.type = Booking.Type.OneWay;
    oneWay.segments = TestSegmentFactory.createFromBookingFlights(
      oneWay,
      segmentInfos1
    );

    // RoundTrip
    List<TestSegmentFactory.SegmentsInfo> segmentInfos2 = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3
    };
    Booking roundTrip = TestBookingFactory.createValidForClaim(c);
    roundTrip.type = Booking.Type.RoundTrip;
    roundTrip.segments = TestSegmentFactory.createFromBookingFlights(
      roundTrip,
      segmentInfos2
    );

    // DayReturn
    List<TestSegmentFactory.SegmentsInfo> segmentInfos3 = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo4
    };
    Booking dayReturn = TestBookingFactory.createValidForClaim(c);
    dayReturn.type = Booking.Type.DayReturn;
    dayReturn.segments = TestSegmentFactory.createFromBookingFlights(
      dayReturn,
      segmentInfos3
    );

    // MultiCity
    List<TestSegmentFactory.SegmentsInfo> segmentInfos4 = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo5,
      sInfo6
    };
    Booking multiCity = TestBookingFactory.createValidForClaim(c);
    multiCity.type = Booking.Type.MultiCity;
    multiCity.segments = TestSegmentFactory.createFromBookingFlights(
      multiCity,
      segmentInfos4
    );

    // Unknown
    Booking unknown = TestBookingFactory.createValidForClaim(c);
    unknown.type = Booking.Type.Unknown;
    unknown.segments = TestSegmentFactory.createFromBookingFlights(
      unknown,
      segmentInfos1
    );
    unknown.segments[0].tripType = 'Unknown';

    EU261Claim oneWayClaim = new EU261Claim(
      c,
      new List<Booking>{ oneWay },
      false,
      config
    );
    EU261Claim roundTripClaim = new EU261Claim(
      c,
      new List<Booking>{ roundTrip },
      false,
      config
    );
    EU261Claim dayReturnClaim = new EU261Claim(
      c,
      new List<Booking>{ dayReturn },
      false,
      config
    );
    EU261Claim multiCityClaim = new EU261Claim(
      c,
      new List<Booking>{ multiCity },
      false,
      config
    );
    EU261Claim unknownClaim = new EU261Claim(
      c,
      new List<Booking>{ unknown },
      false,
      config
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{},
      false,
      config
    );

    EU261Claim.Decision oneWayResult = oneWayClaim.evaluate();
    EU261Claim.Decision roundTripResult = roundTripClaim.evaluate();
    EU261Claim.Decision dayReturnResult = dayReturnClaim.evaluate();
    EU261Claim.Decision multiCityResult = multiCityClaim.evaluate();
    EU261Claim.Decision unknownResult = unknownClaim.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      oneWayResult.verdict,
      'One way claim should be possible to evaluate.'
    );
    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      roundTripResult.verdict,
      'Round trip claim should be possible to evaluate.'
    );

    for (
      EU261Claim.Decision d : new List<EU261Claim.Decision>{
        dayReturnResult,
        multiCityResult,
        unknownResult
      }
    ) {
      System.assertEquals(
        Claim.EU261HandlingStatus.UnableToHandle,
        d.verdict,
        'Other booking types should not be available for evaluation.'
      );
      System.assertEquals(
        'can handle only one way or round trips',
        d.reasoning,
        'Rejection reason should be "can handle only one way or round trips"'
      );
    }
  }

  @IsTest
  static void onlyClaimsWhichDoNotRequirePOACanBeEvaluated() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2 };
    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };
    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;
    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    ClaimCustomer cc1 = new ClaimCustomer();
    cc1.firstname = 'Test';
    cc1.lastName = 'Testsson';
    ClaimCustomer cc2 = new ClaimCustomer();
    cc2.firstname = 'Test2';
    cc2.lastName = 'Testsson2';
    ClaimCustomer cc3 = new ClaimCustomer();
    cc3.firstname = 'Test3';
    cc3.lastName = 'Testsson3';
    ClaimCustomer cc4 = new ClaimCustomer();
    cc4.firstname = 'Test4';
    cc4.lastName = 'Testsson4';
    ClaimCustomer cc5 = new ClaimCustomer();
    cc5.firstname = 'Test5';
    cc5.lastName = 'Testsson5';
    ClaimCustomer cc6 = new ClaimCustomer();
    cc6.firstname = 'Test6';
    cc6.lastName = 'Testsdaughter';

    List<Claim> claimsWithoutCustomers = new List<Claim>();

    for (Integer i = 0; i < 4; i++) {
      Claim c = TestClaimFactory.create();
      c.recordType = Claim.RecordType.CustomerClaim;
      c.category = Claim.Category.FlightDisruptions;
      c.type = Claim.Type.FlightCancellation;
      c.departureDate = departure.date();
      c.flightNumber = 'SK0001';
      c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
      c.customers = new List<ClaimCustomer>{ cc1 };
      claimsWithoutCustomers.add(c);
    }

    // groupBookingReference
    // Cloning these would be nice but there does not seem to be an easy solution
    Claim groupClaim = claimsWithoutCustomers[0];
    groupClaim.customers.add(cc2);
    groupClaim.customers.add(cc3);
    groupClaim.customers.add(cc4);
    groupClaim.customers.add(cc5);
    Booking groupBooking = TestBookingFactory.createValidForClaim(groupClaim);
    groupBooking.type = Booking.Type.OneWay;

    groupBooking.segments = TestSegmentFactory.createFromBookingFlights(
      groupBooking,
      segmentInfos
    );

    // differentLastNamesReference
    Claim differentLastNameClaim = claimsWithoutCustomers[1];
    differentLastNameClaim.customers.add(cc6);
    Booking differentLastNameBooking = TestBookingFactory.createValidForClaim(
      differentLastNameClaim
    );
    differentLastNameBooking.type = Booking.Type.OneWay;
    differentLastNameBooking.segments = TestSegmentFactory.createFromBookingFlights(
      differentLastNameBooking,
      segmentInfos
    );

    // missingTravelersBookingReference, todo, Customer name != passenger name
    Claim missingTravelersClaim = claimsWithoutCustomers[2];
    missingTravelersClaim.customers.add(cc2);
    Booking missingTravelersBooking = TestBookingFactory.createValidForClaim(
      missingTravelersClaim
    );
    missingTravelersBooking.passengers[1].firstName = 'Missing';
    missingTravelersBooking.type = Booking.Type.OneWay;
    missingTravelersBooking.segments = TestSegmentFactory.createFromBookingFlights(
      missingTravelersBooking,
      segmentInfos
    );

    // claimFirmBookingReference
    Claim claimFirmClaim = claimsWithoutCustomers[3];
    claimFirmClaim.contactType = Claim.ContactType.ClaimFirm;
    Booking claimFirmBooking = TestBookingFactory.createValidForClaim(
      claimFirmClaim
    );
    claimFirmBooking.type = Booking.Type.OneWay;
    claimFirmBooking.segments = TestSegmentFactory.createFromBookingFlights(
      claimFirmBooking,
      segmentInfos
    );

    EU261Claim groupClaimToEvaluate = new EU261Claim(
      groupClaim,
      new List<Booking>{ groupBooking },
      false,
      config
    );
    EU261Claim differentLastNameClaimToEvaluate = new EU261Claim(
      differentLastNameClaim,
      new List<Booking>{ differentLastNameBooking },
      false,
      config
    );
    EU261Claim missingTravelersClaimToEvaluate = new EU261Claim(
      missingTravelersClaim,
      new List<Booking>{ missingTravelersBooking },
      false,
      config
    );
    EU261Claim claimFirmClaimToEvaluate = new EU261Claim(
      claimFirmClaim,
      new List<Booking>{ claimFirmBooking },
      false,
      config
    );

    EU261Claim.Decision groupResult = groupClaimToEvaluate.evaluate();
    EU261Claim.Decision differentLastNameResult = differentLastNameClaimToEvaluate.evaluate();
    EU261Claim.Decision missingTravelersResult = missingTravelersClaimToEvaluate.evaluate();
    EU261Claim.Decision claimFirmResult = claimFirmClaimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      groupResult.verdict,
      'It should not be possible to automatically evaluate a claim with more than four travelers.'
    );
    System.assertEquals(
      'caveats: requires a power of attorney',
      groupResult.reasoning,
      'Reasoning should include caveat on power of attorney'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      differentLastNameResult.verdict,
      'It should not be possible to automatically evaluate a claim with different last names.'
    );
    System.assertEquals(
      'caveats: requires a power of attorney',
      differentLastNameResult.reasoning,
      'Reasoning should include caveat on power of attorney'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      missingTravelersResult.verdict,
      'It should not be possible to automatically evaluate a claim when claimed travelers are not included in the booking.'
    );
    System.assertEquals(
      'caveats: requires a power of attorney',
      missingTravelersResult.reasoning,
      'Reasoning should include caveat on power of attorney'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      claimFirmResult.verdict,
      'It should not be possible to evaluate a claim submitted by a claim firm.'
    );
    System.assertEquals(
      'caveats: requires a power of attorney',
      claimFirmResult.reasoning,
      'Reasoning should include caveat on power of attorney'
    );
  }

  @IsTest
  static void onlyClaimsWithOneBookingCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b, bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim with more than one booking cannot be evaluated.'
    );
    System.assertEquals(
      'can handle only one booking per claim',
      result.reasoning,
      'Rejection reason should be "can handle only one booking per claim"'
    );
  }

  @IsTest
  static void onlyClaimsWithAirportsinEUCanBeEvaluated() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'JFK');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'JFK');

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with airports outside the EU.'
    );
    System.assertEquals(
      'can only handle claims with origin and destination airports in EU',
      result.reasoning,
      'Rejection reason should be "can only handle claims with origin and destination airports in EU"'
    );
  }

  @IsTest
  static void onlyClaimsWithoutExpensesCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    bc.c.submittedClaimExpenses = new Money(20, Money.CurrencyCode.SEK);
    ClaimExpense ce = new ClaimExpense();
    ce.amount = 20;
    ce.amountInSEK = 20;
    ce.currencyOfAmount = Money.CurrencyCode.SEK;
    bc.c.expenses = new List<ClaimExpense>{ ce };

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      result.verdict,
      'It should not be possible to automatically evaluate claims with expenses.'
    );
    System.assertEquals(
      'caveats: has high claim expenses',
      result.reasoning,
      'Rejection reason should include caveat about expenses'
    );
  }

  @IsTest
  static void onlyClaimsWithClaimedFlightInBookingCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.c.flightNumber = 'SK0009';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with flight missing from booking.'
    );
    System.assertEquals(
      'cannot find claimed flight from booking',
      result.reasoning,
      'Rejection reason should be "cannot find claimed flight from booking"'
    );
  }

  @IsTest
  static void claimsWithRotationIrregularitiesCannotBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'EQUI';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with rotation delays.'
    );
    System.assertEquals(
      'cannot handle flights with irregularities caused by rotations',
      result.reasoning,
      'Rejection reason should be "cannot handle flights with irregularities caused by rotations"'
    );
  }

  @IsTest
  static void onlyClaimsWithFlightsOperatedBySASCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight nonSASFlight = TestFlightFactory.create(
      'LH0001',
      departure.addHours(4),
      'ARN',
      'HEL'
    );
    bc.b.segments[1].flight = nonSASFlight;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with flights not operated by SAS.'
    );
    System.assertEquals(
      'cannot handle claims where SAS is not the only operating carrier',
      result.reasoning,
      'Rejection reason should be "cannot handle claims where SAS is not the only operating carrier"'
    );
  }

  @IsTest
  static void onlyClaimsWithoutDuplicatesCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      true,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      result.verdict,
      'It should not be possible to automatically evaluate claims with possible duplicates.'
    );
    System.assertEquals(
      'caveats: has potential duplicates',
      result.reasoning,
      'Caveat should be be "caveats: has potential duplicates"'
    );
  }

  @IsTest
  static void minimalClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
  }

  @IsTest
  static void minimalCancellationClaimWithoutRebookingCannotBeEvaluated() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'No rebooking cannot be automated.'
    );
    System.assertEquals(
      'was not able to divide the booking into trips (Interpretation of booking changed after cancellation)',
      result.reasoning,
      'This trip type should not be supported.'
    );
  }

  @IsTest
  static void minimalCancellationClaimsWithCancellationsOutsideSASControlShouldBeDenied() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'WEAT';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'It should be possible to evaluate minimal claims with cancellations outside SAS control and they should not receive any compensation.'
    );
  }

  @IsTest
  static void claimsWithUnsupportedCancellationCodesShouldNotBeAutomated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'AIRS';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with unsupported cancellation codes.'
    );
    System.assertEquals(
      'cannot determine wether SAS is responsible or not for the cancellation',
      result.reasoning,
      'Unhandled reason should be "cannot determine wether SAS is responsible or not for the cancellation"'
    );
  }

  @IsTest
  static void claimsWithTwoCancellationsShouldNotBeAutomated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    FlightIrregularity newIrreg = TestIrregularityFactory.createCancellation(
      bc.b.segments[0].flight
    );
    newIrreg.code = 'TECH';
    bc.b.segments[0].flight.irregularities.add(newIrreg);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Should not be able to handle claim'
    );
    System.assertEquals(
      'there are more than one cancellation connected to this claim',
      result.reasoning,
      'Unhandled reason should be "there are more than one cancellation connected to this claim"'
    );
  }

  @IsTest
  static void claimsWithTwoFlightsAndOneCancellationNotOnTimeShouldBeApproved() {
    Datetime newDeparture = departure.addHours(4);
    Datetime nextFlightDeparture = departure.addHours(3);
    Datetime nextFlightDepartureReplacement = departure.addHours(6);

    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      nextFlightDeparture,
      'HEL',
      'CPH'
    );
    Flight f4 = TestFlightFactory.create(
      'SK0004',
      nextFlightDepartureReplacement,
      'HEL',
      'CPH'
    );

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo4 = new TestSegmentFactory.SegmentsInfo(
      f4,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3,
      sInfo4
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);
    b.segments[2].tripType = 'Cancelled';

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'If a cancelled flight leads to a missed connection and a delay of +3 hours the customer should be eligble for compensation (two flights).'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'The customer should be awarded 250 eur (two flights)'
    );
  }

  @IsTest
  static void claimsWithTwoFlightsANDOneCancellationButOnTimeShouldBeDenied() {
    Datetime newDeparture = departure.addHours(4);
    Datetime nextFlightDeparture = departure.addHours(7);

    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      nextFlightDeparture,
      'HEL',
      'CPH'
    );

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      departure.addDays(-60),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'If a cancelled flight does not affect the final arrival time the customer should not be compensated (two flights).'
    );
    System.assertEquals(
      'the offered rebooking is not outside the timeframe allowed by EU261',
      result.reasoning,
      'If a cancelled flight does not affect the final arrival time the customer should not be compensated (two flights).'
    );
  }

  @IsTest
  static void claimsWithAnyNumberOfPassengersCanBeEvaluated() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    ClaimCustomer cc1 = new ClaimCustomer();
    cc1.firstname = 'Test';
    cc1.lastName = 'Testsson';
    ClaimCustomer cc2 = new ClaimCustomer();
    cc2.firstname = 'Test2';
    cc2.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc1, cc2 }; // Is this correctly implemented?
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'It should be possible to evaluate a claim with two passengers.'
    );
    System.assertEquals(
      2,
      result.compensationPerCustomerInEUR.values().size(),
      'Settlement total should be larger for two passenger.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250€ for first customer'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[1],
      'Compensation should be 250€ for second customer'
    );
  }

  @IsTest
  static void minimalCancellationClaimShouldBeAutomatedCorrectly() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
  }

  @IsTest
  static void claimWithRemovedButNotCancelledSegmentsAfterCancellationShouldBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;
    Flight replacementFlight = bc.b.segments[1].flight;
    Datetime cancellationTime = cancelledFlight.irregularities[0]
      .cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.REMOVEDNOTCANCELLED
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      replacementFlight,
      cancellationTime.addMinutes(20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Claim where a segment has been removed without being cancelled should be evaluated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
  }

  @IsTest
  static void claimWithRemovedButNotCancelledSegmentsBeforeCancellationShouldBeAutomatedWithCaveats() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;
    Flight replacementFlight = bc.b.segments[1].flight;
    Datetime cancellationTime = cancelledFlight.irregularities[0]
      .cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      cancellationTime.addMinutes(-20),
      TestSegmentFactory.History.REMOVEDNOTCANCELLED
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      replacementFlight,
      cancellationTime.addMinutes(-20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim where a segment has been removed without being cancelled should not be evaluated.'
    );
    System.assertEquals(
      'it is uncertain if SAS or the customer cancelled the flight',
      result.reasoning,
      'Reasoning should be "it is uncertain if SAS or the customer cancelled the flight"'
    );
  }

  @IsTest
  static void claimWithUnsupportedSegmentEventsShouldNotBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      null,
      TestSegmentFactory.History.UNABLETOCONFIRM
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'A claim with segments which have unsupported segment events should not be handled.'
    );
    System.assertEquals(
      'a segment has an unsupported status',
      result.reasoning,
      'Unhandled reason should be "a segment has an unsupported status"'
    );
  }

  @IsTest
  static void claimWithGroupSegmentEventShouldNotBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      null,
      TestSegmentFactory.History.GROUPBOOKING
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'A claim with segments which have group segment events should not be handled.'
    );
    System.assertEquals(
      'a segment has an unsupported status',
      result.reasoning,
      'Unhandled reason should be "a segment has an unsupported status"'
    );
  }

  @IsTest
  static void claimWithTwoUnconfirmedStatusesShouldBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;
    Flight replacementFlight = bc.b.segments[1].flight;
    Datetime cancellationTime = cancelledFlight.irregularities[0]
      .cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.DOUBLEUNCONFIRMED
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      replacementFlight,
      cancellationTime.addMinutes(140),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
  }

  @IsTest
  static void claimWithFullHistoryShouldBeAutomated() {
    BookingClaim bc = getCancellationFullBookingHistory();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
  }

  /**
    Based on:
    THVPPA  2022-02-15 19:44:00 LPA   OSL   1 A   0 HK         2022-07-01 2022-07-01
    THVPPA  2022-02-15 19:46:00 LPA   OSL   1 C   2 HK HK      2022-07-01 2022-07-01
    THVPPA  2022-03-10 20:51:00 LPA   OSL   1 C  10 UN HK      2022-07-01 2022-07-01
    THVPPA  2022-03-10 21:00:00 LPA   OSL   1 X  18 UN UN      2022-07-01 2022-07-01

    THVPPA  2022-03-10 20:51:00 LPA   OSL   2 A  10 TK         2022-06-29 2022-06-29
    THVPPA  2022-03-10 21:00:00 LPA   OSL   2 C  18 HK TK      2022-06-29 2022-06-29
    THVPPA  2022-03-11 08:54:00 LPA   OSL   2 X  23 XX HK      2022-06-29 2022-06-29

    THVPPA  2022-03-11 08:54:00 LPA   OSL   3 A  23 HK    CREW 2022-07-02 2022-07-02
    THVPPA  2022-03-11 08:54:00 LPA   OSL   3 C  24 HK HK CREW 2022-07-02 2022-07-02
    THVPPA  2022-07-01 17:25:00 LPA   OSL   3 C  46 UN HK CREW 2022-07-02 2022-07-02
    THVPPA  2022-07-01 17:59:00 LPA   OSL   3 X  51 UN UN CREW 2022-07-02 2022-07-02

    THVPPA  2022-07-01 17:59:00 LPA   BRU   4 A  51 HK    NaN 2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 LPA   BRU   4 C  55 HK HK NaN 2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 LPA   BRU   4 C  56 HK HK NaN 2022-07-03 2022-07-03

    THVPPA  2022-07-01 17:59:00 BRU   OSL   5 A  51 HK         2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 BRU   OSL   5 C  55 HK HK      2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 BRU   OSL   5 C  56 HK HK      2022-07-03 2022-07-03
   */
  private static BookingClaim getCancellationFullBookingHistory() {
    Datetime newDeparture1 = departure.addHours(4);
    Datetime newDeparture2 = departure.addDays(-2);
    Datetime newDeparture3 = departure.addDays(1);
    Datetime newDeparture4 = departure.addDays(1).addHours(5);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture1, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create('SK0003', newDeparture2, 'ARN', 'HEL');
    Flight f4 = TestFlightFactory.create('SK0004', newDeparture3, 'ARN', 'CPH');
    Flight f5 = TestFlightFactory.create('SK0005', newDeparture4, 'CPH', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2, f3, f4, f5 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f3)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f3.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellation;
    c.departureDate = newDeparture2.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0003'; // SK001 null reference
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    Datetime timeBooked = departure.addDays(-60);
    Datetime unconfirmedWithoutCancellation = departure.addDays(-45);
    Datetime cancelledWithoutCancellation = unconfirmedWithoutCancellation.addHours(
      2
    ); // 2 h default
    Datetime removed = cancelledWithoutCancellation.addDays(1);

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      timeBooked,
      unconfirmedWithoutCancellation,
      TestSegmentFactory.History.DOUBLEUNCONFIRMED
    );

    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancelledWithoutCancellation,
      removed,
      TestSegmentFactory.History.REMOVEDNOTCANCELLED
    );

    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      removed,
      cancellationTime,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );

    TestSegmentFactory.SegmentsInfo sInfo4 = new TestSegmentFactory.SegmentsInfo(
      f4,
      cancellationTime,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    TestSegmentFactory.SegmentsInfo sInfo5 = new TestSegmentFactory.SegmentsInfo(
      f5,
      cancellationTime,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3,
      sInfo4,
      sInfo5
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }
}
