public without sharing class Bookings extends fflib_SObjectDomain {
  public Bookings(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Booking__c>) Records;
  }

  private List<Booking__c> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Bookings(records);
    }
  }

  public static Bookings newInstance(List<Booking__c> sObjectList) {
    return (Bookings) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  /**
   * Whether the bookings have a non Star Alliance operating carrier for at
   * least one leg in the booking.
   *
   * @return A map from booking id to whether that booking has non Star
   * Alliance operating carriers as a part of the journey.
   */
  public Map<Id, Boolean> haveNonStarAllianceOperatingCarriers() {
    Set<Id> bookingIds = (new Map<Id, Booking__c>(instanceRecords)).keySet();

    Map<Id, Boolean> flightIdToOperatedByStarAlliance = Flights.newInstance(
        FlightsSelector.newInstance().selectByBookingIds(bookingIds)
      )
      .operatedByStarAlliance();

    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Booking__c booking : instanceRecords) {
      Boolean hasNonStarAllianceOperators = false;
      for (Segment__c segment : booking.Segments__r) {
        Boolean flightOperatedByStarAlliance = flightIdToOperatedByStarAlliance.get(
          segment.Flight__c
        );
        if (!flightOperatedByStarAlliance) {
          hasNonStarAllianceOperators = true;
          break;
        }
      }
      toReturn.put(booking.Id, hasNonStarAllianceOperators);
    }

    return toReturn;
  }
}
