public without sharing class Trip {
  public Airport__c originAirport;
  public Airport__c destinationAirport;
  public List<Leg> sortedLegs;
  public Boolean SASIsOnlyOperatingCarrier;
  public FlightHistory flightHistory;

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
  public static List<Trip> createFromBooking(
    Booking__c b,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    Map<Id, List<Trip>> bookingIdToTrips = new Map<Id, List<Trip>>{};

    // Sort the Segments
    if (b.Segments__r == null) {
      throw new InsufficientDataException(
        'You must fetch the Segments__r for the booking.'
      );
    }

    return divideBookingSegmentsIntoTrips(b, airportCodeToAirport);
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

    List<Flight__c> fs = new List<Flight__c>();
    for (Leg l : legsInOrder) {
      fs.add(l.flight);
    }

    for (
      Boolean operatedBySAS : Flights.newInstance(fs).operatedBySAS().values()
    ) {
      if (!operatedBySAS) {
        SASIsOnlyOperatingCarrier = false;
      }
    }

    this.flightHistory = new FlightHistory(this.sortedLegs);
  }

  // GENERAL LOGIC
  public Flight__c getFlight(String flightNumberDate) {
    for (Leg l : this.sortedLegs) {
      String segmentFlightId = Flights.TEDSIdToSimpleFlightIds(
        l.flight.TEDS_Identifier__c
      )[0];
      if (segmentFlightId == flightNumberDate) {
        return l.flight;
      }
    }
    return null;
  }

  public Flight__c getFlightToFinalDestination() {
    return sortedLegs[sortedLegs.size() - 1].flight;
  }

  public Flight__c getFirstFlight() {
    return sortedLegs[0].flight;
  }

  public Boolean isIntraCommunity() {
    return originAirport.Is_EU261_Applicable__c &&
      destinationAirport.Is_EU261_Applicable__c;
  }

  public String getJSON() {
    return JSON.serialize(this);
  }

  public void logJSON(String additionalInfo) {
    System.debug(
      '--------- TRIP-DEBUG (' +
      additionalInfo +
      ') START ---------\n' +
      this.getJSON() +
      '\n---------- TRIP-DEBUG (' +
      additionalInfo +
      ') END ----------\n'
    );
  }

  // DELAY LOGIC
  public Datetime getFinalDestinationArrivalTime() {
    Flight__c lastFlight = getFlightToFinalDestination();
    return lastFlight.Scheduled_Arrival_Time__c;
  }

  public Boolean isDelayedToDestination() {
    return getFlightToFinalDestination().Arrival_Delayed_Minutes__c > 0;
  }

  // CANCELLATION LOGIC
  public Boolean hasCancelledSegments() {
    Integer noCancelledFlights = 0;
    for (Leg l : sortedLegs) {
      for (Segment__c s : l.segments) {
        if (Trip.nameToType.get(s.Trip_Type__c) == Type.Cancelled) {
          return true;
        }
      }
    }
    return false;
  }

  public Integer getNoCancelledFlights(
    Map<Id, List<FlightIrregularities__c>> flightToIrregularities
  ) {
    Integer noCancelledFlights = 0;
    for (Leg l : sortedLegs) {
      FlightIrregularities fi = new FlightIrregularities(
        flightToIrregularities.get(l.flight.Id)
      );
      if (fi.containsCancellation()) {
        noCancelledFlights += 1;
      }
    }
    return noCancelledFlights;
  }

  public Boolean canGetOriginalTrip() {
    try {
      this.getOriginalTripWithFlight();
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  public Boolean canGetSuggestedRebookingTrip() {
    try {
      if (this.getSuggestedRebookingWithoutFlight() == null) {
        throw new TripException();
      }
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  // Flight__c cancelledFlight, TODO: Make dependant on cancelledFlight
  public Trip getOriginalTripWithFlight() {
    Trip originalTrip = flightHistory.getOriginalTrip();
    if (
      originalTrip.getFirstFlight().Departure_Airport__c !=
      this.getFirstFlight().Departure_Airport__c ||
      originalTrip.getFirstFlight().Arrival_Airport__c !=
      this.getFirstFlight().Arrival_Airport__c
    ) {
      throw new TripException(
        'The original trip does not have the same origin and destination as the final trip'
      );
    }
    originalTrip.originAirport = this.originAirport;
    originalTrip.destinationAirport = this.destinationAirport;
    return originalTrip;
  }

  // Flight__c cancelledFlight, TODO: Make dependant on cancelledFlight
  public Trip getSuggestedRebookingWithoutFlight() {
    Trip suggestedRebookedTrip;
    try {
      suggestedRebookedTrip = flightHistory.getSuggestedRebooking(); // TODO: Make dependant on cancelledFlight
    } catch (NoRouteException e) {
      return null;
    }

    if (
      suggestedRebookedTrip.getFirstFlight().Departure_Airport__c !=
      this.getFirstFlight().Departure_Airport__c ||
      suggestedRebookedTrip.getFirstFlight().Arrival_Airport__c !=
      this.getFirstFlight().Arrival_Airport__c
    ) {
      throw new TripException(
        'The suggested rebooked trip does not have the same origin and destination as the final trip'
      );
    }
    suggestedRebookedTrip.originAirport = this.originAirport;
    suggestedRebookedTrip.destinationAirport = this.destinationAirport;
    return suggestedRebookedTrip;
  }

  public class Airport {
    String IATACode;
    List<Leg> availableRoutesFromAirport = new List<Leg>{};

    public Airport(String IATACode) {
      this.IATACode = IATACode;
    }
  }

  public class FlightHistory {
    Map<String, Airport> codeToAirport = new Map<String, Airport>{};
    Airport originAirport;
    Airport destinationAirport;

    public FlightHistory(List<Leg> tripLegs) {
      List<String> addedAirports = new List<String>{};
      for (Leg l : tripLegs) {
        if (!addedAirports.contains(l.flight.Departure_Airport__c)) {
          Airport newAirport = new Airport(l.flight.Departure_Airport__c);
          codeToAirport.put(l.flight.Departure_Airport__c, newAirport);
          addedAirports.add(l.flight.Departure_Airport__c);
        }
        if (!addedAirports.contains(l.flight.Arrival_Airport__c)) {
          Airport newAirport = new Airport(l.flight.Arrival_Airport__c);
          codeToAirport.put(l.flight.Arrival_Airport__c, newAirport);
          addedAirports.add(l.flight.Arrival_Airport__c);
        }

        Airport departureAirport = codeToAirport.get(
          l.flight.Departure_Airport__c
        );
        departureAirport.availableRoutesFromAirport.add(l);
      }

      this.originAirport = codeToAirport.get(
        tripLegs[0].flight.Departure_Airport__c
      );
      this.destinationAirport = codeToAirport.get(
        tripLegs[tripLegs.size() - 1].flight.Arrival_Airport__c
      );
    }

    /**
     * Currently assumes only 1 cancellation per Trip.
     * Goes through all legs in the trips and constructs an "original" trip
     * prioritizing cancelled segments over active ones
     */
    public Trip getOriginalTrip() {
      Airport currentAirport = originAirport;
      Airport nextAirport;
      List<Leg> tripLegsInOrder = new List<Leg>{};
      List<Leg> routes = currentAirport.availableRoutesFromAirport;
      Integer noIterations = 0;
      while (routes.size() != 0) {
        Leg currentLeg;
        switch on routes.size() {
          when 1 {
            currentLeg = routes[0];
          }
          when 2 {
            if (routes[0].segmentType == Type.Cancelled) {
              currentLeg = routes[0];
            } else if (routes[1].segmentType == Type.Cancelled) {
              currentLeg = routes[1];
            } else {
              throw new TripException(
                'More than one active leg from one airport to another.'
              );
            }
          }
          when else {
            throw new TripException(
              'Trip type not supported (more than one cancellation)'
            );
          }
        }
        tripLegsInOrder.add(currentLeg);
        nextAirport = this.codeToAirport.get(
          currentLeg.flight.Arrival_Airport__c
        );
        routes = nextAirport.availableRoutesFromAirport;
        currentAirport = nextAirport;
        noIterations += 1;
        if (noIterations == 200) {
          throw new TripException('Likely infinite loop');
        }
      }
      if (currentAirport.IATACode != destinationAirport.IATACode) {
        throw new TripException('Error while calculating original trip.');
      }

      return new Trip(tripLegsInOrder);
    }

    /**
     * Currently assumes only 1 cancellation per Trip.
     * Goes through all legs in the trips and constructs an "original" trip
     * prioritizing active segments over cancelled ones
     */
    public Trip getSuggestedRebooking() {
      Airport currentAirport = originAirport;
      Airport nextAirport;
      List<Leg> tripLegsInOrder = new List<Leg>{};
      List<Leg> routes = currentAirport.availableRoutesFromAirport;
      while (routes.size() != 0) {
        Leg currentLeg;
        switch on routes.size() {
          when 1 {
            if (
              routes[0].segmentType == Type.Cancelled ||
              routes[0].segmentType == Type.Unknown
            ) {
              throw new NoRouteException('No way of flying from this airport.');
            }
            currentLeg = routes[0];
          }
          when 2 {
            if (
              routes[0].segmentType != Type.Cancelled &&
              routes[0].segmentType != Type.Unknown &&
              routes[1].segmentType == Type.Cancelled
            ) {
              currentLeg = routes[0];
            } else if (
              routes[1].segmentType != Type.Unknown &&
              routes[1].segmentType != Type.Cancelled &&
              routes[0].segmentType == Type.Cancelled
            ) {
              currentLeg = routes[1];
            } else {
              throw new TripException(
                'More than one active leg from one airport to another.'
              );
            }
          }
          when else {
            throw new TripException(
              'Trip type not supported (more than one cancellation)'
            );
          }
        }
        tripLegsInOrder.add(currentLeg);
        nextAirport = this.codeToAirport.get(
          currentLeg.flight.Arrival_Airport__c
        );
        currentAirport = nextAirport;
        routes = nextAirport.availableRoutesFromAirport;
      }
      if (currentAirport.IATACode != destinationAirport.IATACode) {
        throw new TripException('Error while calculating original trip.');
      }

      return new Trip(tripLegsInOrder);
    }
  }

  // INITIALIZATION LOGIC
  /*
   * Class used to combine different passengers' segments into one.
   */
  public class Leg {
    transient List<Segment__c> segments;
    Flight__c flight;
    Type segmentType;

    public Leg(List<Segment__c> segments) {
      this.segments = segments;
      this.flight = segments[0].Flight__r;
      this.segmentType = Trip.nameToType.get(segments[0].Trip_Type__c);
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
  public static List<Leg> createFromSegments(List<Segment__c> sortedSegments) {
    String departureAirport = sortedSegments[0].Flight__r.Departure_Airport__c;
    String arrivalAirport = sortedSegments[0].Flight__r.Arrival_Airport__c;
    Datetime departureTime = sortedSegments[0]
      .Flight__r.Scheduled_Departure_Time__c;
    Datetime arrivalTime = sortedSegments[0]
      .Flight__r.Scheduled_Arrival_Time__c;
    Type segmentType = Trip.nameToType.get(sortedSegments[0].Trip_Type__c);

    List<Leg> toReturn = new List<Leg>{};
    List<Segment__c> segmentsInCurrentLeg = new List<Segment__c>{};
    Boolean isNewLeg = true;
    for (Segment__c s : sortedSegments) {
      if (
        s.Flight__r.Departure_Airport__c == departureAirport &&
        s.Flight__r.Arrival_Airport__c == arrivalAirport &&
        s.Flight__r.Scheduled_Departure_Time__c == departureTime &&
        s.Flight__r.Scheduled_Arrival_Time__c == arrivalTime
      ) {
        if (Trip.nameToType.get(s.Trip_Type__c) != segmentType) {
          throw new TripException(
            'Two segments which should be the same are of different types.'
          );
        } else {
          segmentsInCurrentLeg.add(s);
        }
      } else {
        toReturn.add(new Leg(segmentsInCurrentLeg));

        segmentsInCurrentLeg = new List<Segment__c>{ s }; // Clear current leg
        departureAirport = s.Flight__r.Departure_Airport__c;
        arrivalAirport = s.Flight__r.Arrival_Airport__c;
        departureTime = s.Flight__r.Scheduled_Departure_Time__c;
        arrivalTime = s.Flight__r.Scheduled_Arrival_Time__c;
        segmentType = Trip.nameToType.get(s.Trip_Type__c);
      }
    }
    if (segmentsInCurrentLeg.size() > 0) {
      toReturn.add(new Leg(segmentsInCurrentLeg));
    }

    return toReturn;
  }

  /*
   * Divides all segments in a booking into trips. A trip is identified by either being outbound or inbound or
   * by the scheduled arrival and departure of two segments being more than 24 hours apart.
   *
   * @param booking A Booking__c that needs the connected Segments__r and their Flight__r.
   *
   * @return a List<Trip> of the trips sorted in reverse order.
   */
  private static List<Trip> divideBookingSegmentsIntoTrips(
    Booking__c booking,
    Map<String, Airport__c> airportCodeToAirport
  ) {
    List<Segment__c> sortedSegments = Segments.newInstance(booking.Segments__r)
      .getSortedInstanceRecords();
    List<Leg> sortedLegs = Leg.createFromSegments(sortedSegments);

    // Leg latestLeg;
    // List<Leg> legsInCurrentTrip = new List<Leg>{};
    // Boolean hasInBoundTrip = false;
    List<Trip> tripsToReturn = new List<Trip>{};
    switch on booking.Type__c {
      when 'OneWay' {
        List<Leg> tripLegs = new List<Leg>{};
        for (Leg l : sortedLegs) {
          tripLegs.add(l);
        }
        tripsToReturn.add(new Trip(tripLegs));
      }
      when else {
        throw new BookingTypeNotSupportedException(
          'Booking type "' +
          Bookings.nameToBookingType.get(booking.Type__c) +
          '" is not yet supported.'
        );
      }
    }

    for (Trip t : tripsToReturn) {
      t.setAirports(airportCodeToAirport);
    }

    return tripsToReturn;

    /*
     * Go through the segments backwards.
     * Looping through forwards makes it very difficult to distinguish between whether a cancelled flight is outbound or inbound.
     */
    // for (Integer i = sortedSegments.size() - 1; i >= 0; i--) {
    //   Segment__c s = sortedSegments[i];
    //   Type segmentsTripType = nameToType.get(s.Trip_Type__c);
    //   if (segmentsTripType == null) {
    //     segmentsTripType = Type.Unknown;
    //   }
    //   /*
    //    * Check if the segment is the last segment in the booking, cancelled or unknown => add it to the trip.
    //    *
    //    * This is logical in most cases. The most common case this does not work for is if the flight to the
    //    * final destination was cancelled (and there is a return flight home) and the replacement flight
    //    * departs before the original one.
    //    *
    //    * TODO: Handle Cancellations and Unknowns better.
    //    */
    //   if (
    //     latestLeg == null ||
    //     segmentsTripType == Type.Cancelled ||
    //     segmentsTripType == Type.Unknown
    //   ) {
    //     latestLeg = s;
    //     segmentsInCurrentTrip.add(s);
    //     continue;
    //   }

    //   if (s.Flight__r == null) {
    //     throw new InsufficientDataException(
    //       'You must fetch the Flight__r for the Segments__r for the booking.'
    //     );
    //   }

    //   // We can only have one outbound and one inbound trip (Except for MultiCity bookings)
    //   Boolean switchedToOutbound = (s.Trip_Type__c != latestLeg.Trip_Type__c &&
    //   segmentsTripType == Trip.Type.Outbound &&
    //   !hasInBoundTrip);

    //   Boolean moreThan24HoursAtAirport = DateUtils.isMoreThan24HoursBetween(
    //     latestLeg.Flight__r.Scheduled_Departure_Time__c,
    //     s.Flight__r.Scheduled_Arrival_Time__c
    //   );

    //   /**
    //    * Switched to inbound does not work for MultiCity bookings.
    //    * However, it is a MultiCity booking, it is relatively unlikely you will stay less than
    //    * 24 hours at a destination airport. This is most likely to happen to DayReturn bookings.
    //    */
    //   Boolean segmentReachedAFinalDestination =
    //     moreThan24HoursAtAirport ||
    //     (switchedToOutbound &&
    //     Bookings.nameToBookingType.get(booking.Type__c) !=
    //     Bookings.Type.MultiCity);

    //   if (segmentReachedAFinalDestination) {
    //     tripsToReturn.add(
    //       new Trip(
    //         new Segments(segmentsInCurrentTrip).getSortedInstanceRecords()
    //       )
    //     );
    //     segmentsInCurrentTrip = new List<Segment__c>{};
    //     hasInBoundTrip = true;
    //   } else {
    //     // If not, continue looping through the segments
    //     latestLeg = s;
    //   }
    //   segmentsInCurrentTrip.add(s);
    // }

    // tripsToReturn.add(
    //   new Trip((new Segments(segmentsInCurrentTrip)).getSortedInstanceRecords())
    // );

    // // No, refactor, DB-call -> see eu261-service 773
    // for (Trip t : tripsToReturn) {
    //   t.setAirports(airportCodeToAirport);
    // }

    // return tripsToReturn;
  }

  // Do not use in batch
  private void setAirports() {
    Flight__c firstFlight = sortedLegs[0].flight;
    Flight__c finalFlight = getFlightToFinalDestination();

    String originAirportCode = firstFlight.Departure_Airport__c;
    String destinationAirportCode = finalFlight.Arrival_Airport__c;

    List<Airport__c> aps = AirportsSelector.newInstance()
      .selectByIATACode(
        new Set<String>{ originAirportCode, destinationAirportCode }
      );

    for (Airport__c a : aps) {
      if (a.TEDS_Identifier__c == originAirportCode) {
        this.originAirport = a;
      } else if (a.TEDS_Identifier__c == destinationAirportCode) {
        this.destinationAirport = a;
      }
    }
  }

  private void setAirports(Map<String, Airport__c> airportCodeToAirport) {
    Flight__c firstFlight = sortedLegs[0].flight;
    Flight__c finalFlight = getFlightToFinalDestination();

    this.originAirport = airportCodeToAirport.get(
      firstFlight.Departure_Airport__c
    );
    this.destinationAirport = airportCodeToAirport.get(
      finalFlight.Arrival_Airport__c
    );
  }
}
