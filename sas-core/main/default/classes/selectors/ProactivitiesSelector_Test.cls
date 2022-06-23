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

    insert new List<Case>{
      caseWithOneProactivityRegularMatcher,
      caseWithTwoProactivitiesRegularMatcher,
      caseWithOneProactivityAirportMatcher,
      caseWithOneProactivityCancellationCodeMatcher,
      caseWithThreeProactivitiesCancellationCodeAndAirportMatcher
    };

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
      Flight_Number__c = 'SK1',
      Flight_Date__c = today
    );
    LIA_Claim__c claimWithOneProactivityCancellationCodeMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityCancellationCodeMatcher.Id,
      Flight_Number__c = 'SK2',
      Flight_Date__c = today
    );
    LIA_Claim__c claimWithThreeProactivitesCancellationCodeAndAirportMatcher = new LIA_Claim__c(
      Case__c = caseWithThreeProactivitiesCancellationCodeAndAirportMatcher.Id,
      Flight_Number__c = 'SK3',
      Flight_Date__c = today
    );

    String flightIdentifier1 =
      'SK1-' +
      String.valueOf(today).remove('-') +
      '-UME-ARN';

    String flightIdentifier2 =
      'SK2-' +
      String.valueOf(today).remove('-') +
      '-ARN-UME';

    String flightIdentifier3 =
      'SK3-' +
      String.valueOf(today).remove('-') +
      '-UME-ARN';

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

    insert new List<Flight__c>{ flight1, flight2, flight3 };

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

    insert new List<SObject>{
      flightIrregularity1,
      flightIrregularity2,
      flightIrregularity3,
      normalProactivity,
      majorEventProactivity,
      airportMatcherProactivity,
      cancellationCodeProactivity,
      claimWithOneProactivityRegularMatcher,
      claimWithTwoProactivitiesRegularMatcher,
      claimWithOneProactivityAirportMatcher,
      claimWithOneProactivityCancellationCodeMatcher,
      airportMatcherAndCancellationCodeProactivity,
      claimWithThreeProactivitesCancellationCodeAndAirportMatcher
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
      'Selector did not select a single proactivity from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityRegularMatcher[0].Id,
      'Selector did not select a single proactivity from case ID correctly (wrong proactivity)'
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
      'Selector did not select two proactivities from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      2,
      correctlyMatched,
      'Selector did not select two proactivities from case ID correctly (wrong proactivity)'
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
      'Selector did not select a single proactivity with an airport matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityAirportMatcher[0].Id,
      'Selector did not select a single proactivity with an airport matcher from case ID correctly (wrong proactivity)'
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
      'Selector did not select a single proactivity with a cancellation code matcher from case ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctProactivity.Id,
      oneProactivityCancellationCodeMatcher[0].Id,
      'Selector did not select a single proactivity with a cancellation code matcher from case ID correctly (wrong proactivity)'
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
      'Selector did not select three proactivities with a cancellation code and airport matcher from case ID correctly (too many/few matches)'
    );
  }
}
