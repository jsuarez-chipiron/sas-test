public without sharing class Segments extends ApplicationDomain {
  public Segments(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Segment__c>) Records;
  }

  public List<Segment__c> instanceRecords;
  public Map<String, List<Segment__c>> flightIdToSegments;
  @TestVisible
  private SegmentEvents segmentEvents;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Segments(records);
    }
  }

  public static Segments newInstance(List<Segment__c> sObjectList) {
    return (Segments) SAS_Service_Application.Domain.newInstance(sObjectList);
  }
  /**
   * Creates Segments for each passenger from a list of parsed EDW data.
   * The parsed data contains data for every update to each segment and we create
   * a segment based on the latest update
   */
  public static Segments createFromEDWData(
    List<FetchEDWBookingResponse.Segment> sourceData,
    List<Passenger__c> passengersInBooking
  ) {
    List<Segment__c> allCreatedSegments = new List<Segment__c>();
    Map<String, List<Segment__c>> flightIdToSegments = new Map<String, List<Segment__c>>();
    List<FetchEDWBookingResponse.Segment> segmentEventsToCreate = new List<FetchEDWBookingResponse.Segment>();

    for (FetchEDWBookingResponse.Segment segment : sourceData) {
      if (segment.isLatest == 1 || segment.segStatus == 'SCHED') {
        String segmentFlightId = String.format(
          '{0}{1}-{2}-{3}-{4}',
          new List<Object>{
            segment.fltAirlCd,
            segment.fltNm,
            Datetime.newInstance(segment.depDte).format('yyyyMMdd'),
            segment.stnFrCd,
            segment.stnToCd
          }
        );
        if (flightIdToSegments.get(segmentFlightId) == null) {
          flightIdToSegments.put(segmentFlightId, new List<Segment__c>());
        }
        for (Passenger__c passenger : passengersInBooking) {
          Segment s = new Segment(new Segment__c(Name = segmentFlightId));
          s.identifier = String.format(
            'ST{0}{1}',
            new List<Object>{ segment.segTattoo, passenger.Identifier__c }
          );
          s.bookingClass = segment.oprBkgCl;
          s.segmentStatusCode = segment.segStatus;
          s.serviceClass = segment.oprSvcCl;
          s.updateSObjectFields();
          flightIdToSegments.get(segmentFlightId).add(s.underlyingSObject);
          allCreatedSegments.add(s.underlyingSObject);
        }
      }
      if (segment.recordOprType != null) {
        segmentEventsToCreate.add(segment);
      }
    }
    Segments newSegments = Segments.newInstance(allCreatedSegments);
    newSegments.flightIdToSegments = flightIdToSegments;
    newSegments.segmentEvents = SegmentEvents.createFromEDWData(
      segmentEventsToCreate,
      passengersInBooking
    );
    return newSegments;
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
