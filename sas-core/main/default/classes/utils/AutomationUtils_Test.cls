@IsTest
private class AutomationUtils_Test {
  /**
   * Common setup for the test classes
   * TODO: Break out into testfactory or at least simplify
   * WHAT IS CREATED:
   * Parentheses signify dynamic values. E.g. "no. pax 0 (1)" means that 0 pax are inserted but during a test 1 is "faked"
   *
   * CLAIM 1:
   * In time for EU261.
   * Flight inside the EU.
   * No. pax 0.
   * Delayed for 1 minute. (Not eligable for care, not eligable for EU261)
   * Type: OneWay.
   * Extra: Is a duplicate with CLAIM 7
   *
   * CLAIM 2:
   * Just in time for EU261.
   * Flight inside the EU.
   * No. pax 0.
   * Delayed for 120 minutes. (Eligable for care, not eligable EU261)
   * Type: OneWay.
   *
   * CLAIM 3:
   * Too late for EU261.
   * Flight inside the EU.
   * No. pax 0 (3).
   * Delayed for 181 minutes. (Eligable for care, eligable for (3*250) EUR EU261)
   * Type: OneWay.
   *
   * CLAIM 4:
   * In time for EU261.
   * Flight inside the EU but >3500km.
   * No. pax 0 (1).
   * Delayed for 181 minutes. (Eligable for care, eligable for (1*400) EUR EU261)
   * Type: OneWay.
   *
   * CLAIM 5:
   * In time for EU261.
   * Flight inside the EU and <3500km.
   * No. pax 0 (1).
   * Delayed for 241 minutes. (Eligable for care, eligable for (1*400) EUR EU261)
   * Type: OneWay.
   *
   * CLAIM 6:
   * In time for EU261.
   * Flight from outside to inside the EU and >3500km.
   * No. pax 0 (1).
   * Delayed for 400 minutes. (Eligable for care, eligable for (1*600) EUR EU261)
   * Type: OneWay.
   *
   * CLAIM 7:
   * In time for EU261.
   * Flight inside the EU.
   * No. pax 1 (0).
   * Delayed for 400 minutes. (Eligable for care, eligable for (0*250) EUR EU261)
   * Type: OneWay.
   * Extra: Is a duplicate with CLAIM 1 and 8
   *
   * CLAIM 8:
   * In time for EU261.
   * Flight inside the EU.
   * No. pax 1 (0).
   * Delayed for 400 minutes. (Eligable for care, eligable for (0*250) EUR EU261)
   * Type: OneWay.
   * Extra: Is a duplicate with CLAIM 7
   */
  @testSetup
  static void setup() {
    Date today = Date.today();
    Date inTime = today.addYears(-2);
    Date justInTime = today.addYears(-3).addDays(1); // Last day
    Date tooLate = today.addYears(-4);
    Date placeholderTime = today.addYears(-2);

    List<Booking__c> createdBookings = TestDataFactories.createBookings(
      3,
      'AUTO'
    );
    createdBookings.addAll(TestDataFactories.createBookings(5, 'AUTO1')); // Because Salesforce (chunks)

    List<String> bookingReferences = new List<String>{
      'AUTO0',
      'AUTO1',
      'AUTO2',
      'AUTO10',
      'AUTO11',
      'AUTO12',
      'AUTO13',
      'AUTO14'
    }; // TODO: refactor

    List<SObject> toUpdate = new List<SObject>{};
    List<Case> casesToCreate = new List<Case>{};
    for (Integer i = 0; i < bookingReferences.size(); i++) {
      casesToCreate.add(new Case());
    }

    insert casesToCreate;

    List<String> departureAirports = new List<String>{
      'UME',
      'UME',
      'UME',
      'RUN',
      'CDG',
      'SYD',
      'UME',
      'UME'
    };

    String formattedToday = String.valueOf(today).remove('-');
    List<String> customFlightIds = new List<String>{};
    for (Integer i = 0; i < createdBookings.size(); i++) {
      customFlightIds.add(
        'SK' +
        String.valueOf(i + 1) +
        '-' +
        formattedToday +
        '-' +
        departureAirports[i] +
        '-ARN'
      );
    }

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
      400,
      400,
      400
    }; // TODO: add 160
    List<Date> flightDates = new List<Date>{
      inTime,
      justInTime,
      tooLate,
      placeholderTime,
      placeholderTime,
      placeholderTime,
      placeholderTime,
      placeholderTime
    };

    List<String> bookingTypes = new List<String>{
      'OneWay',
      'OneWay',
      'OneWay',
      'OneWay',
      'OneWay',
      'OneWay',
      'OneWay',
      'OneWay'
    }; // TODO: add multiple types

    // First update/insert pass
    for (Integer i = 0; i < createdBookings.size(); i++) {
      Booking__c booking = createdBookings[i];
      Case c = casesToCreate[i];
      String flightId = customFlightIds[i];

      booking.Type__c = bookingTypes[i];
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
      flight.Departure_Airport__c = departureAirports[i];
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
    Map<Id, LIA_Claim__c> bookingIdToClaim = new Map<Id, LIA_Claim__c>{};

    // Second update/insert pass
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
        Flight_Number__c = flightId.substringBefore('-'),
        Flight_Date__c = flightDates[i]
      );

      // Modify cases for some of the tests
      toInsert2.add(claim);
      bookingIdToClaim.put(booking.Id, claim);
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

