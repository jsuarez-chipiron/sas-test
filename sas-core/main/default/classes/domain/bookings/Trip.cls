public without sharing class Trip {
  public Airport originAirport;
  public Airport destinationAirport;
  public List<Leg> sortedLegs;
  public Boolean SASIsOnlyOperatingCarrier;

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
  public static List<Trip> createFromBooking(Booking b) {
    checkData(b);
    return createFromSegments(b.segments);
  }

  public static List<Trip> createFromBookingAtTime(
    Booking b,
    Datetime theTime
  ) {
    checkData(b);
    return createFromSegmentsAtTime(b.segments, theTime);
  }

  private static void checkData(Booking b) {
    if (b.segments == null) {
      throw new InsufficientDataException(
        'You must fetch the segments for the booking.'
      );
    }

    for (Segment s : b.segments) {
      if (s.flight == null) {
        throw new InsufficientDataException(
          'You must fetch flights for the segments in the booking.'
        );
      }
      if (
        s.flight.departureAirportObject == null ||
        s.flight.arrivalAirportObject == null
      ) {
        throw new InsufficientDataException(
          'You must fetch airports for the segments in the booking.'
        );
      }
    }
  }

  public static List<Trip> createFromSegments(List<Segment> segments) {
    List<Segment> activeSegments = SegmentService.getActiveSegments(segments);
    return divideActiveSegmentsIntoTrips(activeSegments);
  }

  public static List<Trip> createFromSegmentsAtTime(
    List<Segment> segments,
    Datetime theTime
  ) {
    List<Segment> activeSegments = SegmentService.getActiveSegments(
      segments,
      theTime
    );
    return divideActiveSegmentsIntoTrips(activeSegments);
  }

  public class InsufficientDataException extends Exception {
  }

  public class TripException extends Exception {
  }

  public class BookingTypeNotSupportedException extends Exception {
  }

  public class NoRouteException extends Exception {
  }

  private Trip(List<Leg> legsInOrder) {
    // make some checks about the booking to make it clear what all we need.
    // should have all data by now, just populate the properties.
    if (legsInOrder.size() == 0) {
      throw new InsufficientDataException('A trip must have at least one leg');
    }

    this.sortedLegs = legsInOrder;
    this.SASIsOnlyOperatingCarrier = true;

    List<Flight> fs = new List<Flight>();
    for (Leg l : legsInOrder) {
      fs.add(l.flight);
    }

    for (Flight f : fs) {
      if (!f.isOperatedBySAS()) {
        SASIsOnlyOperatingCarrier = false;
        break;
      }
    }
  }

  // GENERAL LOGIC
  public Boolean containsFlight(Flight flight) {
    for (Leg l : this.sortedLegs) {
      if (l.flight.tedsIdentifier == flight.tedsIdentifier) {
        return true;
      }
    }
    return false;
  }

  public Flight getFlightToFinalDestination() {
    return sortedLegs[sortedLegs.size() - 1].flight;
  }

  public Flight getFirstFlight() {
    return sortedLegs[0].flight;
  }

  public Boolean isIntraCommunity() {
    return originAirport.isEU261Applicable &&
      destinationAirport.isEU261Applicable;
  }

  public void logJSON(String additionalInfo) {
    System.debug(
      '--------- TRIP-DEBUG (' +
      additionalInfo +
      ') START ---------\n' +
      JSON.serialize(this) +
      '\n---------- TRIP-DEBUG (' +
      additionalInfo +
      ') END ----------\n'
    );
  }

  public Boolean equals(Object other) {
    Trip otherT = (Trip) other;

    if (this.sortedLegs.size() != otherT.sortedLegs.size()) {
      return false;
    }

    for (Integer i = 0; i < this.sortedLegs.size(); i++) {
      if (
        this.sortedLegs[i].flight.tedsIdentifier !=
        otherT.sortedLegs[i].flight.tedsIdentifier
      ) {
        return false;
      }
    }

    return true;
  }

  // DELAY LOGIC
  public Datetime getFinalDestinationArrivalTime() {
    Flight lastFlight = getFlightToFinalDestination();
    return lastFlight.scheduledArrivalTime;
  }

  public Boolean isDelayedToDestination() {
    return getFlightToFinalDestination().arrivalDelayedMinutes > 0;
  }

  // INITIALIZATION LOGIC
  /*
   * Class used to combine different passengers' segments into one.
   */
  public class Leg {
    transient List<Segment> segments;
    Flight flight;

    public Leg(List<Segment> segments) {
      this.segments = segments;
      this.flight = segments[0].flight;
    }
  }

  /*
   * Function used to combine different passengers' segments into one.
   * E.g.
   * Jonas ARN->CPH 2022-01-01 00:00 Oneway
   * Fanny ARN->CPH 2022-01-01 00:00 Oneway
   * Becomes:
   * ARN->CPH 2022-01-01 00:00 Oneway
   *
   * This is done to simplify cancellation compensation handling.
   */
  public static List<Leg> createLegsFromSegments(List<Segment> segments) {
    segments.sort();
    String departureAirport = segments[0].flight.departureAirport;
    String arrivalAirport = segments[0].flight.arrivalAirport;
    Datetime departureTime = segments[0].flight.scheduledDepartureTime;
    Datetime arrivalTime = segments[0].flight.scheduledArrivalTime;

    List<Leg> toReturn = new List<Leg>{};
    List<Segment> segmentsInCurrentLeg = new List<Segment>{};
    Boolean isNewLeg = true;
    for (Segment s : segments) {
      if (
        s.flight.departureAirport == departureAirport &&
        s.flight.arrivalAirport == arrivalAirport &&
        s.flight.scheduledDepartureTime == departureTime &&
        s.flight.scheduledArrivalTime == arrivalTime
      ) {
        segmentsInCurrentLeg.add(s);
      } else {
        toReturn.add(new Leg(segmentsInCurrentLeg));

        segmentsInCurrentLeg = new List<Segment>{ s }; // Clear current leg
        departureAirport = s.flight.departureAirport;
        arrivalAirport = s.flight.arrivalAirport;
        departureTime = s.flight.scheduledDepartureTime;
        arrivalTime = s.flight.scheduledArrivalTime;
      }
    }
    if (segmentsInCurrentLeg.size() > 0) {
      toReturn.add(new Leg(segmentsInCurrentLeg));
    }

    return toReturn;
  }

  /*
   * Divides all segments into trips. A trip is identified by
   * the scheduled arrival and departure of two segments being more than 24 hours apart.
   *
   * @param segments A List<Segment> that needs the connected Flight__r.
   *
   * @return a List<Trip> of the trips sorted in order.
   */
  private static List<Trip> divideActiveSegmentsIntoTrips(
    List<Segment> activeSegments
  ) {
    List<Leg> sortedLegs = createLegsFromSegments(activeSegments);

    List<Trip> tripsToReturn = new List<Trip>{};
    Leg latestLeg;
    List<Leg> legsInCurrentTrip = new List<Leg>();
    for (Leg leg : sortedLegs) {
      if (latestLeg == null) {
        latestLeg = leg;
        legsInCurrentTrip.add(leg);
        continue;
      }

      Boolean moreThan24HoursAtAirport = DateUtils.isMoreThan24HoursBetween(
        latestLeg.flight.scheduledDepartureTime,
        leg.flight.scheduledArrivalTime
      );

      if (moreThan24HoursAtAirport) {
        tripsToReturn.add(new Trip(legsInCurrentTrip));
        legsInCurrentTrip = new List<Leg>();
      }

      latestLeg = leg;
      legsInCurrentTrip.add(leg);
    }

    tripsToReturn.add(new Trip(legsInCurrentTrip));

    for (Trip t : tripsToReturn) {
      Flight firstFlight = t.sortedLegs[0].flight;
      Flight finalFlight = t.getFlightToFinalDestination();

      t.originAirport = firstFlight.departureAirportObject;
      t.destinationAirport = finalFlight.arrivalAirportObject;
    }

    if (
      tripsToReturn.size() == 1 &&
      tripsToReturn[0].originAirport == tripsToReturn[0].destinationAirport
    ) {
      throw new BookingTypeNotSupportedException(
        'Booking type not yet supported (Dayreturn)'
      );
    }

    return tripsToReturn;
  }
}
