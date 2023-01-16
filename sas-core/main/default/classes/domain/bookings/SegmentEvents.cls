public without sharing class SegmentEvents extends ApplicationDomain {
  public SegmentEvents(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Segment_Event__c>) Records;
  }

  public List<Segment_Event__c> instanceRecords;
  //public Map<String, List<Segment_Event__c>> segmentIdToEvents = new Map<String, List<Segment_Event__c>>();
  public Map<String, Map<String, List<Segment_Event__c>>> segmentIdToEventsPerPassenger = new Map<String, Map<String, List<Segment_Event__c>>>();

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new SegmentEvents(records);
    }
  }

  public static SegmentEvents newInstance(List<Segment_Event__c> sObjectList) {
    return (SegmentEvents) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  /**
   * Creates lookup relationships for all Segment Events per passenger
   * @param segments List of all segments in the booking
   * @param passengersInBooking List of all passengers in the booking
   */
  public SegmentEvents addSegmentReferences(
    List<Segment__c> segments,
    List<Passenger__c> passengersInBooking
  ) {
    for (Passenger__c passenger : passengersInBooking) {
      for (Segment__c segment : segments) {
        List<Segment_Event__c> segmentEvents = segmentIdToEventsPerPassenger.get(
            passenger.Identifier__c
          )
          ?.get(segment.Name);
        if (segmentEvents != null) {
          for (Segment_Event__c segmentEvent : segmentEvents) {
            if (segment.Identifier__c.contains(passenger.Identifier__c)) {
              segmentEvent.Segment__c = segment.Id;
            }
          }
        }
      }
    }
    return this;
  }
}
