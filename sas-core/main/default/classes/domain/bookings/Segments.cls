public without sharing class Segments extends ApplicationDomain {
  public Segments(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Segment__c>) Records;
  }

  public List<Segment__c> instanceRecords;
  public Map<String, List<Segment__c>> flightIdToSegments;
  public SegmentEvents segmentEvents;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Segments(records);
    }
  }

  public static Segments newInstance(List<Segment__c> sObjectList) {
    return (Segments) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public Segments addBookingReference(Id bookingId) {
    for (Segment__c s : instanceRecords) {
      s.Booking__c = bookingId;
    }
    return this;
  }

  public Segments addFlightReferences(List<Flight__c> flights) {
    for (Flight__c flight : flights) {
      List<Segment__c> segmentsForFlight = flightIdToSegments.get(
        flight.TEDS_Identifier__c
      );
      if (segmentsForFlight != null && segmentsForFlight.size() > 0) {
        for (Segment__c segment : segmentsForFlight) {
          segment.Flight__c = flight.Id;
        }
      }
    }
    return this;
  }
  public Segments upsertToDB(List<Passenger__c> passengersInBooking) {
    upsert this.instanceRecords;
    segmentEvents.addSegmentReferences(instanceRecords, passengersInBooking);
    upsert segmentEvents.instanceRecords;
    return this;
  }
}
