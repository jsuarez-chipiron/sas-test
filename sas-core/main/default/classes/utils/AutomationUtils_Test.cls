@IsTest
private class AutomationUtils_Test {
  public static Set<String> airportIdsFromTEDS = new Set<String>{
    'ARN',
    'HEL',
    'ITM',
    'RUN',
    'SYD'
  };

  /**
   * Common setup for the test classes
   * I tried to make this nice but ended up making it way too complicated.
   */
  @testSetup
  static void setup() {
    Date today = Date.today();
    Date inTime = today.addYears(-2);
    Date justInTime = today.addYears(-3).addDays(1); // Last day
    Date tooLate = today.addYears(-4);
    Date tooLate2 = today.addYears(-2);
    Date tooLate3 = today.addYears(-2);
    Date tooLate4 = today.addYears(-2);

    List<Booking__c> createdBookings = TestDataFactories.createBookings(
      3,
      'AUTO'
    );
    createdBookings.addAll(TestDataFactories.createBookings(3, 'AUTO1')); // Because Salesforce (chunks)

    List<String> bookingReferences = new List<String>{
      'AUTO0',
      'AUTO1',
      'AUTO2',
      'AUTO10',
      'AUTO11',
      'AUTO12'
    }; // TODO: refactor

    List<SObject> toUpdate = new List<SObject>{};

    List<Case> casesToCreate = new List<Case>{
      new Case(),
      new Case(),
      new Case(),
      new Case(),
      new Case(),
      new Case()
    };

    insert casesToCreate;

    String flightIdentifier1 =
      'SK1-' +
      String.valueOf(today).remove('-') +
      '-UME-ARN';
    String flightIdentifier2 =
      'SK2-' +
      String.valueOf(today).remove('-') +
      '-UME-ARN';
    String flightIdentifier3 =
      'SK3-' +
      String.valueOf(today).remove('-') +
      '-UME-ARN';
    String flightIdentifier4 =
      'SK4-' +
      String.valueOf(today).remove('-') +
      '-RUN-ARN';
    String flightIdentifier5 =
      'SK5-' +
      String.valueOf(today).remove('-') +
      '-CDG-ARN';
    String flightIdentifier6 =
      'SK6-' +
      String.valueOf(today).remove('-') +
      '-SYD-ARN';

    List<String> customFlightIds = new List<String>{
      flightIdentifier1,
      flightIdentifier2,
      flightIdentifier3,
      flightIdentifier4,
      flightIdentifier5,
      flightIdentifier6
    };

    // Link bookings to flights for easier bulk handling
    Set<Id> bookingIds = new Set<Id>{};

    for (Booking__c b : createdBookings) {
      bookingIds.add(b.Id);
    }

    List<Segment__c> bookingSegments = SegmentsSelector.newInstance()
      .selectByBookingId(bookingIds);

    Map<Id, Segment__c> bookingIdToSegment = new Map<Id, Segment__c>{};
    Map<Id, Flight__c> bookingIdToFlight = new Map<Id, Flight__c>{};

    for (Booking__c b : createdBookings) {
      Segment__c bookingSegment;
      for (Segment__c s : bookingSegments) {
        if (s.Booking__c == b.Id) {
          bookingIdToSegment.put(b.Id, s);
          break;
        }
      }
    }

    // Update records
    List<SObject> toInsert = new List<SObject>{};
    List<Integer> delayedMinutes = new List<Integer>{
      1,
      120,
      181,
      181,
      241,
      400
    }; // Add 160
    List<Date> flightDates = new List<Date>{
      inTime,
      justInTime,
      tooLate,
      tooLate2,
      tooLate3,
      tooLate4
    };
    Integer err = casesToCreate.size();
    for (Integer i = 0; i < createdBookings.size(); i++) {
      Booking__c booking = createdBookings[i];
      Case c = casesToCreate[i];
      String flightId = customFlightIds[i];

      booking.Type__c = 'OneWay';
      booking.Booking_Reference__c = bookingReferences[i];
      toUpdate.add(booking);
      toInsert.add(
        new CaseToBooking__c(Booking__c = booking.Id, Case__c = c.Id)
      );

      c.Initially_Provided_PNR__c = booking.Booking_Reference__c;
      toUpdate.add(c);

      // The factory assigns one flight to multiple bookings so we have to replace the flights
      Date flightTime = flightDates[i];
      Integer minutesDelayed = delayedMinutes[i];

      Flight__c flight = new Flight__c(
        TEDS_Identifier__c = C_Util.generateUUID()
      );

      flight.Arrival_Airport__c = 'ARN';
      flight.Departure_Airport__c = 'UME';
      flight.Scheduled_Arrival_Time__c = flightTime;
      flight.Scheduled_Departure_Time__c = flightTime;
      flight.Arrival_Delayed_Minutes__c = minutesDelayed;
      flight.TEDS_Identifier__c = flightId;

      bookingIdToFlight.put(booking.Id, flight);
      toInsert.add(flight);
    }

    toInsert.sort(); // Make fewer chunks
    toUpdate.sort();
    insert toInsert;
    update toUpdate;

    List<Sobject> toInsert2 = new List<Sobject>{};
    List<Sobject> toUpdate2 = new List<Sobject>{};

    for (Integer i = 0; i < createdBookings.size(); i++) {
      Booking__c booking = createdBookings[i];
      Segment__c segment = bookingIdToSegment.get(booking.Id);
      Flight__c flight = bookingIdToFlight.get(booking.Id);
      Case c = casesToCreate[i];

      String flightId = customFlightIds[i];
      LIA_Claim__c claim = new LIA_Claim__c(
        Case__c = c.Id,
        Phone_Number__c = '0000000000',
        Liability_PNR__c = booking.TEDS_Identifier__c,
        Flight_Number__c = flightId.substringBefore('-')
      );

      toInsert2.add(claim);

      // Insert a flight irregularity for the first booking
      if (booking.TEDS_Identifier__c == 'AUTO0') {
        toInsert2.add(
          new FlightIrregularities__c(Flight__c = flight.Id, Code__c = 'AUTH')
        );
      }
      segment.Flight__c = flight.Id;

      toUpdate2.add(segment);

      // Connect the bookings to their respective cases
      CaseToBooking__c ctb = new CaseToBooking__c(
        Booking__c = booking.Id,
        Case__c = c.Id
      );
      toInsert2.add(ctb);
      toInsert2.add(
        new IRR_CommunicationLog__c(
          IRR_BookingReference__c = booking.TEDS_Identifier__c
        )
      );
    }

    toInsert2.sort();

    update toUpdate2;
    Test.setMock(HttpCalloutMock.class, new APIMMock()); // Needed for TEDSbooking-fetches caused by trigger
    Test.startTest();
    insert toInsert2;
    Test.stopTest();
  }

