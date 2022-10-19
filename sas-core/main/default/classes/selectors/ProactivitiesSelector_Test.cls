@IsTest
private class ProactivitiesSelector_Test {
  private static ProactivitiesSelector proactivites = ProactivitiesSelector.newInstance();

  @testSetup
  static void setup() {
    Date today = Date.today();

    Proactivity__c normalProactivity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Email__c = 'test@test.com'
    );
    Proactivity__c majorEventProactivity = new Proactivity__c(
      Note__c = 'Test 2',
      Type__c = 'Major Event',
      Email__c = 'test@test.com',
      Phone_Number__c = '0000000000'
    );
    Proactivity__c airportMatcherProactivity = new Proactivity__c(
      Note__c = 'Test 3',
      Type__c = 'Normal',
      Airport__c = 'ARN',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c cancellationCodeProactivity = new Proactivity__c(
      Note__c = 'Test 4',
      Type__c = 'Normal',
      Cancellation_Code__c = 'AIRS',
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c airportMatcherAndCancellationCodeProactivity = new Proactivity__c(
      Note__c = 'Test 5',
      Type__c = 'Normal',
      Cancellation_Code__c = 'AIRS',
      Airport__c = 'ARN',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today
    );
    Proactivity__c directlyMatchedProactivity = new Proactivity__c(
      Note__c = 'Test 6',
      Type__c = 'Normal'
    );
    Proactivity__c strikeCodeProactivity = new Proactivity__c(
      Note__c = 'Test 7',
      Type__c = 'Normal',
      Cancellation_Code__c = 'INDU',
      From_Date__c = today,
      To_Date__c = today
    );

    Case caseWithOneProactivityRegularMatcher = new Case(
      FCS_EBNumber__c = '000000001'
    );
    Case caseWithTwoProactivitiesRegularMatcher = new Case(
      FCS_EBNumber__c = '000000002'
    );
    Case caseWithOneProactivityAirportMatcher = new Case(
      FCS_EBNumber__c = '000000003'
    );
    Case caseWithOneProactivityCancellationCodeMatcher = new Case(
      FCS_EBNumber__c = '000000004'
    );
    Case caseWithThreeProactivitiesCancellationCodeAndAirportMatcher = new Case(
      FCS_EBNumber__c = '000000005'
    );
    Case caseWithNoRelevantClaimFlight = new Case(
      FCS_EBNumber__c = '000000007'
    );

    insert new List<SObject>{
      caseWithOneProactivityRegularMatcher,
      caseWithTwoProactivitiesRegularMatcher,
      caseWithOneProactivityAirportMatcher,
      caseWithOneProactivityCancellationCodeMatcher,
      caseWithThreeProactivitiesCancellationCodeAndAirportMatcher,
      caseWithNoRelevantClaimFlight,
      directlyMatchedProactivity
    };

    Case caseWithDirectMatch = new Case(
      FCS_EBNumber__c = '000000006',
      Proactivity__c = directlyMatchedProactivity.Id
    );

    LIA_Claim__c claimWithOneProactivityRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityRegularMatcher.Id,
      Phone_Number__c = '0000000000'
    );
    LIA_Claim__c claimWithTwoProactivitiesRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithTwoProactivitiesRegularMatcher.Id,
      Contact_Email__c = 'test@test.com'
    );
    LIA_Claim__c claimWithOneProactivityAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityAirportMatcher.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK1'),
      Flight_Date__c = today
    );

    LIA_Claim__c claimWithOneProactivityCancellationCodeMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityCancellationCodeMatcher.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK2'),
      Flight_Date__c = today
    );

    LIA_Claim__c claimWithThreeProactivitesCancellationCodeAndAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK3'),
      Liability_PNR__c = 'ABC123',
      Flight_Date__c = today
    );

    LIA_Claim__c claimWithNoIrrelevantClaimFlight = new LIA_Claim__c(
      Case__c = caseWithNoRelevantClaimFlight.Id,
      Flight_Number__c = Flight.normalizeFlightNumber('SK8'),
      Liability_PNR__c = 'ABC124',
      Flight_Date__c = today
    );

    String flightIdentifier1 =
      Flight.constructTEDSFlightNumberDate('SK1', today) + '-UME-ARN';

    String flightIdentifier2 =
      Flight.constructTEDSFlightNumberDate('SK2', today) + '-ARN-UME';

    String flightIdentifier3 =
      Flight.constructTEDSFlightNumberDate('SK3', today) + '-UME-ARN';

    String flightIdentifier4 =
      Flight.constructTEDSFlightNumberDate('SK4', today) + '-UME-ARN';

    Flight__c flight1 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier1
    );

    Flight__c flight2 = new Flight__c(
      Arrival_Airport__c = 'UME',
      Departure_Airport__c = 'ARN',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier2
    );

    Flight__c flight3 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier3
    );

    Flight__c flight4 = new Flight__c(
      Arrival_Airport__c = 'ARN',
      Departure_Airport__c = 'UME',
      Scheduled_Arrival_Time__c = today,
      Scheduled_Departure_Time__c = today,
      TEDS_Identifier__c = flightIdentifier4
    );

    Booking__c flight3Booking = new Booking__c(
      TEDS_Identifier__c = 'ABC123',
      Booking_Reference__c = 'ABC123'
    );
    Booking__c flight4Booking = new Booking__c(
      TEDS_Identifier__c = 'ABC124',
      Booking_Reference__c = 'ABC124'
    );

    insert new List<SObject>{
      flight1,
      flight2,
      flight3,
      flight4,
      flight3Booking,
      flight4Booking
    };

    CaseToBooking__c ctb1 = new CaseToBooking__c(
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id,
      Booking__c = flight3Booking.Id
    );
    CaseToBooking__c ctb2 = new CaseToBooking__c(
      Case__c = caseWithNoRelevantClaimFlight.Id,
      Booking__c = flight4Booking.Id
    );
    Segment__c seg1 = new Segment__c(
      Booking__c = flight3Booking.Id,
      Flight__c = flight3.Id
    );
    Segment__c seg2 = new Segment__c(
      Booking__c = flight4Booking.Id,
      Flight__c = flight1.Id
    );
    Segment__c seg3 = new Segment__c(
      Booking__c = flight4Booking.Id,
      Flight__c = flight4.Id
    );

    FlightIrregularities__c flightIrregularity1 = new FlightIrregularities__c(
      Flight__c = flight1.Id,
      Code__c = 'AUTH'
    );

    FlightIrregularities__c flightIrregularity2 = new FlightIrregularities__c(
      Flight__c = flight2.Id,
      Code__c = 'AIRS'
    );

    FlightIrregularities__c flightIrregularity3 = new FlightIrregularities__c(
      Flight__c = flight3.Id,
      Code__c = 'AIRS'
    );

    FlightIrregularities__c flightIrregularity4 = new FlightIrregularities__c(
      Flight__c = flight4.Id,
      Code__c = 'INDU'
    );

    insert new List<SObject>{
      ctb1,
      ctb2,
      seg1,
      seg2,
      seg3,
      flightIrregularity1,
      flightIrregularity2,
      flightIrregularity3,
      flightIrregularity4,
      normalProactivity,
      majorEventProactivity,
      airportMatcherProactivity,
      cancellationCodeProactivity,
      airportMatcherAndCancellationCodeProactivity,
      strikeCodeProactivity,
      claimWithOneProactivityRegularMatcher,
      claimWithTwoProactivitiesRegularMatcher,
      claimWithOneProactivityAirportMatcher,
      claimWithOneProactivityCancellationCodeMatcher,
      claimWithThreeProactivitesCancellationCodeAndAirportMatcher,
      claimWithNoIrrelevantClaimFlight,
      caseWithDirectMatch
    };
  }

  @IsTest
  static void shouldSelectNormalProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 2'
    ][0];
    Case caseWithOneProactivityRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000001'
    ][0];

    // When
    List<Proactivity__c> oneProactivityRegularMatcher = proactivites.selectByCaseId(
      caseWithOneProactivityRegularMatcher.Id
    );

    // Then
    System.assertEquals(
      1,
      oneProactivityRegularMatcher.size(),
      'Should select a single proactivity from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityRegularMatcher[0].Id,
      'Should select a single proactivity from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectMajorEventProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity1 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 1'
    ][0];
    Proactivity__c correctProactivity2 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 2'
    ][0];
    Case caseWithTwoProactivitiesRegularMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000002'
    ][0];
    // When
    List<Proactivity__c> twoProactivitiesRegularMatcher = proactivites.selectByCaseId(
      caseWithTwoProactivitiesRegularMatcher.Id
    );

    // Then
    Integer correctlyMatched = 0;
    for (Proactivity__c p : twoProactivitiesRegularMatcher) {
      if (p.id == correctProactivity1.Id || p.id == correctProactivity2.Id) {
        correctlyMatched += 1;
      }
    }

    System.assertEquals(
      2,
      twoProactivitiesRegularMatcher.size(),
      'Should select two proactivities from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      2,
      correctlyMatched,
      'Should select two proactivities from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectAirportMatcherProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    Case caseWithOneProactivityAirportMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000003'
    ][0];
    // When
    List<Proactivity__c> oneProactivityAirportMatcher = proactivites.selectByCaseId(
      caseWithOneProactivityAirportMatcher.Id
    );

    // Then
    System.assertEquals(
      1,
      oneProactivityAirportMatcher.size(),
      'Should select a single proactivity with an airport matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityAirportMatcher[0].Id,
      'Should select a single proactivity with an airport matcher from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectCancellationCodeProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 4'
    ][0];
    Case caseWithOneProactivityCancellationCodeMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000004'
    ][0];
    // When
    List<Proactivity__c> oneProactivityCancellationCodeMatcher = proactivites.selectByCaseId(
      caseWithOneProactivityCancellationCodeMatcher.Id
    );

    // Then
    System.assertEquals(
      1,
      oneProactivityCancellationCodeMatcher.size(),
      'Should select a single proactivity with a cancellation code matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityCancellationCodeMatcher[0].Id,
      'Should select a single proactivity with a cancellation code matcher from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectCancellationCodeAndAirportProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity1 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    Proactivity__c correctProactivity2 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 4'
    ][0];
    Proactivity__c correctProactivity3 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 5'
    ][0];
    Case caseWithThreeProactivitiesCancellationCodeAndAirportMatcher = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000005'
    ][0];
    // When
    List<Proactivity__c> threeProactivitiesCancellationCodeAndAirportMatcher = proactivites.selectByCaseId(
      caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id
    );

    Integer correctlyMatched = 0;
    for (
      Proactivity__c p : threeProactivitiesCancellationCodeAndAirportMatcher
    ) {
      if (
        p.id == correctProactivity1.Id ||
        p.id == correctProactivity2.Id ||
        p.id == correctProactivity3.Id
      ) {
        correctlyMatched += 1;
      }
    }
    // Then
    System.assertEquals(
      3,
      correctlyMatched,
      'Should select three proactivities with a cancellation code and airport matcher from case ID correctly (too many/few matches)'
    );
  }

  @IsTest
  static void shouldSelectDirectlyLinkedProactivityByCaseIdTest() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 6'
    ][0];
    Case caseWithDirectMatch = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000006'
    ][0];

    // When
    List<Proactivity__c> directMatchProactivity = proactivites.selectByCaseId(
      caseWithDirectMatch.Id
    );

    // Then
    System.assertEquals(
      1,
      directMatchProactivity.size(),
      'Should select a single proactivity with a direct match from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      directMatchProactivity[0].Id,
      'Should select a single proactivity with a direct match from case ID correctly (wrong proactivity)'
    );
  }

  @IsTest
  static void shouldSelectNonClaimFlightProactivites() {
    // Given (setup)
    Proactivity__c correctProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 3'
    ][0];
    Proactivity__c correctProactivity2 = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 7'
    ][0];
    Case caseWithIrrelevantClaimFlight = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000007'
    ][0];

    // When
    List<Proactivity__c> nonClaimFlightProactiviies = proactivites.selectByCaseId(
      caseWithIrrelevantClaimFlight.Id
    );

    for (Proactivity__c p : nonClaimFlightProactiviies) {
      Proactivity__c pasdf = p;
    }

    // Then
    System.assertEquals(
      2,
      nonClaimFlightProactiviies.size(),
      'Should select a single proactivity with a direct match from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      nonClaimFlightProactiviies[0].Id,
      'Should select a single proactivity with a direct match from case ID correctly (wrong proactivity)'
    );
    System.assertEquals(
      correctProactivity2.Id,
      nonClaimFlightProactiviies[1].Id,
      'Should select a single proactivity with a direct match from case ID correctly (wrong proactivity)'
    );
  }
}
