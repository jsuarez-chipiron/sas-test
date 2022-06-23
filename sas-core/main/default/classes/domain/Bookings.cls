public without sharing class Bookings extends fflib_SObjectDomain {
  public Bookings(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Booking__c>) Records;
  }

  public List<Booking__c> instanceRecords;

  // fullRecords exist only when an instance has been created from TEDS
  // response data.
  public List<FullBookingData> fullRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Bookings(records);
    }
  }

  public static Bookings newInstance(List<Booking__c> sObjectList) {
    return (Bookings) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public class BookingReferenceInvalidException extends Exception {
  }

  public static Boolean isValidBookingReference(String bookingReference) {
    return (!String.isBlank(bookingReference) &&
    (bookingReference.length() == 5 ||
    bookingReference.length() == 6));
  }

  /**
   * Whether the bookings have a non Star Alliance operating carrier for at
   * least one leg in the booking.
   *
   * @return A map from booking id to whether that booking has non Star
   * Alliance operating carriers as a part of the journey.
   */
  public Map<Id, Boolean> haveNonStarAllianceOperatingCarriers() {
    Set<Id> bookingIds = (new Map<Id, Booking__c>(instanceRecords)).keySet();

    Map<Id, Boolean> flightIdToOperatedByStarAlliance = Flights.newInstance(
        FlightsSelector.newInstance().selectByBookingIds(bookingIds)
      )
      .operatedByStarAlliance();

    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Booking__c booking : instanceRecords) {
      Boolean hasNonStarAllianceOperators = false;
      for (Segment__c segment : booking.Segments__r) {
        Boolean flightOperatedByStarAlliance = flightIdToOperatedByStarAlliance.get(
          segment.Flight__c
        );
        if (!flightOperatedByStarAlliance) {
          hasNonStarAllianceOperators = true;
          break;
        }
      }
      toReturn.put(booking.Id, hasNonStarAllianceOperators);
    }

    return toReturn;
  }

  public Set<String> getFlightIds() {
    Set<String> toReturn = new Set<String>();

    if (fullRecords != null) {
      // Prefer getting flight data from fullRecords as they're always there if
      // we have that data.
      for (FullBookingData d : fullRecords) {
        for (Flight__c f : d.flights) {
          toReturn.add(f.TEDS_Identifier__c);
        }
      }
    } else {
      if (instanceRecords[0].Id != null) {
        // If the instance bookings exist in DB, they might also have related
        // flights in the DB.
        for (
          Flight__c f : FlightsSelector.newInstance()
            .selectByBookingIds(
              (new Map<Id, Booking__c>(instanceRecords)).keySet()
            )
        ) {
          toReturn.add(f.TEDS_Identifier__c);
        }
      }
      // else we have no FullBookingData and no DB links => can't find connected flights.
    }

    return toReturn;
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

        if (p.contact.email.size() > 0) {
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

  /**
   * Inserts all booking related objects to the DB and constructs the lookups
   * between them.
   *
   * Because upserts by external id are not supported by fflib, this method has
   * to have its own DML statements.
   */
  public Bookings upsertToDB() {
    // TODO: This should be called upsert.
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
      List<SObject> toDelete = new List<SObject>();
      for (Booking__c existingBooking : bookingsFromDB) {
        for (Passenger__c existingPassenger : existingBooking.Passengers__r) {
          toDelete.add(existingPassenger);
        }
        for (Segment__c existingSegment : existingBooking.Segments__r) {
          toDelete.add(existingSegment);
        }
      }
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
    // The upsert operation seems to fail due to a race condition between two threads
    // trying to upsert the records simultaneously. One thread succeeds and the other
    // fails with a duplicate value exception.
    try {
      upsert uniqueFlightsToUpsert.values() TEDS_Identifier__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert uniqueFlightsToUpsert.values() TEDS_Identifier__c;
      }
    }

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
   * Whether the bookings have at least one flight affected by irregularities
   *
   * @return A map from booking id to whether that booking was affected by irregularities
   */
  public Map<Id, Boolean> haveDelayedOrCancelledFlights() {
    Set<Id> bookingIds = (new Map<Id, Booking__c>(instanceRecords)).keySet();

    Map<Id, Boolean> flightIdToIrrStatus = Flights.newInstance(
        FlightsSelector.newInstance().selectByBookingIds(bookingIds)
      )
      .isDelayedOrCancelled();

    Map<Id, Boolean> toReturn = new Map<Id, Boolean>();
    for (Booking__c booking : instanceRecords) {
      Boolean isAffectedByIrregularity = false;
      for (Segment__c segment : booking.Segments__r) {
        Boolean flightIsDelayedOrCancelled = flightIdToIrrStatus.get(
          segment.Flight__c
        );
        if (flightIsDelayedOrCancelled) {
          isAffectedByIrregularity = true;
          break;
        }
      }
      toReturn.put(booking.Id, isAffectedByIrregularity);
    }

    return toReturn;
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