  @isTest
  static void shouldAutomateTheRightCases() {
    // Given
    List<LIA_Claim__c> claims = [
      SELECT Id, Case__c, Flight_Number__c, CreatedDate
      FROM LIA_Claim__c
      WHERE Phone_Number__c = '0000000000'
    ];
    List<Id> claimIds = new List<Id>{};

    for (LIA_Claim__c c : claims) {
      claimIds.add(c.Id);
    }

    // When
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Map<Id, Boolean> claimToWasAutomated = AutomationUtils.automateEU261(
      new Set<Id>(claimIds)
    );
    Test.stopTest();

    // Then, TODO: test unsupported ones
    List<Boolean> correctResults = new List<Boolean>{
      true,
      true,
      true,
      true,
      true,
      true
    };

    for (Integer i = 0; i < claimToWasAutomated.size(); i++) {
      System.assertEquals(
        correctResults[i],
        claimToWasAutomated.get(new List<Id>(claimToWasAutomated.keySet())[i]),
        'Should automate correctly'
      );
    }
  }

  @isTest
  static void shouldCalculateIfInTimeForCompensation() {
    // Given
    List<LIA_Claim__c> claims = [
      SELECT Id, Case__c, Flight_Number__c, CreatedDate
      FROM LIA_Claim__c
      WHERE Phone_Number__c = '0000000000'
    ];
    List<Boolean> isFiledOnTimeResult = new List<Boolean>{};

    // When
    for (LIA_Claim__c claim : claims) {
      List<BookingJSON> booking = CustomerCardController.getBookingsForCase(
        String.valueOf(claim.Case__c)
      );
      isFiledOnTimeResult.add(
        AutomationUtils.isFiledOnTime(
          new AutomationUtils.AutomationContainer(claim, booking[0])
        )
      );
    }

    // Then
    List<Boolean> correctResults = new List<Boolean>{
      true,
      true,
      false,
      true,
      true,
      true
    };

    for (Integer i = 0; i < isFiledOnTimeResult.size(); i++) {
      System.assertEquals(
        correctResults[i],
        isFiledOnTimeResult[i],
        'Should automate correctly'
      );
    }
  }

