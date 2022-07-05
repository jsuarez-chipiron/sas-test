@IsTest
private class AutomationUtils_Test {
  /**
   * Common setup for the test classes
   */
  @testSetup
  static void setup() {
    Date today = Date.today();
    Date inTime = today.addYears(-2);
    Date justInTime = today.addYears(-2).addMonths(-11).addDays(-30); // Last day
    Date tooLate = today.addYears(-4);

    Case case1 = new Case();
    Case case2 = new Case();
    Case case3 = new Case();

    insert new List<Case>{ case1, case2, case3 };

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

    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = inTime,
      Scheduled_Departure_Time__c = inTime,
      TEDS_Identifier__c = flightIdentifier1,
      Arrival_Delayed_Minutes__c = 1
    );
    Flight__c flight2 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = justInTime,
      Scheduled_Departure_Time__c = justInTime,
      TEDS_Identifier__c = flightIdentifier2,
      Arrival_Delayed_Minutes__c = 120
    );
    Flight__c flight3 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = tooLate,
      Scheduled_Departure_Time__c = tooLate,
      TEDS_Identifier__c = flightIdentifier3,
      Arrival_Delayed_Minutes__c = 160
    );

    insert new List<Flight__c>{ flight1, flight2, flight3 };

    LIA_Claim__c claim1 = new LIA_Claim__c(
      Case__c = case1.Id,
      Phone_Number__c = '0000000000',
      Liability_PNR__c = 'ABC123',
      Flight_Number__c = flightIdentifier1
    );
    LIA_Claim__c claim2 = new LIA_Claim__c(
      Case__c = case2.Id,
      Phone_Number__c = '0000000000',
      Liability_PNR__c = 'ABC124',
      Flight_Number__c = flightIdentifier2
    );
    LIA_Claim__c claim3 = new LIA_Claim__c(
      Case__c = case3.Id,
      Phone_Number__c = '0000000000',
      Liability_PNR__c = 'ABC125',
      Flight_Number__c = flightIdentifier3
    );

    FlightIrregularities__c flightIrregularity1 = new FlightIrregularities__c(
      Flight__c = flight1.Id,
      Code__c = 'AUTH'
    );

    Booking__c booking1 = new Booking__c(
      TEDS_Identifier__c = 'ABC123',
      Booking_Reference__c = 'ABC123',
      Type__c = 'OneWay'
    );
    Booking__c booking2 = new Booking__c(
      TEDS_Identifier__c = 'ABC124',
      Booking_Reference__c = 'ABC124',
      Type__c = 'OneWay'
    );
    Booking__c booking3 = new Booking__c(
      TEDS_Identifier__c = 'ABC125',
      Booking_Reference__c = 'ABC125',
      Type__c = 'OneWay'
    );

    insert new List<Booking__c>{ booking1, booking2, booking3 };

    Segment__c segment1 = new Segment__c(
      Booking__c = booking1.Id,
      Flight__c = flight1.Id,
      Identifier__c = 'ST' + 'A' + 'PT' + 'A'
    );
    Segment__c segment2 = new Segment__c(
      Booking__c = booking2.Id,
      Flight__c = flight2.Id,
      Identifier__c = 'ST' + 'A' + 'PT' + 'A'
    );
    Segment__c segment3 = new Segment__c(
      Booking__c = booking3.Id,
      Flight__c = flight3.Id,
      Identifier__c = 'ST' + 'A' + 'PT' + 'A'
    );

    CaseToBooking__c ctb1 = new CaseToBooking__c(
      Booking__c = booking1.Id,
      Case__c = case1.Id
    );
    CaseToBooking__c ctb2 = new CaseToBooking__c(
      Booking__c = booking2.Id,
      Case__c = case2.Id
    );
    CaseToBooking__c ctb3 = new CaseToBooking__c(
      Booking__c = booking3.Id,
      Case__c = case3.Id
    );

    insert new List<SObject>{
      claim1,
      claim2,
      claim3,
      flightIrregularity1,
      segment1,
      segment2,
      segment3,
      ctb1,
      ctb2,
      ctb3
    };
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
    Map<Id, Boolean> claimToWasAutomated = AutomationUtils.automateEU261(
      new Set<Id>(claimIds)
    );

    // Then
    List<Boolean> correctResults = new List<Boolean>{ true, true, false };

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
      isFiledOnTimeResult.add(AutomationUtils.isFiledOnTime(claim, booking[0]));
    }

    // Then
    List<Boolean> correctResults = new List<Boolean>{ true, true, false };

    for (Integer i = 0; i < isFiledOnTimeResult.size(); i++) {
      System.assertEquals(
        correctResults[i],
        isFiledOnTimeResult[i],
        'Should automate correctly'
      );
    }
  }

  @isTest
  static void shouldCalculateIfDelayLargeEnoughForCompensation() {
    // Given
    //   List<LIA_Claim__c> claims = [
    //     SELECT Id, Case__c, Flight_Number__c, CreatedDate
    //     FROM LIA_Claim__c
    //     WHERE Phone_Number__c = '0000000000'
    //   ];
    //   List<Boolean> isFiledOnTimeResult = new List<Boolean>{};

    //   // When
    //   for (LIA_Claim__c claim : claims) {
    //     List<BookingJSON> booking = CustomerCardController.getBookingsForCase(
    //       String.valueOf(claim.Case__c)
    //     );
    //     isFiledOnTimeResult.add(AutomationUtils.isFiledOnTime(claim, booking[0]));
    //   }

    //   // Then
    //   List<Boolean> correctResults = new List<Boolean>{ true, true, false };

    //   for (Integer i = 0; i < isFiledOnTimeResult.size(); i++) {
    //     System.assertEquals(
    //       correctResults[i],
    //       isFiledOnTimeResult[i],
    //       'Should automate correctly'
    //     );
    //   }
  }
}
