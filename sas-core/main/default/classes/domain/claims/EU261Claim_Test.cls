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
    groupClaim.customers.add(cc6);
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
      1,
      groupResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      groupResult.caveats[0],
      'Caveat should be power of attorney.'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      differentLastNameResult.verdict,
      'It should TEMPORARILY be possible to automatically evaluate a claim with different last names.'
    );
    // System.assertEquals(
    //   1,
    //   differentLastNameResult.caveats.size(),
    //   'There should be one caveat'
    // );
    // System.assertEquals(
    //   EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
    //   differentLastNameResult.caveats[0],
    //   'Caveat should be power of attorney.'
    // );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      missingTravelersResult.verdict,
      'It should not be possible to automatically evaluate a claim when claimed travelers are not included in the booking.'
    );
    System.assertEquals(
      1,
      missingTravelersResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      missingTravelersResult.caveats[0],
      'Caveat should be power of attorney.'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      claimFirmResult.verdict,
      'It should not be possible to evaluate a claim submitted by a claim firm.'
    );
    System.assertEquals(
      1,
      claimFirmResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      claimFirmResult.caveats[0],
      'Caveat should be power of attorney.'
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
  static void claimsWhereFlightWasCancelled14DaysOrMoreBeforeDepartureShouldBeDenied() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime = departure.addDays(-14);

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
      'Claim with more than one booking cannot be evaluated.'
    );
    System.assertEquals(
      'flight was cancelled 14 or more days in advance',
      result.reasoning,
      'Rejection reason should be "flight was cancelled 14 or more days in advance"'
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
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    System.assertEquals(
      EU261Claim.SemiAutomationReason.HasHighClaimExpenses,
      result.caveats[0],
      'Caveat should be high expenses.'
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
  static void claimsWithRotationIrregularitiesFromHubCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'CREW';

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
      'It should be possible to evaluate claims with CREW delays.'
    );
  }

  @IsTest
  static void onlyClaimsWithClaimFlightOperatedBySASCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight nonSASFlight = TestFlightFactory.create(
      'LH0001',
      departure.addHours(4),
      'ARN',
      'HEL'
    );
    bc.b.segments[0]
      .flight.tedsIdentifier = Flight.constructTEDSFlightNumberDate(
      'LH0001',
      bc.c.departureDate
    );
    bc.c.flightNumber = 'LH0001';

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
      'It should not be possible to evaluate claims where the claim flight not operated by SAS.'
    );
    System.assertEquals(
      'claim flight is not operated by SAS',
      result.reasoning,
      'Rejection reason should be "claim flight is not operated by SAS"'
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
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    System.assertEquals(
      EU261Claim.SemiAutomationReason.HasPotentialDuplicates,
      result.caveats[0],
      'Caveat should be duplicates.'
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
  static void minimalCancellationClaimWithoutRebookingShouldReceiveFullCompensation() {
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
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'A booking without rebooking should be awarded full compensation'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be €250'
    );
  }

  @IsTest
  static void minimalCancellationClaimsWithCancellationsOutsideSASControlShouldBeDenied() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'WEAT';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.No;

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
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;

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
      'cannot determine wether SAS is responsible or not for the cancellation | Cannot determine whether SAS is within control or not.',
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
      'there are more than one cancellation connected to the claim flight',
      result.reasoning,
      'Unhandled reason should be "there are more than one cancellation connected to the claim flight"'
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
  static void claimWhereTheCustomerCancelledTheFlightShouldBeDenied() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime = bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime.addDays(1);
    List<SegmentEvent> newEvents = new List<SegmentEvent>();
    for (SegmentEvent se : bc.b.segments[0].getEvents()) {
      se.officeCode = 'STOSK08RV';
      if (se.newStatus == SegmentEvent.StatusCode.C_UN) {
        se.operationType = SegmentEvent.OperationType.C_X;
        se.newStatus = SegmentEvent.StatusCode.C_XX;
      }
      newEvents.add(se);
    } // TODO: change to real codes
    bc.b.segments[0].events = newEvents;

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
      'A claim where the customer cancelled the flight should not be automated'
    );
    System.assertEquals(
      'customer cancelled the flight',
      result.reasoning,
      'Reasoning should be "customer cancelled the flight"'
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
      'booking has unsupported event(s)',
      result.reasoning,
      'Unhandled reason should be "booking has unsupported event(s)"'
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
      'booking has unsupported event(s)',
      result.reasoning,
      'Unhandled reason should be "booking has unsupported event(s)"'
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

  @IsTest
  static void claimWithoutSegmentEventsShouldNotCrashEvaluation() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].setEvents(null);

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
      'Claims without segment events should not be possible to handle'
    );
    System.assertEquals(
      'cannot get segment statuses',
      result.reasoning,
      'Reasoning should be "cannot get segment statuses"'
    );
  }
}