  @isTest
  static void shouldCalculateDistanceBetweenAirports() {
    // Given
    Test.setMock(HttpCalloutMock.class, new APIMMock()); // Needed for TEDSbooking-fetches caused by trigger

    // When
    Test.startTest();
    AirportService.newInstance()
      .fetchAirportsByReference(airportIdsFromTEDS, true);
    Test.stopTest();

    // Then
    List<Airport__c> airportsFromDB = AirportsSelector.newInstance()
      .selectByTEDSId(airportIdsFromTEDS);

    Airport__c ARN;
    for (Airport__c a : airportsFromDB) {
      if (a.TEDS_Identifier__c == 'ARN') {
        ARN = a;
        break;
      }
    }

    for (Airport__c a : airportsFromDB) {
      switch on a.TEDS_Identifier__c {
        when 'HEL' {
          System.assertEquals(
            398569,
            AutomationUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between ARN and HEL correctly.'
          );
        }
        when 'ITM' {
          System.assertEquals(
            8062362,
            AutomationUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between ARN and ITM correctly.'
          );
        }
        when 'RUN' {
          System.assertEquals(
            9584413,
            AutomationUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between RUN and ARN correctly.'
          );
        }
        when 'SYD' {
          System.assertEquals(
            15597941,
            AutomationUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between SYD and ARN correctly.'
          );
        }
      }
    }
  }

  // TODO: Add support for multi flights
  @isTest
  static void shouldCalculateEU261Compensation() {
    //Given
    List<LIA_Claim__c> claims = [
      SELECT Id, Case__c, Flight_Number__c, CreatedDate
      FROM LIA_Claim__c
      WHERE Phone_Number__c = '0000000000'
    ];
    List<Integer> compensations = new List<Integer>{};

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    List<BookingJSON> relevantBookings = getRelevantBookings(claims);

    // When
    for (Integer i = 0; i < claims.size(); i++) {
      LIA_Claim__c claim = claims[i];
      AutomationUtils.AutomationContainer ac = new AutomationUtils.AutomationContainer(
        claim,
        relevantBookings[i]
      );
      compensations.add(AutomationUtils.calculateEU261Compensation(ac));
    }

    Test.stopTest();

    // Then
    List<Integer> correctCompensations = new List<Integer>{
      0,
      0,
      750,
      400,
      400,
      600
    }; // Delay not long enough, No passengers, 3 delayed < 1500km, 1 delayed >1500 km <3500km, 1 delayed intra community, 1 delayed >3500 >4hrs delay

    for (Integer i = 0; i < compensations.size(); i++) {
      System.assertEquals(
        correctCompensations[i],
        compensations[i],
        'Should calculate EU261 compensation correctly.'
      );
    }
  }

  private static List<BookingJSON> getRelevantBookings(
    List<LIA_Claim__c> claims
  ) {
    List<List<BookingJSON.Passenger>> bookingPassengers = new List<List<BookingJSON.Passenger>>{
      new List<BookingJSON.Passenger>{ null, null },
      new List<BookingJSON.Passenger>{},
      new List<BookingJSON.Passenger>{ null, null, null },
      new List<BookingJSON.Passenger>{ null },
      new List<BookingJSON.Passenger>{ null },
      new List<BookingJSON.Passenger>{ null }
    };
    List<String> departureAirports = new List<String>{
      'UME',
      'UME',
      'UME',
      'CDG',
      'RUN',
      'SYD'
    };
    List<BookingJSON> relevantBookings = new List<BookingJSON>{};
    for (Integer i = 0; i < claims.size(); i++) {
      LIA_Claim__c claim = claims[i];

      List<BookingJSON> booking = CustomerCardController.getBookingsForCase(
        String.valueOf(claim.Case__c)
      );
      booking[0].passengers = bookingPassengers[i];
      booking[0].type = 'OneWay';
      booking[0].flights[0].departureAirport = departureAirports[i];
      booking[0].flights[0].arrivalAirport = 'ARN';
      relevantBookings.add(booking[0]);
    }
    return relevantBookings;
  }
}
