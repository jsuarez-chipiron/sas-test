@IsTest
public with sharing class FlightIrregularity_Test {
  @IsTest
  public static void WEATwithEUYesShouldBeEligible() {
    FlightIrregularities__c EUYesWEAT = new FlightIrregularities__c(
      Code__c = 'WEAT',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'Yes'
    );

    Boolean isWithinSASControl = new FlightIrregularity(EUYesWEAT)
      .isWithinSASControl();

    System.assert(
      isWithinSASControl,
      'An irregularity which is not normally within SAS control with Eligible_For_EU261__c = "YES" should be in SAS control.'
    );
  }
  @IsTest
  public static void WEATwithEUTentativeShouldNotBeEligible() {
    FlightIrregularities__c EUTentativeWEAT = new FlightIrregularities__c(
      Code__c = 'WEAT',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'Tentative'
    );

    Boolean isWithinSASControl = new FlightIrregularity(EUTentativeWEAT)
      .isWithinSASControl();

    System.assert(
      !isWithinSASControl,
      'An irregularity which is not normally within SAS control with Eligible_For_EU261__c = "Tentativ" should not be in SAS control.'
    );
  }

  @IsTest
  public static void TECHwithEUNoShouldNotBeEligible() {
    FlightIrregularities__c EUNoTECH = new FlightIrregularities__c(
      Code__c = 'TECH',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'No'
    );

    Boolean isWithinSASControl = new FlightIrregularity(EUNoTECH)
      .isWithinSASControl();

    System.assert(
      !isWithinSASControl,
      'An irregularity which is normally within SAS control with Eligible_For_EU261__c = "NO" should not be in SAS control.'
    );
  }

  @isTest
  public static void evaluateCREWResponsibility() {
    Flight__c f = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0003-20220818',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );

    insert f;

    FlightIrregularities__c CREWfromHub = new FlightIrregularities__c(
      Flight__c = f.Id,
      Code__c = 'CREW',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'Tentative'
    );

    insert CREWfromHub;

    FlightIrregularities irr = new FlightIrregularities(
      new List<FlightIrregularities__c>{ CREWfromHub }
    );
    irr.setEU261EligibilityForCREWIrregularities();

    Boolean isWithinSASControl = new FlightIrregularity(CREWfromHub)
      .isWithinSASControl();

    System.assert(
      isWithinSASControl,
      'A CREW irregularity from a hub should be within sas control'
    );
  }
}
