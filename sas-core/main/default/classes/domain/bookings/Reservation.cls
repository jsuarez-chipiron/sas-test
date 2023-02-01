public without sharing abstract class Reservation {
  public Booking booking { get; protected set; }
  public List<Passenger> passengers { get; protected set; }
  public Map<String, List<Segment>> segments { get; protected set; }
  public List<Flight> flights { get; protected set; }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  protected Reservation() {
  }
  protected Reservation(
    Booking b,
    List<Passenger> p,
    Map<String, List<Segment>> s,
    List<Flight> f
  ) {
    this.booking = b;
    this.passengers = p;
    this.segments = s;
    this.flights = f;
  }

  protected abstract Booking constructBookingFromSourceData(Object sourceData);
  protected abstract List<Passenger> constructPassengersFromSourceData(
    List<Object> sourceData
  );

  protected abstract Map<String, List<Segment>> constructSegmentsFromSourceData(
    List<Object> sourceData
  );

  protected abstract List<Flight> constructFlightsFromSourceData(
    List<Object> sourceData
  );
  protected abstract Map<String, List<FlightIrregularity>> constructFlightIrregularitiesFromSourceData(
    List<Object> sourceData
  );

  public Bookings createBookingsDomainInstance() {
    Bookings toReturn = Bookings.newInstance(
      new List<Booking__c>{ this.booking.underlyingSObject }
    );
    toReturn.reservations = new List<Reservation>{ this };
    return toReturn;
  }
  /**
   * @param uowUpsert fflib UnitOfWork to handle the upserts of data
   * @param uowDelete fflib UnitOfWork to handle the deletion of data
   * @return The Reservation itself
   *
   * Upserts the Booking and Flights if they already exist.
   * Deletes all the detail records (i.e. Segments, Segment Events, Passengers, and Flight Irregularities)
   * The reason for using two units of work is because the commitWork method processes inserts/updates before deletions
   * and we want it to work in the reverse order
   */
  public Reservation registerUpsert(
    fflib_ISObjectUnitOfWork uowUpsert,
    fflib_ISObjectUnitOfWork uowDelete
  ) {
    List<SObject> toDelete = new List<SObject>();
    List<Flight> newFlights = new List<Flight>();
    List<Flight__c> existingFlights = FlightsSelector.newInstance()
      .selectByTEDSId(this.segments.keySet());
    Map<String, Flight__c> existingFlightIdToRecord = new Map<String, Flight__c>();
    for (Flight__c fRecord : existingFlights) {
      existingFlightIdToRecord.put(fRecord.TEDS_Identifier__c, fRecord);
    }
    if (existingFlights.size() > 0) {
      toDelete.addAll(
        FlightIrregularitiesSelector.newInstance()
          .selectByFlightId(new Map<Id, Flight__c>(existingFlights).keySet())
      );
    }

    List<Booking__c> existingBookings = BookingsSelector.newInstance()
      .selectByTEDSIdFull(new Set<String>{ this.booking.tedsIdentifier });
    Boolean shouldUpsertBooking = existingBookings.size() == 1;
    if (shouldUpsertBooking) {
      toDelete.addAll(
        PassengersSelector.newInstance()
          .selectByBookingId(new Set<Id>{ existingBookings[0].Id })
      );
      toDelete.addAll(
        SegmentsSelector.newInstance()
          .selectByBookingId(new Set<Id>{ existingBookings[0].Id })
      );
      this.booking.updateSObjectFields();
      this.booking.underlyingSObject.id = existingBookings[0].Id;
      uowUpsert.registerDirty(this.booking.underlyingSObject);
    } else {
      this.booking.updateSObjectFields();
      uowUpsert.registerNew(this.booking.underlyingSObject);
    }

    for (Passenger p : this.passengers) {
      p.updateSObjectFields();
      uowUpsert.registerNew(p.underlyingSObject);
    }
    for (Flight f : this.flights) {
      f.updateSObjectFields();
      if (existingFlightIdToRecord.get(f.tedsIdentifier) == null) {
        uowUpsert.registerNew(f.underlyingSObject);
      } else {
        f.underlyingSObject.id = existingFlightIdToRecord.get(f.tedsIdentifier)
          .Id;
        uowUpsert.registerDirty(f.underlyingSObject);
      }
      if (f.irregularities == null) {
        continue;
      }
      for (FlightIrregularity fi : f.irregularities) {
        fi.updateSObjectFields();
        uowUpsert.registerNew(fi.underlyingSObject);
      }
    }
    List<Segment> allSegments = new List<Segment>();
    for (List<Segment> segments : this.segments.values()) {
      allSegments.addAll(segments);
    }
    for (Segment s : allSegments) {
      s.updateSObjectFields();
      uowUpsert.registerNew(s.underlyingSObject);
      if (s.getEvents() == null) {
        continue;
      }
      for (SegmentEvent se : s.getEvents()) {
        se.updateSObjectFields();
        uowUpsert.registerNew(se.underlyingSObject);
      }
    }
    uowDelete.registerDeleted(toDelete);

    return this;
  }

  /**
   * Handles the creation of relationships between record prior to upserting.
   * @param uow THe UnitOfWork used for inserting/updating records
   */
  public Reservation resolveRelationships(fflib_ISObjectUnitOfWork uow) {
    Map<String, Flight> flightIdToFlight = new Map<String, Flight>();

    for (Passenger p : this.passengers) {
      uow.registerRelationship(
        p.underlyingSObject,
        Passenger__c.Booking__c,
        this.booking.underlyingSObject
      );
    }

    for (Flight f : this.flights) {
      flightIdToFlight.put(f.tedsIdentifier, f);
      if (f.irregularities == null) {
        continue;
      }
      for (FlightIrregularity fi : f.irregularities) {
        uow.registerRelationship(
          fi.underlyingSObject,
          FlightIrregularities__c.Flight__c,
          f.underlyingSObject
        );
      }
    }
    List<Segment> allSegments = new List<Segment>();
    for (List<Segment> segments : this.segments.values()) {
      allSegments.addAll(segments);
    }
    for (Segment s : allSegments) {
      uow.registerRelationship(
        s.underlyingSObject,
        Segment__c.Booking__c,
        this.booking.underlyingSObject
      );
      uow.registerRelationship(
        s.underlyingSObject,
        Segment__c.Flight__c,
        flightIdToFlight.get(s.name).underlyingSObject
      );
      if (s.getEvents() == null) {
        continue;
      }
      for (SegmentEvent se : s.getEvents()) {
        uow.registerRelationship(
          se.underlyingSObject,
          Segment_Event__c.Segment__c,
          s.underlyingSObject
        );
      }
    }
    return this;
  }
}
