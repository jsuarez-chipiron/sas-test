public without sharing abstract class Reservation {
  public Booking booking { get; protected set; }
  @TestVisible
  protected Map<String, Flight> flights { get; protected set; }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  protected Reservation() {
  }

  protected abstract Booking constructBookingFromSourceData(Object sourceData);
  protected abstract List<Passenger> constructPassengersFromSourceData(
    List<Object> sourceData
  );

  protected abstract List<Segment> constructSegmentsFromSourceData(
    List<Object> sourceData
  );

  protected abstract Map<String, Flight> constructFlightsFromSourceData(
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
      .selectByTEDSId(this.flights.keySet());

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
      List<Passenger__c> passengersToDelete = new List<Passenger__c>();
      List<Segment__c> segmentsToDelete = new List<Segment__c>();
      for (Passenger__c existingPassenger : existingBookings[0].Passengers__r) {
        passengersToDelete.add(existingPassenger);
      }
      for (Segment__c existingSegment : existingBookings[0].Segments__r) {
        segmentsToDelete.add(existingSegment);
      }
      toDelete.addAll(passengersToDelete);
      toDelete.addAll(segmentsToDelete);
      this.booking.updateSObjectFields();
      this.booking.underlyingSObject.id = existingBookings[0].Id;
      uowUpsert.registerDirty(this.booking.underlyingSObject);
    } else {
      this.booking.updateSObjectFields();
      uowUpsert.registerNew(this.booking.underlyingSObject);
    }

    for (Passenger p : this.booking.passengers) {
      p.updateSObjectFields();
      uowUpsert.registerNew(p.underlyingSObject);
      uowUpsert.registerRelationship(
        p.underlyingSObject,
        Passenger__c.Booking__c,
        this.booking.underlyingSObject
      );
    }
    for (Flight f : this.flights.values()) {
      f.updateSObjectFields();
      if (!existingFlightIdToRecord.containsKey(f.tedsIdentifier)) {
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
        uowUpsert.registerRelationship(
          fi.underlyingSObject,
          FlightIrregularities__c.Flight__c,
          f.underlyingSObject
        );
      }
    }
    for (Segment s : this.booking.segments) {
      s.updateSObjectFields();
      uowUpsert.registerNew(s.underlyingSObject);
      uowUpsert.registerRelationship(
        s.underlyingSObject,
        Segment__c.Booking__c,
        this.booking.underlyingSObject
      );
      if (this.flights.containsKey(s.name)) {
        uowUpsert.registerRelationship(
          s.underlyingSObject,
          Segment__c.Flight__c,
          s.flight.underlyingSObject
        );
      }
      if (s.getEvents() == null) {
        continue;
      }
      for (SegmentEvent se : s.getEvents()) {
        se.updateSObjectFields();
        uowUpsert.registerNew(se.underlyingSObject);
        uowUpsert.registerRelationship(
          se.underlyingSObject,
          Segment_Event__c.Segment__c,
          s.underlyingSObject
        );
      }
    }
    uowDelete.registerDeleted(toDelete);

    return this;
  }
}
