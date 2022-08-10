@IsTest
private class AutomationUtils_Test {
  /**
   * Common setup for the test classes
   * WHAT IS CREATED:
   *
   * CLAIM 1:
   * In time for EU261. Flight inside the EU. 2 pax. Not eligable for care, not eligable for EU261. OneWay.
   *
   * CLAIM 2:
   * Just in time for EU261. Flight inside the EU. 0 pax. Eligable for care, not eligable EU261. OneWay.
   * Extra: Is a duplicate with CLAIM 7
   *
   * CLAIM 3:
   * Too late for EU261. Flight inside the EU. 3 pax. Eligable for care, eligable for 3*250 EUR EU261. OneWay.
   *
   * CLAIM 4:
   * In time for EU261. Flight inside the EU but >3500km. 1 pax. Eligable for care, eligable for 1*400 EUR EU261. OneWay.
   *
   * CLAIM 5:
   * In time for EU261. Flight inside the EU and <3500km. 1 pax. Eligable for care, eligable for 1*400 EUR EU261. OneWay.
   *
   * CLAIM 6:
   * In time for EU261. Flight from outside to inside the EU and >3500km. 1 pax. Eligable for care, eligable for 1*600 EUR EU261. OneWay.
   *
   * CLAIM 7:
   * In time for EU261. Flight inside the EU. 1 pax. Eligable for care, eligable for 0*250 EUR EU261. OneWay.
   * Extra: Is a duplicate with CLAIM 2 and 8
   *
   * CLAIM 8:
   * In time for EU261. Flight inside the EU. 1 pax. Eligable for care, eligable for 0*250 EUR EU261. OneWay.
   * Extra: Is a duplicate with CLAIM 7
   */
  @testSetup
  static void setup() {
    Date today = Date.today();
    Date inTime = today.addYears(-2);
    Date justInTime = today.addYears(-3).addDays(1); // Last day
    Date tooLate = today.addYears(-4);
    Date placeholderTime = today.addYears(-2);

    // Sch_Dep_T, Sch_Arr_T, Delay_Min, Dep_A, Arr_A
    List<List<Map<String, Object>>> flightsToCreate = new List<List<Map<String, Object>>>{
      new List<Map<String, Object>>{
        new Map<String, Object>{
          'Sch_Dep_T' => inTime,
          'Sch_Arr_T' => inTime,
          'Delay_Min' => 1
        }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Sch_Arr_T' => justInTime, 'Delay_Min' => 120 }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Sch_Arr_T' => tooLate, 'Delay_Min' => 181 }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Dep_A' => 'CDG', 'Delay_Min' => 181 }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Dep_A' => 'RUN', 'Delay_Min' => 241 }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Dep_A' => 'SYD', 'Delay_Min' => 400 }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Delay_Min' => 400 }
      },
      new List<Map<String, Object>>{
        new Map<String, Object>{ 'Delay_Min' => 400 }
      }
    };

    // Generate null variables and flight id
    for (Integer i = 0; i < flightsToCreate.size(); i++) {
      List<Map<String, Object>> flightsInABooking = flightsToCreate[i];
      for (Integer j = 0; j < flightsInABooking.size(); j++) {
        Map<String, Object> flight = flightsInABooking[j];
        Date flightTime = (Date) flight.get('Sch_Arr_T');
        String depAirport = (String) flight.get('Dep_A');
        String arrAirport = (String) flight.get('Arr_A');
        if (flightTime == null) {
          flightTime = placeholderTime;
        }
        if (arrAirport == null) {
          arrAirport = 'ARN';
        }
        if (depAirport == null) {
          depAirport = 'UME';
        }
        String flightId =
          'SK1' +
          String.valueOf(i) +
          '0' +
          String.valueOf(j) +
          '-' +
          String.valueOf(flightTime).remove('-') +
          '-' +
          depAirport +
          '-' +
          arrAirport;

        flight.put('TEDS_Id', flightId);
        flight.put('Sch_Arr_T', flightTime);
        flight.put('Arr_A', arrAirport);
        flight.put('Dep_A', depAirport);
      }
    }

    // Name, First_Name__c, Last_Name__c
    List<List<Map<String, String>>> customersToCreate = new List<List<Map<String, String>>>{
      new List<Map<String, String>>{ null, null },
      new List<Map<String, String>>{},
      new List<Map<String, String>>{ null, null, null },
      new List<Map<String, String>>{ null },
      new List<Map<String, String>>{ null },
      new List<Map<String, String>>{ null },
      new List<Map<String, String>>{
        new Map<String, String>{
          'Name' => 'Test Testsson',
          'First_Name__c' => 'Test',
          'Last_Name__c' => 'Testsson'
        }
      },
      new List<Map<String, String>>{
        new Map<String, String>{
          'Name' => 'Test Testsson',
          'First_Name__c' => 'Test',
          'Last_Name__c' => 'Testsson'
        }
      }
    };

    // Type
    List<Map<String, String>> bookingsToCreate = new List<Map<String, String>>{
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' },
      new Map<String, String>{ 'Type' => 'OneWay' }
    }; // TODO: add different types.

    List<Map<Schema.SObjectField, Object>> fieldsForClaimsToCreate = new List<Map<Schema.SObjectField, Object>>{};
    List<Map<Schema.SObjectField, Object>> fieldsForCasesToCreate = new List<Map<Schema.SObjectField, Object>>{};
    List<Map<Schema.SObjectField, Object>> fieldsForBookingsToCreate = new List<Map<Schema.SObjectField, Object>>{};
    List<List<Map<Schema.SObjectField, Object>>> fieldsForFlightsToCreate = new List<List<Map<Schema.SObjectField, Object>>>{};
    List<List<Map<Schema.SObjectField, Object>>> fieldsForCustomersToCreate = new List<List<Map<Schema.SObjectField, Object>>>{};

    for (
      Integer bookingIndex = 0;
      bookingIndex < bookingsToCreate.size();
      bookingIndex++
    ) {
      Map<String, String> booking = bookingsToCreate[bookingIndex];

      fieldsForClaimsToCreate.add(null);
      fieldsForCasesToCreate.add(
        new Map<Schema.SObjectField, Object>{ Case.Status => 'New' }
      );
      fieldsForBookingsToCreate.add(
        new Map<Schema.SObjectField, Object>{
          Booking__c.Type__c => booking.get('Type')
        }
      );

      List<Map<Schema.SObjectField, Object>> bookingFlights = new List<Map<Schema.SObjectField, Object>>{};
      List<Map<Schema.SObjectField, Object>> bookingCustomers = new List<Map<Schema.SObjectField, Object>>{};

      List<Map<String, Object>> flights = flightsToCreate[bookingIndex];
      for (Map<String, Object> flight : flights) {
        if (flight == null) {
          bookingFlights.add(null);
          continue;
        }
        bookingFlights.add(
          new Map<Schema.SObjectField, Object>{
            Flight__c.TEDS_Identifier__c => flight.get('TEDS_Id'),
            Flight__c.Scheduled_Arrival_Time__c => flight.get('Sch_Arr_T'),
            Flight__c.Arrival_Airport__c => flight.get('Arr_A'),
            Flight__c.Departure_Airport__c => flight.get('Dep_A'),
            Flight__c.Arrival_Delayed_Minutes__c => flight.get('Delay_Min')
          }
        );
      }

      List<Map<String, String>> customers = customersToCreate[bookingIndex];
      for (Map<String, String> customer : customers) {
        if (customer == null) {
          bookingCustomers.add(null);
          continue;
        }
        bookingCustomers.add(
          new Map<Schema.SObjectField, Object>{
            Customer__c.Name => customer.get('Name'),
            Customer__c.First_Name__c => customer.get('First_Name__c'),
            Customer__c.Last_Name__c => customer.get('Last_Name__c')
          }
        );
      }
      fieldsForFlightsToCreate.add(bookingFlights);
      fieldsForCustomersToCreate.add(bookingCustomers);
    }

    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    TestDataFactories.CasesClaimsBookings createdCasesClaimsBookings = TestDataFactories.createClaimsWithCasesBookingsFlightsAndCustomers(
      fieldsForClaimsToCreate,
      fieldsForCasesToCreate,
      fieldsForBookingsToCreate,
      fieldsForFlightsToCreate,
      fieldsForCustomersToCreate
    );
    Test.stopTest();

    List<SObject> objectsToUpdate = new List<SObject>{};

    // Make duplicates
    List<LIA_Claim__c> claims = createdCasesClaimsBookings.claims;

    // ??? (must have to do with trigger logic updating the ctb from the PNR)
    List<Booking__c> bookings = createdCasesClaimsBookings.bookings;
    CaseToBooking__c iDissapear = [
      SELECT Case__c, Booking__c
      FROM CaseToBooking__c
      WHERE Booking__c = :bookings[6].Id
    ][0];
    iDissapear.Id = null;
    // ???

    claims[6].Liability_PNR__c = claims[1].Liability_PNR__c;
    claims[6].Flight_Number__c = claims[7].Flight_Number__c;
    claims[6].Flight_Date__c = claims[7].Flight_Date__c;
    List<Segment__c> makeUsDuplicates = [
      SELECT Flight__c
      FROM Segment__c
      WHERE Segment__c.Booking__c IN (:bookings[6].Id, :bookings[7].Id)
    ];
    makeUsDuplicates[0].Flight__c = makeUsDuplicates[1].Flight__c;
    objectsToUpdate.add(makeUsDuplicates[0]);

    objectsToUpdate.add(claims[6]);
    update objectsToUpdate;
    insert iDissapear;
  }

  @isTest
  static void shouldAutomateTheRightCases() {
    // Given
    List<LIA_Claim__c> claims = [
      SELECT Id, Case__c, Flight_Number__c, CreatedDate
      FROM LIA_Claim__c
      WHERE Liability_PNR__c LIKE 'AUTO%'
    ];
    List<Id> claimIds = new List<Id>{};

    for (LIA_Claim__c c : claims) {
      claimIds.add(c.Id);
    }

    // When
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Map<Id, Boolean> claimToWasAutomated = AutomationUtils.automateEU261Claims(
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

    for (Boolean b : claimToWasAutomated.values()) {
      System.debug(b);
    }

    System.assert(
      claimToWasAutomated.values().size() == claims.size(),
      'Should automate all cases.'
    );

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
      SELECT Id, Case__c, Flight_Number__c, CreatedDate, Flight_Date__c
      FROM LIA_Claim__c
      WHERE Liability_PNR__c LIKE 'AUTO%'
    ];
    List<Boolean> isFiledOnTimeResult = new List<Boolean>{};

    // When
    // TODO: Do this in batch
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    for (LIA_Claim__c claim : claims) {
      Booking__c booking = getClaimBooking(claim);
      List<AutomationUtils.Trip> trips = getBookingTrips(booking);

      isFiledOnTimeResult.add(
        AutomationUtils.isFiledOnTime(
          new AutomationUtils.AutomationInfoContainer(claim, booking, trips)
        )
      );
    }
    Test.stopTest();

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

    System.assert(
      isFiledOnTimeResult.size() == claims.size(),
      'Should check if all claims are filed on time.'
    );

    for (Integer i = 0; i < isFiledOnTimeResult.size(); i++) {
      System.assertEquals(
        correctResults[i],
        isFiledOnTimeResult[i],
        'Should automate correctly'
      );
    }
  }

  @isTest
  static void shouldCalculateEU261Compensation() {
    //Given
    // TODO: fix
    List<LIA_Claim__c> claimsWithoutData = [
      SELECT Id
      FROM LIA_Claim__c
      WHERE Liability_PNR__c LIKE 'AUTO%'
    ];
    List<Integer> compensations = new List<Integer>{};

    Set<Id> claimIds = new Set<Id>{};
    for (LIA_Claim__c claim : claimsWithoutData) {
      claimIds.add(claim.Id);
    }

    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectByCaseIdWithCustomers(claimIds);
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();

    // When
    // TODO: batch
    for (Integer i = 0; i < claims.size(); i++) {
      Booking__c booking = getClaimBooking(claims[i]);
      List<AutomationUtils.Trip> trips = getBookingTrips(booking);
      AutomationUtils.AutomationInfoContainer ac = new AutomationUtils.AutomationInfoContainer(
        claims[i],
        booking,
        trips
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

    System.assert(
      compensations.size() == claims.size(),
      'Should calculate all compensations.'
    );

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
      [SELECT Id FROM LIA_Claim__c WHERE Liability_PNR__c IN ('AUTO1', 'AUTO2')]
    );
    claimsToCheck.addAll(
      [SELECT Id FROM LIA_Claim__c WHERE Liability_PNR__c IN ('AUTO6', 'AUTO7')]
    );

    List<Id> claimIdsToCheck = new List<Id>{};
    Map<Id, Boolean> claimIdToIsDuplicateCorrect = new Map<Id, Boolean>{};
    Map<String, Boolean> correctIsDuplicate = new Map<String, Boolean>{
      'AUTO1' => true,
      'AUTO2' => false,
      'AUTO6' => true,
      'AUTO7' => true
    }; // Duplicate duplicate with no. 3, not , duplicate with no. 1 and 4, duplicate with no. 3
    for (Integer i = 0; i < claimsToCheck.size(); i++) {
      claimIdsToCheck.add(claimsToCheck[i].Id);
    }

    List<LIA_Claim__c> claimsWithPassengersToCheck = ClaimsSelector.newInstance()
      .selectByIdWithCustomers(new Set<Id>(claimIdsToCheck));

    // When
    // TODO: batch
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    Map<String, Boolean> claimIdToIsDuplicate = new Map<String, Boolean>{};
    List<String> pnrOrder = new List<String>{};
    for (Integer i = 0; i < claimsWithPassengersToCheck.size(); i++) {
      LIA_Claim__c claim = claimsWithPassengersToCheck[i];
      pnrOrder.add(claim.Liability_PNR__c);
      Booking__c booking = getClaimBooking(claim);
      List<AutomationUtils.Trip> trips = getBookingTrips(booking);

      AutomationUtils.AutomationInfoContainer ac = new AutomationUtils.AutomationInfoContainer(
        claim,
        booking,
        trips
      );
      claimIdToIsDuplicate.put(
        claim.Liability_PNR__c,
        AutomationUtils.isDuplicate(ac)
      );
    }

    Test.stopTest();

    // Then
    for (String claimId : pnrOrder) {
      System.assertEquals(
        correctIsDuplicate.get(claimId),
        claimIdToIsDuplicate.get(claimId),
        'Should assert if the claim is a duplicate or not.'
      );
    }
  }

  // TODO: Implement form to resolution (end-to-end) tests

  private static Booking__c getClaimBooking(LIA_Claim__c claim) {
    List<CaseToBooking__c> ctbs = CaseToBookingsSelector.newInstance()
      .selectByCaseId(new Set<Id>{ claim.Case__c });
    List<Booking__c> bookings = BookingsSelector.newInstance()
      .selectByIdFull(new Set<Id>{ ctbs[0].Booking__c });
    return bookings[0];
  }

  private static List<AutomationUtils.Trip> getBookingTrips(
    Booking__c booking
  ) {
    List<AutomationUtils.Trip> tripsWithAirports = new List<AutomationUtils.Trip>{};
    for (
      AutomationUtils.Trip t : AutomationUtils.divideIntoTrips(
        booking,
        booking.Segments__r
      )
    ) {
      t.forceSetFlights();
      tripsWithAirports.add(t);
    }

    return tripsWithAirports;
  }
}
