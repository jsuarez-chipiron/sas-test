public without sharing class Trip {
  public Airport__c originAirport;
  public Airport__c destinationAirport;
  public List<Segment__c> sortedSegments; // TODO: public Segments segments; instead?
  private Set<Type> segmentTypes = new Set<Type>{}; // These are trip types, not segment types. TODO: What to do?
  public Boolean hasOnlySASFlights;
  public Type tripType;

  public enum Type {
    Cancelled,
    Inbound,
    Outbound,
    Unknown
  }

  public static Map<String, Type> nameToType = new Map<String, Type>{
    'Cancelled' => Type.Cancelled,
    'Inbound' => Type.Inbound,
    'Outbound' => Type.Outbound,
    'Unknown' => Type.Unknown
  };

  /**
   * Returns an ordered list of all trips in a booking.
   *
   *
   * Divides the flights in the booking into different trips. If there is an issue, the booking's trip(s) get set to null.
   * If the booking is a OneWay there should only be one trip.
   * If the booking is a Roundtrip or Dayreturn there should be two trips.
   * If the booking is a MultiCity there can be 1(?) or more trips.
   *
   * The compensation should, logically, be calculated with respect to each "final destination" in the booking (see EU261 Article 2 h: https://eur-lex.europa.eu/legal-content/EN/TXT/?qid=1476179175834&uri=CELEX:32004R0261)
   * When a pax stays in a city for more than 24 hours it counts as a "final destination" according to internal SAS policy (TODO: find a good source).
   * After 24 hours the booking is considered a "package" under EU law (Council Directive 90/314/EEC Article 2 §1: https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=celex%3A31990L0314)
   *
   * TODO: Find a solid source for the 24 hour policy.
   * TODO: Think about implementation: When there is a cancelled flight and a customers trip becomes e.g.
   * ARN -> CPH (Delay 200 minutes + Wait >24hrs because of cancellation) -> LAX (Delay 260 minutes).
   * The customer could, according to this implementation, claim compensation for both ARN -> CPH and CPH -> LAX.
   * This seems fair. However, I think there is a good case for us not needing to provide them with more compensation.
   *
   * @return A map of booking id to each trip in booking
   */
  public static List<Trip> createFromBooking(Booking__c b) {
    Map<Id, List<Trip>> bookingIdToTrips = new Map<Id, List<Trip>>{};

    // Sort the Segments
    if (b.Segments__r == null) {
      throw new InsufficientDataException(
        'You must fetch the Segments__r for the booking.'
      );
    }

    return divideBookingSegmentsIntoTrips(b);
  }

  public class InsufficientDataException extends Exception {
  }

  public class InvalidTripException extends Exception {
  }

  private Trip(List<Segment__c> segmentsInOrder) {
    // make some checks about the booking to make it clear what all we need.
    // should have all data by now, just populate the properties.
    this.sortedSegments = segmentsInOrder;
    this.hasOnlySASFlights = true;
    this.tripType = nameToType.get(segmentsInOrder[0].Trip_Type__c);

    List<Flight__c> fs = new List<Flight__c>();

    for (Segment__c s : segmentsInOrder) {
      fs.add(s.Flight__r);
      segmentTypes.add(nameToType.get(s.Trip_Type__c));
    }

    for (
      Boolean operatedBySAS : Flights.newInstance(fs).operatedBySAS().values()
    ) {
      if (!operatedBySAS) {
        hasOnlySASFlights = false;
      }
    }
  }

  public Boolean containsFlight(String flightNumberDate) {
    for (Segment__c s : this.sortedSegments) {
      List<String> parts = s.Flight__r.TEDS_Identifier__c.split('-');
      if (parts.size() < 2) {
        return false;
      }
      String segmentFlightId = parts[0] + '-' + parts[1];
      if (segmentFlightId == flightNumberDate) {
        return true;
      }
    }
    return false;
  }

  public Datetime getFinalDestinationArrivalTime() {
    Flight__c lastFlight = getFlightToFinalDestination();

    if (lastFlight.Actual_Arrival_Time__c != null) {
      return lastFlight.Actual_Arrival_Time__c;
    }
    return lastFlight.Scheduled_Arrival_Time__c;
  }

  public Flight__c getFlightToFinalDestination() {
    Flight__c lastFlight = sortedSegments[sortedSegments.size() - 1].Flight__r;
    if (lastFlight == null) {
      throw new InvalidTripException(
        'Segment in trip does not contain all necessary information.'
      );
    }
    return lastFlight;
  }

  public Boolean hasCancelledOrUnknownSegments() {
    return hasCancelledSegments() || hasUnknownSegments();
  }

  public Boolean hasCancelledSegments() {
    return segmentTypes.contains(Type.Cancelled);
  }

  public Boolean hasUnknownSegments() {
    return segmentTypes.contains(Type.Unknown);
  }

  public Boolean isDelayedToDestination() {
    return getFlightToFinalDestination().Arrival_Delayed_Minutes__c > 0;
  }

  private void setAirports() {
    Flight__c firstFlight = sortedSegments[0].Flight__r;
    Flight__c finalFlight = getFlightToFinalDestination();

    String originAirportCode = firstFlight.Departure_Airport__c;
    String destinationAirportCode = firstFlight.Arrival_Airport__c;

    List<Airport__c> aps = AirportsSelector.newInstance()
      .selectByIATACode(
        new Set<String>{ originAirportCode, destinationAirportCode }
      );

    // TODO: Need to fetch airports separately
    for (Airport__c a : aps) {
      if (a.TEDS_Identifier__c == originAirportCode) {
        this.originAirport = a;
      } else if (a.TEDS_Identifier__c == destinationAirportCode) {
        this.destinationAirport = a;
      }
    }
  }

  /*
   * Divides all segments in a booking into trips. A trip is identified by either being outbound or inbound or
   * by the scheduled arrival and departure of two segments being more than 24 hours apart.
   *
   * @param booking A Booking__c that needs the connected Segments__r and their Flight__r.
   *
   * @return a List<Trip> of the trips sorted in reverse order.
   */
  private static List<Trip> divideBookingSegmentsIntoTrips(Booking__c booking) {
    List<Trip> tripsToReturn = new List<Trip>{};
    List<Segment__c> sortedSegments = Segments.newInstance(booking.Segments__r)
      .getSortedInstanceRecords();

    Segment__c latestSegment;
    List<Segment__c> segmentsInCurrentTrip = new List<Segment__c>{};
    Boolean hasInBoundTrip = false;
    /*
     * Go through the segments backwards.
     * Looping through forwards makes it very difficult to distinguish between whether a cancelled flight is outbound or inbound.
     */
    for (Integer i = sortedSegments.size() - 1; i >= 0; i--) {
      Segment__c s = sortedSegments[i];
      Type segmentsTripType = nameToType.get(s.Trip_Type__c);
      if (segmentsTripType == null) {
        segmentsTripType = Type.Unknown;
      }
      /*
       * Check if the segment is the last segment in the booking, cancelled or unknown => add it to the trip.
       *
       * This is logical in most cases. The most common case this does not work for is if the flight to the
       * final destination was cancelled (and there is a return flight home) and the replacement flight
       * departs before the original one.
       *
       * TODO: Handle Cancellations and Unknowns better.
       */
      if (
        latestSegment == null ||
        segmentsTripType == Type.Cancelled ||
        segmentsTripType == Type.Unknown
      ) {
        latestSegment = s;
        segmentsInCurrentTrip.add(s);
        continue;
      }

      if (s.Flight__r == null) {
        throw new InsufficientDataException(
          'You must fetch the Flight__r for the Segments__r for the booking.'
        );
      }

      // We can only have one outbound and one inbound trip (Except for MultiCity bookings)
      Boolean switchedToOutbound = (s.Trip_Type__c !=
      latestSegment.Trip_Type__c &&
      segmentsTripType == Trip.Type.Outbound &&
      !hasInBoundTrip);

      Boolean moreThan24HoursAtAirport = DateUtils.isMoreThan24HoursBetween(
        latestSegment.Flight__r.Scheduled_Departure_Time__c,
        s.Flight__r.Scheduled_Arrival_Time__c
      );

      /**
       * Switched to inbound does not work for MultiCity bookings.
       * However, it is a MultiCity booking, it is relatively unlikely you will stay less than
       * 24 hours at a destination airport. This is most likely to happen to DayReturn bookings.
       */
      Boolean segmentReachedAFinalDestination =
        moreThan24HoursAtAirport ||
        (switchedToOutbound &&
        Bookings.nameToBookingType.get(booking.Type__c) !=
        Bookings.Type.MultiCity);

      if (segmentReachedAFinalDestination) {
        tripsToReturn.add(
          new Trip(
            new Segments(segmentsInCurrentTrip).getSortedInstanceRecords()
          )
        );
        segmentsInCurrentTrip = new List<Segment__c>{};
        hasInBoundTrip = true;
      } else {
        // If not, continue looping through the segments
        latestSegment = s;
      }
      segmentsInCurrentTrip.add(s);
    }

    tripsToReturn.add(
      new Trip((new Segments(segmentsInCurrentTrip)).getSortedInstanceRecords())
    );

    // No, refactor, DB-call -> see eu261-service 773
    for (Trip t : tripsToReturn) {
      t.setAirports();
    }

    return tripsToReturn;
  }
}