    List<Sobject> toInsert3 = new List<Sobject>{};
    List<Sobject> toUpdate3 = new List<Sobject>{};
    Id auto13FlightId;
    String auto13FlightNumber;
    Date auto13FlightDate;
    // Third update/insert pass
    for (Integer i = 0; i < createdBookings.size(); i++) {
      Booking__c booking = createdBookings[i];
      LIA_Claim__c claim = bookingIdToClaim.get(booking.Id);
      Flight__c flight = bookingIdToFlight.get(booking.Id);
      Segment__c segment = bookingIdToSegment.get(booking.Id);

      // Modify cases for some of the tests
      switch on booking.TEDS_Identifier__c {
        when 'AUTO0' {
          toInsert3.add(
            new FlightIrregularities__c(Flight__c = flight.Id, Code__c = 'AUTH')
          );
        }
        when 'AUTO13' {
          claim.Phone_Number__c = '0000000001';
          claim.Liability_PNR__c = 'AUTO1';
          auto13FlightId = flight.Id;
          auto13FlightNumber = claim.Flight_Number__c;
          auto13FlightDate = claim.Flight_Date__c;
          toInsert3.add(
            new Customer__c(
              Name = 'Test Testsson',
              First_Name__c = 'Test',
              Last_Name__c = 'Testsson',
              Claim__c = claim.Id
            )
          );
          toUpdate3.add(claim);
        }
        when 'AUTO14' {
          segment.Flight__c = auto13FlightId;
          claim.Phone_Number__c = '0000000001';
          claim.Flight_Number__c = auto13FlightNumber;
          claim.Flight_Date__c = auto13FlightDate;
          toInsert3.add(
            new Customer__c(
              Name = 'Test Testsson',
              First_Name__c = 'Test',
              Last_Name__c = 'Testsson',
              Claim__c = claim.Id
            )
          );
          toUpdate3.add(claim);
          toUpdate3.add(segment);
        }
      }
    }

    update toUpdate3;
    insert toInsert3;
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
      false,
      true,
      true,
      true,
      true,
      false,
      false
    }; // -, Duplicate, -{4}, Duplicate, Duplicate

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
      600,
      0,
      0
    }; // Delay not long enough, No passengers, 3 delayed < 1500km, 1 delayed >1500 km <3500km, 1 delayed >3500km but intra community, 1 delayed >3500 >4hrs delay, -

    for (Integer i = 0; i < compensations.size(); i++) {
      System.assertEquals(
        correctCompensations[i],
        compensations[i],
        'Should calculate EU261 compensation correctly.'
      );
    }
  }

  @isTest
  static void shouldIdentifyDuplicateCases() {
    //Given
    List<LIA_Claim__c> claimsToCheck = new List<LIA_Claim__c>{};
    claimsToCheck.addAll(
      [SELECT Id FROM LIA_Claim__c WHERE Phone_Number__c = '0000000000' LIMIT 2]
    );
    claimsToCheck.addAll(
      [SELECT Id FROM LIA_Claim__c WHERE Phone_Number__c = '0000000001']
    );

    List<Id> claimIdsToCheck = new List<Id>{};
    Map<Id, Boolean> claimIdToIsDuplicateCorrect = new Map<Id, Boolean>{};
    List<Boolean> correctIsDuplicate = new List<Boolean>{
      false,
      true,
      true,
      true
    }; // Not duplicate, duplicate with no. 3, duplicate with no. 2 and 4, duplicate with no. 3
    for (Integer i = 0; i < claimsToCheck.size(); i++) {
      claimIdsToCheck.add(claimsToCheck[i].Id);
      claimIdToIsDuplicateCorrect.put(
        claimsToCheck[i].Id,
        correctIsDuplicate[i]
      );
    }

    List<LIA_Claim__c> claimsWithPassengersToCheck = ClaimsSelector.newInstance()
      .selectByIdWithCustomers(new Set<Id>(claimIdsToCheck));

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    List<BookingJSON> relevantBookings = getRelevantBookings(
      claimsWithPassengersToCheck
    );

    // When
    Map<Id, Boolean> claimIdToIsDuplicate = new Map<Id, Boolean>{};

    for (Integer i = 0; i < claimsWithPassengersToCheck.size(); i++) {
      LIA_Claim__c claim = claimsWithPassengersToCheck[i];
      AutomationUtils.AutomationContainer ac = new AutomationUtils.AutomationContainer(
        claim,
        relevantBookings[i]
      );
      claimIdToIsDuplicate.put(claim.Id, AutomationUtils.isDuplicate(ac));
    }

    Test.stopTest();

    // Then
    for (Id claimId : claimIdToIsDuplicate.keySet()) {
      System.assertEquals(
        claimIdToIsDuplicateCorrect.get(claimId),
        claimIdToIsDuplicate.get(claimId),
        'Should assert if the claim is a duplicate or not.'
      );
    }
  }

  private static List<BookingJSON> getRelevantBookings(
    List<LIA_Claim__c> claims
  ) {
    // Artificially set pax
    List<List<BookingJSON.Passenger>> bookingPassengers = new List<List<BookingJSON.Passenger>>{
      new List<BookingJSON.Passenger>{ null, null },
      new List<BookingJSON.Passenger>{},
      new List<BookingJSON.Passenger>{ null, null, null },
      new List<BookingJSON.Passenger>{ null },
      new List<BookingJSON.Passenger>{ null },
      new List<BookingJSON.Passenger>{ null },
      new List<BookingJSON.Passenger>{},
      new List<BookingJSON.Passenger>{}
    };
    List<String> departureAirports = new List<String>{
      'UME',
      'UME',
      'UME',
      'CDG',
      'RUN',
      'SYD',
      'UME',
      'UME'
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
