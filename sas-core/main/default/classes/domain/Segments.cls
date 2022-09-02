public without sharing class Segments extends fflib_SObjectDomain {
  public Segments(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Segment__c>) Records;
  }

  public List<Segment__c> instanceRecords;
  private FlightIrregularities flightIrregularities;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Segments(records);
    }
  }

  public static Segments newInstance(List<Segment__c> sObjectList) {
    return (Segments) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public class SegmentException extends Exception {
  }

  public List<Segment__c> getSortedInstanceRecords() {
    List<SegmentWrapper> segmentsToSort = new List<SegmentWrapper>{};
    for (Segment__c s : instanceRecords) {
      segmentsToSort.add(new SegmentWrapper(s));
    }

    segmentsToSort.sort();

    List<Segment__c> sortedSegments = new List<Segment__c>{};
    for (SegmentWrapper sw : segmentsToSort) {
      sortedSegments.add(sw.segment);
    }

    return sortedSegments;
  }

  /**
   * Helper class to sort segments
   * TODO: Think about how to handle infants.
   * They might cause issues with the "segment.Seat__c != otherSegment.segment.Seat__c"
   */
  private class SegmentWrapper implements Comparable {
    public Segment__c segment;

    public SegmentWrapper(Segment__c segment) {
      this.segment = segment;
    }

    public Integer compareTo(Object compareTo) {
      SegmentWrapper otherSegment = (SegmentWrapper) compareTo;
      if (segment.flight__r == null || segment.Seat__c == null) {
        throw new SegmentException(
          'The segment should contain a flight and a seat.'
        );
      }
      if (
        segment.flight__r.Scheduled_Departure_Time__c >
        otherSegment.segment.flight__r.Scheduled_Departure_Time__c
      ) {
        return 1;
      } else if (
        segment.flight__r.Scheduled_Departure_Time__c <
        otherSegment.segment.flight__r.Scheduled_Departure_Time__c
      ) {
        return -1;
      } else {
        /*if (segment.Seat__c != otherSegment.segment.Seat__c) {
          return 0;
        }*/
        return 0;
        /*throw new SegmentException(
          'The scheduled departure time for the segments and their seats are the same.'
        );*/
      }
    }
  }
}
