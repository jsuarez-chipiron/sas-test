public without sharing class Bookings extends ApplicationDomain {
  public Bookings(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Booking__c>) Records;

    List<Booking> bookingObjects = new List<Booking>();
    for (Booking__c b : this.instanceRecords) {
      bookingObjects.add(new Booking(b));
    }

    this.objects = bookingObjects;
  }

  public List<Booking__c> instanceRecords;
  public List<Booking> objects;

  // fullRecords exist only when an instance has been created from TEDS
  // response data.
  public List<FullBookingData> fullRecords;
  // edwBookings exist only when an instance has been created from EDW
  // response data.
  public List<EDWBooking> edwBookings;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Bookings(records);
    }
  }

  public static Bookings newInstance(List<Booking__c> sObjectList) {
    return (Bookings) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public static Bookings createFromTEDSData(
    List<IRR_MOD_TedsBooking> bookingData
  ) {
    List<FullBookingData> toReturn = new List<FullBookingData>();
    List<Booking__c> allBookings = new List<Booking__c>();

    for (IRR_MOD_TedsBooking booking : bookingData) {
      Booking__c bookingToCreate = new Booking__c(
        Booking_Reference__c = booking.reference,
        Created_at_Travel_Office_Id__c = booking?.audit?.created?.officeId ==
          null
          ? ''
          : booking.audit.created.officeId,
        Name = booking.id,
        TEDS_Identifier__c = booking.id,
        Type__c = booking.type,
        Is_Cancelled__c = booking.isCancelled
      );
      allBookings.add(bookingToCreate);

      Map<String, Flight__c> flightsProcessed = new Map<String, Flight__c>();
      Map<String, List<Segment__c>> segmentsToCreate = new Map<String, List<Segment__c>>();

      // Create passengers
      List<Passenger__c> passengersToCreate = new List<Passenger__c>();
      for (IRR_MOD_TedsBooking.Passenger p : booking.passengers) {
        Passenger__c newPassenger = new Passenger__c(
          First_Name__c = p.firstName,
          Identifier__c = p.id,
          Last_Name__c = p.lastName
        );

        if (p.frequentTraveler.euroBonus.size() > 0) {
          newPassenger.EuroBonus_Number__c = p.frequentTraveler.euroBonus[0]
            .number_x;
        }

        if (p.contact.phone.size() > 0) {
          newPassenger.Phone__c = p.contact.phone[0].number_x;
        }

        if (
          p.contact.email.size() > 0 &&
          StringUtils.isEmailAddress(p.contact.email[0].address)
        ) {
          newPassenger.Email__c = p.contact.email[0].address;
        }

        passengersToCreate.add(newPassenger);
      }

      for (IRR_MOD_TedsBooking.Trip trip : booking.trips) {
        for (IRR_MOD_TedsBooking.SegmentTrip segmentTrip : trip.segments) {
          String flightId = segmentTrip.flight.id.trim().toUpperCase();

          // Create flights
          Datetime arrivalDate = Datetime.valueOf(
            segmentTrip.flight.arrival.scheduledTime.utc.replace('T', ' ')
              .replace('Z', '')
          );
          Datetime departureDate = Datetime.valueOf(
            segmentTrip.flight.departure.scheduledTime.utc.replace('T', ' ')
              .replace('Z', '')
          );
          String scheduledArrivalDateLocal = segmentTrip.flight.arrival.scheduledTime
            ?.local
            ?.replace('Z', '');

          String scheduledDepartureDateLocal = segmentTrip.flight.departure.scheduledTime
            ?.local
            ?.replace('Z', '');

          Flight__c newFlight = new Flight__c(
            Name = flightId,
            Arrival_Airport__c = segmentTrip.flight.arrival.station,
            Departure_Airport__c = segmentTrip.flight.departure.station,
            Operating_Carrier__c = segmentTrip.flight.operatingCarrier,
            Scheduled_Arrival_Time__c = arrivalDate,
            Scheduled_Arrival_Time_Local__c = scheduledArrivalDateLocal,
            Scheduled_Departure_Time__c = departureDate,
            Scheduled_Departure_Time_Local__c = scheduledDepartureDateLocal,
            TEDS_Identifier__c = flightId
          );

          flightsProcessed.put(flightId, newFlight);

          // Create segments
          // Create one segment per passenger per flight in the booking.
          for (Passenger__c p : passengersToCreate) {
            IRR_MOD_TedsBooking.Passenger passengerData;
            IRR_MOD_TedsBooking.Segment segmentPassenger;
            String ssrs = '';

            for (IRR_MOD_TedsBooking.Passenger pData : booking.passengers) {
              if (pData != null && pData.id == p.Identifier__c) {
                passengerData = pData;
                break;
              }
            }
            for (IRR_MOD_TedsBooking.Segment pSeg : passengerData.segments) {
              if (pSeg.segmentId == segmentTrip.id) {
                segmentPassenger = pSeg;
                break;
              }
            }

            for (
              IRR_MOD_TedsBooking.SpecialServiceRequests ssr : passengerData.specialServiceRequests
            ) {
              for (String segId : ssr.segmentIds) {
                if (segId == segmentTrip.id) {
                  ssrs += ssrs.length() > 0 ? ',' + ssr.code : ssr.code;
                  break;
                }
              }
            }

            Integer baggage = (segmentPassenger.baggage != null) &&
              (segmentPassenger.baggage.quantity != null)
              ? segmentPassenger.baggage.quantity.allowed +
                segmentPassenger.baggage.quantity.extra
              : 0;

            Segment__c newSegment = new Segment__c(
              Baggage_Quantity__c = baggage,
              Booking_Class__c = segmentTrip.bookingClass,
              Check_In_Status__c = segmentPassenger.checkin == null
                ? 'Unknown'
                : segmentPassenger.checkin.status,
              Fare_Basis__c = segmentPassenger.fare == null
                ? ''
                : segmentPassenger.fare.basis,
              Identifier__c = segmentTrip.id + p.Identifier__c,
              Is_Boarded__c = segmentPassenger.isBoarded,
              Name = segmentTrip.flight.id,
              Seat__c = segmentPassenger.seat,
              Segment_Status__c = segmentTrip.status,
              Segment_Status_Code__c = segmentTrip.statusCode,
              Service_Class__c = segmentTrip.serviceClass,
              Special_Service_Requests__c = ssrs,
              Ticket_Number__c = segmentPassenger.ticket == null
                ? ''
                : segmentPassenger.ticket.number_x,
              Ticket_Type__c = segmentPassenger.ticket == null
                ? ''
                : segmentPassenger.ticket.type,
              Trip_Type__c = trip.type
            );

            if (segmentsToCreate.get(flightId) == null) {
              segmentsToCreate.put(flightId, new List<Segment__c>());
            }
            segmentsToCreate.get(flightId).add(newSegment);
          }
        }
      }

      List<Flight__c> flightsToCreate = flightsProcessed.values();

      toReturn.add(
        new FullBookingData(
          bookingToCreate,
          flightsToCreate,
          passengersToCreate,
          segmentsToCreate
        )
      );
    }

    Bookings newBookingObject = Bookings.newInstance(allBookings);
    newBookingObject.fullRecords = toReturn;

    return newBookingObject;
  }

  public static Bookings createFromEDWData(
    List<FetchEDWDataResponse.Reservation> reservations
  ) {
    List<EDWBooking> edwBookings = new List<EDWBooking>();
    List<Booking__c> createdBookings = new List<Booking__c>();
    for (FetchEDWDataResponse.Reservation reservation : reservations) {
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
      b.updateSObjectFields();
      //create flights
      Flights createdFlights = Flights.createFromEDWData(
        reservation.irregularityList.irregularity
      );
      //create passengers
      Passengers createdPassengers = Passengers.createFromEDWData(
        reservation.passengerList.passenger
      );
      Segments createdSegments = Segments.createFromEDWData(
        reservation.segmentList.segment,
        createdPassengers.instanceRecords
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

  public Bookings upsertEDWDataToDB() {
    for (EDWBooking edwb : edwBookings) {
      upsert edwb.booking.underlyingSObject TEDS_Identifier__c;
      edwb.flights.upsertToDB();
      for (Passenger__c p : edwb.passengers.instanceRecords) {
        p.Booking__c = edwb.booking.underlyingSObject.Id;
      }
      List<Passenger__c> existingPassengers = PassengersSelector.newInstance()
        .selectByBookingId(new Set<Id>{ edwb.booking.underlyingSObject.Id });
      List<Segment__c> existingSegments = SegmentsSelector.newInstance()
        .selectByBookingId(new Set<Id>{ edwb.booking.underlyingSObject.Id });
      List<SObject> toDelete = new List<SObject>();
      if (existingPassengers.size() > 0) {
        toDelete.addAll(existingPassengers);
      }
      if (existingSegments.size() > 0) {
        toDelete.addAll(existingSegments);
      }
      delete toDelete;
      insert edwb.passengers.instanceRecords;
      edwb.segments.addBookingReference(edwb.booking.underlyingSObject.Id)
        .addFlightReferences(edwb.flights.instanceRecords)
        .upsertToDB(edwb.passengers.instanceRecords);
    }
    return this;
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

  /**
   * Inserts all booking related objects to the DB and constructs the lookups
   * between them.
   *
   * Because upserts by external id are not supported by fflib, this method has
   * to have its own DML statements.
   */
  public Bookings upsertToDB() {
    List<Booking__c> bookingsToUpsert = new List<Booking__c>();
    Map<String, Flight__c> uniqueFlightsToUpsert = new Map<String, Flight__c>();

    Set<String> bookingTedsIds = new Set<String>();
    for (FullBookingData b : fullRecords) {
      bookingTedsIds.add(b.booking.TEDS_Identifier__c);
      bookingsToUpsert.add(b.booking);
      for (Flight__c f : b.flights) {
        if (uniqueFlightsToUpsert.get(f.TEDS_Identifier__c) == null) {
          uniqueFlightsToUpsert.put(f.TEDS_Identifier__c, f);
        }
      }
    }

    List<Booking__c> bookingsFromDB = BookingsSelector.newInstance()
      .selectByTEDSIdFull(bookingTedsIds);

    if (bookingsFromDB.size() > 0) {
      List<Passenger__c> passengersToDelete = new List<Passenger__c>();
      List<Segment__c> segmentsToDelete = new List<Segment__c>();
      for (Booking__c existingBooking : bookingsFromDB) {
        for (Passenger__c existingPassenger : existingBooking.Passengers__r) {
          passengersToDelete.add(existingPassenger);
        }
        for (Segment__c existingSegment : existingBooking.Segments__r) {
          segmentsToDelete.add(existingSegment);
        }
      }

      List<SObject> toDelete = new List<SObject>();
      toDelete.addAll(passengersToDelete);
      toDelete.addAll(segmentsToDelete);

      try {
        delete toDelete;
      } catch (DMLException e) {
        if (e.getDmlType(0) == StatusCode.ENTITY_IS_DELETED) {
          // A parallel thread may have deleted the entities. Let's just ignore.
        } else {
          throw e;
        }
      }
    }

    // Upsert bookings
    // The upsert operation seems to fail due to a race condition between two threads
    // trying to upsert the records simultaneously. One thread succeeds and the other
    // fails with a duplicate value exception.
    try {
      upsert bookingsToUpsert TEDS_Identifier__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert bookingsToUpsert TEDS_Identifier__c;
      }
    }

    // Upsert flights
    (new Flights(uniqueFlightsToUpsert.values())).upsertToDB();

    List<SObject> passengersToInsert = new List<SObject>();
    List<SObject> segmentsToInsert = new List<SObject>();

    for (FullBookingData b : fullRecords) {
      for (Passenger__c p : b.passengers) {
        p.Booking__c = b.booking.Id;
        passengersToInsert.add(p);
      }
      for (Flight__c f : b.flights) {
        for (Segment__c s : b.segments.get(f.TEDS_Identifier__c)) {
          s.Booking__c = b.booking.Id;
          s.Flight__c = f.Id;
          segmentsToInsert.add(s);
        }
      }
    }

    List<SObject> toInsert = new List<SObject>();
    toInsert.addAll(passengersToInsert);
    toInsert.addAll(segmentsToInsert);

    insert toInsert;

    return this;
  }

  /**
   * Loads Passenger, Flight, Segment data for instance of domain that was not
   * created as part of retrieving data from TEDS.
   * Stores the data in the same FullBookingData format as if domain instance was
   * created from call to TEDS
   *
   * TODO: Move me to the service class, or somewhere.
   */
  public Bookings reloadFullBookingData() {
    Set<Id> bookingIds = new Map<Id, Booking__c>(instanceRecords).keySet();
    Map<Id, Flight__c> idsToFlights = new Map<Id, Flight__c>(
      FlightsSelector.newInstance().selectByBookingIds(bookingIds)
    );
    List<Passenger__c> allPassengers = PassengersSelector.newInstance()
      .selectByBookingId(bookingIds);
    List<Segment__c> allSegments = SegmentsSelector.newInstance()
      .selectByBookingId(bookingIds);

    Map<String, List<Segment__c>> flightIdToSegments = new Map<String, List<Segment__c>>();
    Map<Id, List<Flight__c>> bookingIdToFlights = new Map<Id, List<Flight__c>>();

    //Sort Segments for TEDS Flight Id
    //Sort Flights by Booking
    for (Segment__c segment : allSegments) {
      Flight__c flightForSegment = idsToFlights.get(segment.Flight__c);
      if (bookingIdToFlights.get(segment.Booking__c) == null) {
        bookingIdToFlights.put(segment.Booking__c, new List<Flight__c>());
      }
      if (flightForSegment != null) {
        bookingIdToFlights.get(segment.Booking__c).add(flightForSegment);
      }

      if (flightIdToSegments.get(flightForSegment.TEDS_Identifier__c) == null) {
        flightIdToSegments.put(
          flightForSegment.TEDS_Identifier__c,
          new List<Segment__c>()
        );
      }
      flightIdToSegments.get(flightForSegment.TEDS_Identifier__c).add(segment);
    }
    Map<Id, List<Passenger__c>> bookingIdToPassengers = new Map<Id, List<Passenger__c>>();
    //Sort passenger by booking Id
    for (Passenger__c passenger : allPassengers) {
      if (bookingIdToPassengers.get(passenger.Booking__c) == null) {
        bookingIdToPassengers.put(
          passenger.Booking__c,
          new List<Passenger__c>()
        );
      }
      bookingIdToPassengers.get(passenger.Booking__c).add(passenger);
    }

    if (fullRecords == null) {
      fullRecords = new List<FullBookingData>();
    }
    for (Booking__c booking : instanceRecords) {
      FullBookingData fbd = new FullBookingData(
        booking,
        bookingIdToFlights.get(booking.Id),
        bookingIdToPassengers.get(booking.Id),
        flightIdToSegments
      );
      fullRecords.add(fbd);
    }
    return this;
  }

  public class FullBookingData {
    public Booking__c booking { get; set; }
    public List<Flight__c> flights { get; set; }
    public List<Passenger__c> passengers { get; set; }
    public Map<String, List<Segment__c>> segments { get; set; } // TEDS FlightId => List of segments

    public FullBookingData(
      Booking__c booking,
      List<Flight__c> flights,
      List<Passenger__c> passengers,
      Map<String, List<Segment__c>> segments // Flight id to segment
    ) {
      this.booking = booking;
      this.flights = flights;
      this.passengers = passengers;
      this.segments = segments;
    }
  }
}
