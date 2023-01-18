public without sharing class Booking extends AbstractSObjectWrapper {
  public Booking__c underlyingSObject { get; private set; }

  public String bookingReference;
  public String createdAtTravelOfficeId;
  public Boolean isCancelled = false;
  public Boolean isStaffBooking = false;
  public String tedsIdentifier;
  public Type type;

  public List<Segment> segments;
  public List<Passenger> passengers;

  @TestVisible
  public Set<Flight> flights {
    get {
      if (this.segments == null) {
        return null;
      }
      Set<Flight> toReturn = new Set<Flight>();

      for (Segment s : this.segments) {
        if (s.flight != null) {
          toReturn.add(s.flight);
        }
      }

      return toReturn;
    }
  }

  public enum Type {
    DayReturn,
    MultiCity,
    OneWay,
    RoundTrip,
    Unknown
  }

  public class EDWBooking {
    public Booking booking { get; private set; }
    public Segments segments { get; private set; }
    public Flights flights { get; private set; }
    public Passengers passengers { get; private set; }
    public EDWBooking(Booking b, Flights f, Segments s, Passengers p) {
      this.booking = b;
      this.segments = s;
      this.flights = f;
      this.passengers = p;
    }
  }

  @TestVisible
  private Booking() {
    this.underlyingSObject = new Booking__c();
  }

  public Booking(Booking__c b) {
    super(b);
    this.underlyingSObject = b;

    this.bookingReference = b.Booking_Reference__c;
    this.createdAtTravelOfficeId = b.Created_at_Travel_Office_Id__c;
    this.isCancelled = b.Is_Cancelled__c;
    this.isStaffBooking = b.Is_Staff_Booking__c;
    this.tedsIdentifier = b.TEDS_Identifier__c;
    this.type = TYPE_PICKLIST_VALUE_TO_ENUM.get(b.Type__c);

    if (b.Segments__r != null) {
      List<Segment> segmentsForBooking = new List<Segment>();
      List<Flight> flightsForBooking = new List<Flight>();
      for (Segment__c segmentSObject : b.Segments__r) {
        Segment s = new Segment(segmentSObject);
        segmentsForBooking.add(s);
      }

      segmentsForBooking.sort();
      this.segments = segmentsForBooking;
    }

    if (b.Passengers__r != null) {
      List<Passenger> passengersForBooking = new List<Passenger>();
      for (Passenger__c p : b.Passengers__r) {
        passengersForBooking.add(new Passenger(p));
      }
      this.passengers = passengersForBooking;
    }
  }

  private static final Map<String, Type> TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, Type>{
    'DayReturn' => Type.DayReturn,
    'MultiCity' => Type.MultiCity,
    'OneWay' => Type.OneWay,
    'RoundTrip' => Type.RoundTrip,
    'Unknown' => Type.Unknown
  };

  private static final Map<Type, String> TYPE_ENUM_TO_PICKLIST_VALUE = new Map<Type, String>{
    Type.DayReturn => 'DayReturn',
    Type.MultiCity => 'MultiCity',
    Type.OneWay => 'OneWay',
    Type.RoundTrip => 'RoundTrip',
    Type.Unknown => 'Unknown'
  };

  public override void updateSObjectFields() {
    this.underlyingSObject.Booking_Reference__c = this.bookingReference;
    this.underlyingSObject.Created_at_Travel_Office_Id__c = this.createdAtTravelOfficeId;
    this.underlyingSObject.Is_Cancelled__c = this.isCancelled;
    this.underlyingSObject.Is_Staff_Booking__c = this.isStaffBooking;
    this.underlyingSObject.TEDS_Identifier__c = this.tedsIdentifier;
    this.underlyingSObject.Type__c = TYPE_ENUM_TO_PICKLIST_VALUE.get(this.type);
  }

  public class UnsupportedException extends Exception {
  }

  /**
   * Returns true if given flight exists in the booking.
   *
   * @param flightId A flight in the format of Flight Number-Flight Date (ex. SK0001-20201010)
   * @throws MissingDataException if this booking instance doesn't have flights set.
   */
  public Boolean containsFlight(String flightId) {
    if (this.flights == null) {
      throw new MissingDataException('Missing flights.');
    }

    for (Flight f : this.flights) {
      if (f.tedsIdentifier.substring(0, 15) == flightId) {
        return true;
      }
    }

    return false;
  }

  /**
   * Returns true if a passenger with the given last name exists in this booking.
   * Case insensitive.
   *
   * @param passengerLastName Last name of the passenger to check
   * @throws MissingDataException if this booking instance doesn't have passengers set.
   */
  public Boolean containsPassenger(String passengerLastName) {
    if (this.passengers == null) {
      throw new MissingDataException('Missing passengers.');
    }

    for (Passenger p : this.passengers) {
      if (p.lastName.toLowerCase() == passengerLastName.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /**
   * Returns true if any flights in this booking have been delayed or cancelled.
   *
   * @throws MissingDataException if this booking doesn't have flights set.
   */
  public Boolean hasDelayedOrCancelledFlights() {
    if (this.flights == null) {
      throw new MissingDataException('Missing flights.');
    }

    for (Flight f : this.flights) {
      if (f.isDelayedOrCancelled()) {
        return true;
      }
    }

    return false;
  }

  /**
   * Whether the booking has a non Star Alliance operating carrier for at
   * least one leg in the booking.
   *
   * Needs flights to be populated.
   *
   * @return A map from booking id to whether that booking has non Star
   * Alliance operating carriers as a part of the journey.
   */
  public Boolean hasNonStarAllianceOperatingCarriers() {
    if (this.flights == null) {
      throw new MissingDataException('Missing flights.');
    }

    for (Flight f : this.flights) {
      if (!f.isOperatedByStarAlliance()) {
        return true;
      }
    }
    return false;
  }

  public void setAirports(Map<String, Airport> airportCodeToAirportObjects) {
    for (Segment s : segments) {
      s.flight.departureAirportObject = airportCodeToAirportObjects.get(
        s.flight.departureAirport
      );
      s.flight.arrivalAirportObject = airportCodeToAirportObjects.get(
        s.flight.arrivalAirport
      );
    }
  }

  /**
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
  public List<Trip> getTrips() {
    return Trip.createFromBooking(this, System.now());
  }

  /**
   * Like getTrips() but you can get the trips at a specific time. E.g. before a cancellation.
   */
  public List<Trip> getTripsAtTime(Datetime theTime) {
    return Trip.createFromBooking(this, theTime);
  }

  public List<Segment> getSegmentsForFlight(Flight f) {
    List<Segment> claimSegments = new List<Segment>();
    for (Segment s : this.segments) {
      if (s.flight == f) {
        claimSegments.add(s);
      }
    }
    return claimSegments;
  }

  public Trip.CancellationTime getCancellationTime(Flight f) {
    List<FlightIrregularity> cancellations = f.getCancellations();

    if (cancellations.size() > 1) {
      throw new UnsupportedException(
        'Bookings with flights which have more than one cancellation are not supported'
      );
    }

    FlightIrregularity cancellation = cancellations[0];
    if (cancellation.cancellationTime == null) {
      throw new MissingDataException(
        'Cancellation does not have a cancellation time'
      );
    }

    // Make sure all segments for the flight have the same history
    Datetime segmentUnconfirmed;
    Datetime segmentRemoved;
    String officeUnconfirming;
    String officeRemoving;
    for (Segment s : getSegmentsForFlight(f)) {
      SegmentEvent unconfirmedEvent = s.getUnconfirmedEvent();
      SegmentEvent removedEvent = s.getRemovedEvent();

      Datetime currentSegmentUnconfirmed;
      if (unconfirmedEvent != null) {
        currentSegmentUnconfirmed = unconfirmedEvent.updateDate;
        officeUnconfirming = unconfirmedEvent.officeCode;
      }
      Datetime currentSegmentRemoved;
      if (removedEvent != null) {
        currentSegmentRemoved = removedEvent.updateDate;
        officeRemoving = removedEvent.officeCode;
      }

      if (
        currentSegmentUnconfirmed != segmentUnconfirmed &&
        segmentUnconfirmed != null
      ) {
        throw new Trip.InvalidException(
          'Segments with the same flight were unconfirmed at different times'
        );
      }
      segmentUnconfirmed = currentSegmentUnconfirmed;

      if (currentSegmentRemoved != segmentRemoved && segmentRemoved != null) {
        throw new Trip.InvalidException(
          'Segments with the same flight were removed at different times'
        );
      }
      segmentRemoved = currentSegmentRemoved;
    }

    if (segmentUnconfirmed == null && segmentRemoved == null) {
      throw new Trip.InvalidException(
        'Was not able to get segment cancellation time'
      );
    }

    return new Trip.CancellationTime(
      cancellation.cancellationTime,
      segmentUnconfirmed,
      segmentRemoved,
      officeUnconfirming,
      officeRemoving
    );
  }

  /**
   * Calculates the trip with the cancelled flight before the cancellation and the replacement trip
   *
   * @throws Trip.InvalidException if the trips calculated are invalid.
   * @throws Trip.BookingTypeNotSupportedException if the booking type is not yet supported.
   * @throws Segment.UnsupportedException if there are unsupported segment event statuses
   * @throws Trip.RouteException if there is an error when checking the trip validity (infinite loop)
   * @throws AbstractSObjectWrapper.MissingDataException if there is no cancellation time
   * @throws Booking.UnsupportedException if there is more than one cancellation
   */
  public List<Trip> getTripsBeforeAndAfterCancellation(Flight cancelledFlight) {
    Trip.CancellationTime cancellationTimeInfo = getCancellationTime(
      cancelledFlight
    );
    Datetime unconfirmed = cancellationTimeInfo.unconfirmed;
    Datetime removed = cancellationTimeInfo.removed;

    List<Trip> tripsBeforeIrregularity;
    if (unconfirmed != null) {
      tripsBeforeIrregularity = getTripsAtTime(unconfirmed.addMinutes(-5)); // Arbitrary
    } else {
      tripsBeforeIrregularity = getTripsAtTime(removed.addMinutes(-5));
    }

    Trip tripWithCancelledFlight = Trip.getTripWithFlight(
      tripsBeforeIrregularity,
      cancelledFlight
    );
    tripWithCancelledFlight.cancellationTimeInfo = cancellationTimeInfo;

    if (tripWithCancelledFlight == null) {
      throw new Trip.InvalidException(
        'was not able to set trip with claim flight'
      );
    }

    // First try to calculate this based on the UN time, then the removed time
    Trip replacementTrip;
    try {
      List<Segment> activeSegments = getActiveSegmentsAtTime(unconfirmed);

      replacementTrip = tripWithCancelledFlight.getOfferedRebooking(
        activeSegments
      );
      if (replacementTrip == null) {
        throw new Trip.InvalidException('No replacement');
      }
    } catch (Trip.InvalidException e) {
      List<Segment> activeSegments = getActiveSegmentsAtTime(removed);

      // Typically happens when an agent has manually rebooked the passengers
      replacementTrip = tripWithCancelledFlight.getOfferedRebooking(
        activeSegments
      );
    }

    return new List<Trip>{ tripWithCancelledFlight, replacementTrip };
  }

  public Trip getTripWithFlight(Flight f) {
    List<Trip> trips = getTrips();

    Trip withFlight;
    for (Trip t : trips) {
      if (t.containsFlight(f)) {
        withFlight = t;
        break;
      }
    }

    if (!withFlight.hasRouteFromOriginToDestination()) {
      throw new Trip.InvalidException(
        'Trip with flight does not have a route from origin to destination'
      );
    }

    return withFlight;
  }

  public Boolean hasReinstated(Flight f) {
    List<Segment> segments = this.getSegmentsForFlight(f);

    for (Segment s : segments) {
      if (s.hasBeenReinstated()) {
        return true;
      }
    }
    return false;
  }

  /**
   * Returns true if the given string is a valid booking reference.
   *
   * Valid booking reference is 5-6 alphanumeric characters. There are also
   * stricter limitations, but just in case they aren't fully universal, this
   * is a relatively lenient check.
   */
  public static Boolean isValidBookingReference(String bookingReference) {
    if (String.isBlank(bookingReference)) {
      return false;
    }

    return Pattern.compile('[a-zA-Z0-9]{5,6}')
      .matcher(bookingReference)
      .matches();
  }

  public static List<Booking> createFromList(List<Booking__c> bookings) {
    List<Booking> toReturn = new List<Booking>();

    for (Booking__c b : bookings) {
      toReturn.add(new Booking(b));
    }

    return toReturn;
  }

  public List<Segment> getActiveSegmentsAtTime(Datetime theTime) {
    U.verifyNotNull(segments);

    List<Segment> activeSegments = new List<Segment>();
    for (Segment s : segments) {
      if (s.getStatus(theTime) == Segment.Status.Confirmed) {
        activeSegments.add(s);
      }
    }

    return activeSegments;
  }

  public static Bookings createFromEDWData(
    List<FetchEDWBookingResponse.Reservation> reservations
  ) {
    List<EDWBooking> edwBookings = new List<EDWBooking>();
    List<Booking__c> createdBookings = new List<Booking__c>();
    for (FetchEDWBookingResponse.Reservation reservation : reservations) {
      String bookingIdentifier = String.format(
        '{0}-{1}',
        new List<Object>{
          reservation.reservationNumber,
          Datetime.newInstance(reservation.createdDate).format('yyyyMMdd')
        }
      );
      //create booking
      Booking b = new Booking(new Booking__c(Name = bookingIdentifier));
      b.bookingReference = reservation.reservationNumber;
      b.tedsIdentifier = bookingIdentifier;
      //TODO Ask SEIP to fix the Json response to have these separately
      if (reservation.segmentList?.segment.size() > 0) {
        b.createdAtTravelOfficeId = reservation.segmentList.segment[0].offCd;
        b.isStaffBooking = reservation.segmentList.segment[0].staffPNR == 'Y';
      }
      b.updateSObjectFields();
      //create flights
      Flights createdFlights = Flight.createFromEDWData(
        reservation.irregularityList.irregularity
      );
      //create passengers
      Passengers createdPassengers = Passenger.createFromEDWData(
        reservation.passengerList.passenger
      );
      Segments createdSegments = Segment.createFromEDWData(
        reservation.segmentList.segment,
        createdPassengers.instanceRecords
      );
      createdSegments.addEDWTicketInformation(
        reservation.ticketInfoList.ticketInfo
      );
      createdBookings.add(b.underlyingSObject);
      edwBookings.add(
        new EDWBooking(b, createdFlights, createdSegments, createdPassengers)
      );
    }
    Bookings bookingsInstance = Bookings.newInstance(createdBookings);
    bookingsInstance.edwBookings = edwBookings;
    bookingsInstance.upsertEDWDataToDB();
    return bookingsInstance;
  }
}
