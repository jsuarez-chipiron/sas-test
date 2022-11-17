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

    fis[0].cancellationTime = departure.addDays(-1);
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

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

    return new BookingClaim(b, c);
  }

  private static BookingClaim getDefaultDelayBookingClaim() {
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createDelay(f1)
    };
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

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

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
    fis[0].cancellationTime = departure.addDays(-1);
    f1.irregularities = fis;

    // OneWay
    List<Flight> flights1 = new List<Flight>{ f1, f2 };
    Booking oneWay = TestBookingFactory.createValidForClaim(c);
    oneWay.type = Booking.Type.OneWay;
    oneWay.segments = TestSegmentFactory.createFromBookingFlights(
      oneWay,
      flights1
    );

    // RoundTrip
    List<Flight> flights2 = new List<Flight>{ f1, f2, f3 };
    Booking roundTrip = TestBookingFactory.createValidForClaim(c);
    roundTrip.type = Booking.Type.RoundTrip;
    roundTrip.segments = TestSegmentFactory.createFromBookingFlights(
      roundTrip,
      flights2
    );

    // DayReturn
    List<Flight> flights3 = new List<Flight>{ f1, f2, f4 };
    Booking dayReturn = TestBookingFactory.createValidForClaim(c);
    dayReturn.type = Booking.Type.DayReturn;
    dayReturn.segments = TestSegmentFactory.createFromBookingFlights(
      dayReturn,
      flights3
    );

    // MultiCity
    List<Flight> flights4 = new List<Flight>{ f1, f2, f5, f6 };
    Booking multiCity = TestBookingFactory.createValidForClaim(c);
    multiCity.type = Booking.Type.MultiCity;
    multiCity.segments = TestSegmentFactory.createFromBookingFlights(
      multiCity,
      flights4
    );

    // Unknown
    List<Flight> flights5 = new List<Flight>{ f1, f2 };
    Booking unknown = TestBookingFactory.createValidForClaim(c);
    unknown.type = Booking.Type.Unknown;
    unknown.segments = TestSegmentFactory.createFromBookingFlights(
      unknown,
      flights5
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
    fis[0].cancellationTime = departure.addDays(-1);
    f1.irregularities = fis;

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
      flights
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
      flights
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
      flights
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
      flights
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
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    fis[0].cancellationTime = departure.addDays(-1);
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

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

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
    List<Flight> flights = new List<Flight>{ f1 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    fis[0].cancellationTime = departure.addDays(-1);
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

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

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
      'this trip type is not yet supported for automated cancellation handling',
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
      'there are more than one cancellation connected to this claim',
      result.reasoning,
      'Unhandled reason should be "there are more than one cancellation connected to this claim"'
    );
  }

  // TODO: use TestFactories (complicated)
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

    List<Flight> flights = new List<Flight>{ f1, f2, f3, f4 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    fis[0].cancellationTime = departure.addDays(-1);
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

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);
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

    List<Flight> flights = new List<Flight>{ f1, f2, f3 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    fis[0].cancellationTime = departure.addDays(-1);
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

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

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
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    fis[0].cancellationTime = departure.addDays(-1);
    f1.irregularities = fis;

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

    b.segments = TestSegmentFactory.createFromBookingFlights(b, flights);

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
}
