@IsTest
public with sharing class TestSegmentFactory {
  public static Segment createFromBookingFlightPassenger(
    Booking b,
    Flight f,
    Passenger p
  ) {
    Segment s = new Segment(new Segment__c());
    s.flight = f;
    s.flightId = f.id;
    s.id = fflib_IDGenerator.generate(Segment__c.getSObjectType());

    s.baggageQuantity = 0;
    s.bookingClass = 'A';
    s.checkInStatus = '';
    s.fareBasis = 'ABCDE';
    s.farePrice = 200;
    s.identifier = 'ST1';
    s.isBoarded = true;
    s.seat = '1A';
    s.segmentStatus = 'Accepted';
    s.segmentStatusCode = 'HK';
    s.serviceClass = 'A';
    s.specialServiceRequests = '';
    s.ticketNumber = '1234567890';
    s.ticketType = '';

    s.tripType = 'Outbound';
    if (f.irregularities != null) {
      for (FlightIrregularity fi : f.irregularities) {
        if (fi.isCancellation()) {
          s.tripType = 'Cancelled';
        }
      }
    }

    return s;
  }

  public static List<Segment> createFromBookingFlight(Booking b, Flight f) {
    List<Segment> segments = new List<Segment>{};
    for (Passenger p : b.passengers) {
      segments.add(createFromBookingFlightPassenger(b, f, p));
    }
    return segments;
  }
  public static List<Segment> createFromBookingFlights(
    Booking b,
    List<Flight> fs
  ) {
    List<Segment> segments = new List<Segment>{};
    for (Flight f : fs) {
      for (Passenger p : b.passengers) {
        segments.add(createFromBookingFlightPassenger(b, f, p));
      }
    }
    return segments;
  }
}
