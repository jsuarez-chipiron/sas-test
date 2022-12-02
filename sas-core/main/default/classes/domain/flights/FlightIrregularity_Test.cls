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

    System.assert(!isWithinSASControl, 'An irregularity which is normally within SAS control with Eligible_For_EU261__c = "NO" should not be in SAS control.');
  }
}
