public without sharing class Flights extends fflib_SObjectDomain {
  public Flights(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Flight__c>) Records;
  }

  private List<Flight__c> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Flights(records);
    }
  }

  public static Flights newInstance(List<Flight__c> sObjectList) {
    return (Flights) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public static final Set<String> STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS = new Set<String>{
    'A3',
    'AC',
    'AI',
    'AV',
    'BR',
    'CA',
    'CM',
    'ET',
    'LH',
    'LO',
    'LX',
    'MS',
    'NH',
    'NZ',
    'OS',
    'OU',
    'OZ',
    'SA',
    'SK',
    'SN',
    'SQ',
    'TG',
    'TK',
    'TP',
    'UA',
    'ZH'
  };

  /**
   * Whether the flights are operated by carriers which are not a part of Star
   * Alliance.
   *
   * @return A map from flight id to whether that flight is operated by carrier
   * which belongs to Star Alliance.
   */
  public Map<Id, Boolean> operatedByStarAlliance() {
    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Flight__c flight : instanceRecords) {
      toReturn.put(
        flight.Id,
        STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS.contains(
          flight.Operating_Carrier__c
        )
      );
    }
    return toReturn;
  }
}
