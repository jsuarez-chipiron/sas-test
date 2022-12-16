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

  public static SegmentEvents createFromEDWData(
    List<FetchEDWBookingResponse.Segment> segments,
    List<Passenger__c> passengersInBooking
  ) {
    List<Segment_Event__c> processedEvents = new List<Segment_Event__c>();
    Map<String, Map<String, List<Segment_Event__c>>> segmentIdToEventsPerPassenger = new Map<String, Map<String, List<Segment_Event__c>>>();
    for (FetchEDWBookingResponse.Segment segment : segments) {
      String segmentFlightId = String.format(
        '{0}{1}-{2}-{3}-{4}',
        new List<Object>{
          segment.fltAirlCd.trim(),
          segment.fltNm,
          Datetime.newInstance(segment.depDte).format('yyyyMMdd'),
          segment.stnFrCd,
          segment.stnToCd
        }
      );
      for (Passenger__c passenger : passengersInBooking) {
        if (
          segmentIdToEventsPerPassenger.get(passenger.Identifier__c) == null
        ) {
          segmentIdToEventsPerPassenger.put(
            passenger.Identifier__c,
            new Map<String, List<Segment_Event__c>>()
          );
        }
        SegmentEvent se = new SegmentEvent(new Segment_Event__c());
        se.operationType = SegmentEvent.getOperationTypeFromPicklistValue(
          segment.recordOprType.replace('D', '').trim()
        );
        se.newStatus = SegmentEvent.getStatusCodeFromPicklistValue(
          segment.actionCd?.trim()
        );
        se.previousStatus = SegmentEvent.getStatusCodeFromPicklistValue(
          segment.prevActionCd?.trim()
        );
        se.officeCode = segment.officeUpdating;
        se.updateDate = segment.resUpdTms == null
          ? null
          : Datetime.newInstance(segment.resUpdTms);
        se.updateNumber = segment.resUpdateNo;
        se.updateSObjectFields();
        processedEvents.add(se.underlyingSObject);
        if (
          segmentIdToEventsPerPassenger.get(passenger.Identifier__c)
            .get(segmentFlightId) == null
        ) {
          segmentIdToEventsPerPassenger.get(passenger.Identifier__c)
            .put(segmentFlightId, new List<Segment_Event__c>());
        }
        segmentIdToEventsPerPassenger.get(passenger.Identifier__c)
          .get(segmentFlightId)
          .add(se.underlyingSObject);
      }
    }
    SegmentEvents newSegmentEvents = SegmentEvents.newInstance(processedEvents);
    newSegmentEvents.segmentIdToEventsPerPassenger = segmentIdToEventsPerPassenger;
    return newSegmentEvents;
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
