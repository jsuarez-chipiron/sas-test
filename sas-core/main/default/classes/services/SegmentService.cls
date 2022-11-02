/**
 * Service class for managing Segments in Salesforce.
 */
public without sharing class SegmentService {
  public static SegmentService newInstance() {
    return (SegmentService) SAS_Service_Application.Service.newInstance(
      SegmentService.class
    );
  }

  public class InsufficientDataException extends Exception {
  }

  public class InvalidSegmentException extends Exception {
  }

  // Get the active segments at a specific time
  public static List<Segment> getActiveSegments(
    List<Segment> segments,
    Datetime theTime
  ) {
    List<Segment> toReturn = new List<Segment>{};

    for (Segment s : segments) {
      if (s.events == null) {
        throw new InsufficientDataException(
          'You must fetch the segment events'
        );
      }

      if (s.isActive(theTime)) {
        toReturn.add(s);
      }
    }

    return toReturn;
  }

  // Get the active segments after all events
  public static List<Segment> getActiveSegments(List<Segment> segments) {
    List<Segment> toReturn = new List<Segment>{};

    for (Segment s : segments) {
      if (s.events == null) {
        throw new InsufficientDataException(
          'You must fetch the segment events'
        );
      }

      if (s.isActive()) {
        toReturn.add(s);
      }
    }

    return toReturn;
  }
}
