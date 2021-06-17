/**
 * Service class for managing bookings and flights in Salesforce.
 */
public with sharing class BookingService {
  /**
   * Adds a booking to the case. If necessary booking or flight objects do not exist
   * in Salesforce, attempts to fetch them from TEDS and commit to SF DB.
   *
   * @param caseId The case to which the booking should be added.
   * @param bookingReference The 6 character code of the booking.
   *
   * @return True if booking was added to case, false if adding failed.
   */
  public static void addBookingToCase(ID caseId, String bookingReference) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
      Booking__c.SObjectType
    );
    TEDSIntegrationService TEDSService = (TEDSIntegrationService) SAS_Service_Application.Service.newInstance(
      TEDSIntegrationService.class
    );

    List<Booking__c> bookingsFoundInSf = bookings.selectByBookingReference(
      bookingReference
    );

    if (bookingsFoundInSf.isEmpty() /* TODO: Or timestamp > something*/) {
      // Booking not in SF so let's check TEDS.
      IRR_MOD_TedsBooking bookingData = TEDSService.fetchBookingByReference(
        bookingReference
      );

      if (bookingData == null) {
        // Not found in TEDS either. Booking reference doesn't exist in recent flight data (3 months or so).
        // TODO: Check EDW when an integration exists.
        return;
      }

      Booking__c newBooking = constructBookingsForDB(bookingData, uow);

      CaseToBooking__c newJoin = new CaseToBooking__c(Case__c = caseId);
      uow.registerNew(newJoin);
      uow.registerRelationship(
        newJoin,
        CaseToBooking__c.Booking__c,
        newBooking
      );
    } else {
      CaseToBooking__c newJoin = new CaseToBooking__c(
        Booking__c = bookingsFoundInSf[0].Id,
        Case__c = caseId
      );
      uow.registerNew(newJoin);
    }

    uow.commitWork();
    return;
  }

  @future(callout=true)
  public static void fetchBookingByBookingReference(String bookingReference) {
    TEDSIntegrationService TEDSService = (TEDSIntegrationService) SAS_Service_Application.Service.newInstance(
      TEDSIntegrationService.class
    );

    IRR_MOD_TedsBooking bookingData = TEDSService.fetchBookingByReference(
      bookingReference
    );

    if (bookingData == null) {
      // Not found in TEDS either. Booking reference doesn't exist in recent flight data (3 months or so).
      // TODO: Check EDW when an integration exists.
      return;
    }

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Booking__c newBooking = constructBookingsForDB(bookingData, uow);
    uow.commitWork();
  }

  /**
   * Fetches all bookings related to an EB customer from TEDS and inserts them into SF DB.
   *
   * Updates existing bookings and creates new ones.
   *
   * @param euroBonusNumber The EB number to find bookings for.
   *
   * @return The list of created bookings.
   */
  @future(callout=true)
  public static void fetchBookingsByEBNumber(String euroBonusNumber) {
    TEDSIntegrationService TEDSService = (TEDSIntegrationService) SAS_Service_Application.Service.newInstance(
      TEDSIntegrationService.class
    );

    Map<String, String> query = new Map<String, String>();
    query.put('euroBonusNumber', euroBonusNumber);
    List<IRR_MOD_TedsBooking> bookingData = TEDSService.fetchBookingsByQuery(
      query
    );

    if (bookingData.size() == 0) {
      return;
    }

    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    List<Booking__c> newBookings = constructBookingsForDB(bookingData, uow);
    uow.commitWork();
  }

  /**
   * Parses booking data in IRR_MOD_TedsBooking format into DB objects and prepares them for DB insertion.
   *
   * @param bookingData A single IRR_MOD_TedsBooking object containing booking to create.
   * @param uow Unit of work transaction in which the booking should be committed. Must be committed by caller.
   *
   * @return The created Booking__c object.
   */
  private static Booking__c constructBookingsForDB(
    IRR_MOD_TedsBooking bookingData,
    fflib_ISObjectUnitOfWork uow
  ) {
    return constructBookingsForDB(
      new List<IRR_MOD_TedsBooking>{ bookingData },
      uow
    )[0];
  }
  /**
   * Parses booking data in IRR_MOD_TedsBooking format into DB objects and prepares them for DB insertion.
   *
   *
   *
   * @param bookingData List of IRR_MOD_TedsBooking objects containing bookings to create.
   * @param uow Unit of work transaction in which the booking should be committed. Must be committed by caller.
   *
   * @return The list of created Booking__c objects.
   */
  private static List<Booking__c> constructBookingsForDB(
    List<IRR_MOD_TedsBooking> bookingData,
    fflib_ISObjectUnitOfWork uow
  ) {
    FlightsSelector flights = (FlightsSelector) SAS_Service_Application.Selector.newInstance(
      Flight__c.SObjectType
    );
    BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
      Booking__c.SObjectType
    );

    // Figure out all flights which are referenced within bookingData, and fetch all which already exist in SF DB.
    Set<String> flightsInBookings = new Set<String>();
    Set<String> bookingIds = new Set<String>();

    for (IRR_MOD_TedsBooking booking : bookingData) {
      for (IRR_MOD_TedsBooking.Trip trip : booking.trips) {
        for (IRR_MOD_TedsBooking.SegmentTrip segmentTrip : trip.segments) {
          flightsInBookings.add(segmentTrip.flight.id);
        }
      }
      bookingIds.add(booking.id);
    }

    List<Flight__c> flightsFromDB = flights.selectByTEDSId(flightsInBookings);
    List<Booking__c> bookingsFromDB = bookings.selectByTEDSIdFull(bookingIds);

    Map<String, Flight__c> flightsAlreadyInSF = new Map<String, Flight__c>();
    for (Flight__c f : flightsFromDB) {
      flightsAlreadyInSF.put(f.TEDS_Identifier__c, f);
    }

    Map<String, Booking__c> bookingsAlreadyInSF = new Map<String, Booking__c>();
    for (Booking__c f : bookingsFromDB) {
      bookingsAlreadyInSF.put(f.TEDS_Identifier__c, f);
    }

    List<Booking__c> bookingsToReturn = new List<Booking__c>();
    Map<String, Flight__c> flightsCreated = new Map<String, Flight__c>();
    // Loop through each booking and create all sub objects.
    for (IRR_MOD_TedsBooking booking : bookingData) {
      Booking__c bookingToUpsert = bookingsAlreadyInSF.get(booking.id);
      Boolean isNew = true;
      if (bookingToUpsert == null) {
        bookingToUpsert = new Booking__c(
          Booking_Reference__c = booking.reference,
          Name = booking.id,
          TEDS_Identifier__c = booking.id,
          Type__c = booking.type,
          Is_Cancelled__c = booking.isCancelled
        );
        uow.registerNew(bookingToUpsert);
      } else {
        isNew = false;
        bookingToUpsert.Type__c = booking.type;
        bookingToUpsert.Is_Cancelled__c = booking.isCancelled;
        uow.registerDirty(bookingToUpsert);
      }

      bookingsToReturn.add(bookingToUpsert);

      // Create passengers
      if (isNew) {
        for (IRR_MOD_TedsBooking.Passenger p : booking.passengers) {
          Passenger__c newPassenger = new Passenger__c(
            Booking__c = bookingToUpsert.id,
            First_Name__c = p.firstName,
            Identifier__c = p.id,
            Last_Name__c = p.lastName
          );
          if (p.frequentTraveler.euroBonus.size() > 0) {
            newPassenger.EuroBonus_Number__c = p.frequentTraveler.euroBonus[0]
              .number_x;
          }
          uow.registerNew(newPassenger);
          uow.registerRelationship(
            newPassenger,
            Passenger__c.Booking__c,
            bookingToUpsert
          );
        }
      } else {
        for (Passenger__c existingPassenger : bookingToUpsert.Passengers__r) {
          Boolean foundInNewBooking = false;
          for (IRR_MOD_TedsBooking.Passenger p : booking.passengers) {
            if (existingPassenger.Identifier__c == p.id) {
              existingPassenger.First_Name__c = p.firstName;
              existingPassenger.Last_Name__c = p.lastName;

              if (p.frequentTraveler.euroBonus.size() > 0) {
                existingPassenger.EuroBonus_Number__c = p.frequentTraveler.euroBonus[0]
                  .number_x;
              } else {
                existingPassenger.EuroBonus_Number__c = '';
              }

              uow.registerDirty(existingPassenger);
            }
          }
          if (!foundInNewBooking) {
            uow.registerDeleted(existingPassenger);
          }
        }
      }

      if (!isNew) {
        for (Segment__c existingSegment : bookingToUpsert.Segments__r) {
          uow.registerDeleted(existingSegment);
        }
      }

      // Loop through all segments in the trip and create segment and flight objects as necessary
      for (IRR_MOD_TedsBooking.Trip trip : booking.trips) {
        for (IRR_MOD_TedsBooking.SegmentTrip segmentTrip : trip.segments) {
          // Create segments
          // TODO: FIXME: Create segment per passenger flight.
          Segment__c newSegment = new Segment__c(
            Identifier__c = segmentTrip.id,
            Name = segmentTrip.flight.id
          );
          uow.registerNew(newSegment);
          uow.registerRelationship(
            newSegment,
            Segment__c.Booking__c,
            bookingToUpsert
          );

          // Create flights
          Flight__c flight = flightsAlreadyInSF.get(segmentTrip.flight.id);

          if (flight != null) {
            Datetime arrivalDate = Datetime.valueOf(
              segmentTrip.flight.arrival.scheduledTime.local.replace('T', ' ')
                .replace('Z', '')
            );
            Datetime departureDate = Datetime.valueOf(
              segmentTrip.flight.departure.scheduledTime.local.replace('T', ' ')
                .replace('Z', '')
            );

            flight.Arrival_Airport__c = segmentTrip.flight.arrival.station;
            flight.Departure_Airport__c = segmentTrip.flight.departure.station;
            flight.Scheduled_Arrival_Time__c = arrivalDate;
            flight.Scheduled_Departure_Time__c = departureDate;

            uow.registerDirty(flight);
            uow.registerRelationship(newSegment, Segment__c.Flight__c, flight);
          } else if (flightsCreated.get(segmentTrip.flight.id) == null) {
            Datetime arrivalDate = Datetime.valueOf(
              segmentTrip.flight.arrival.scheduledTime.local.replace('T', ' ')
                .replace('Z', '')
            );
            Datetime departureDate = Datetime.valueOf(
              segmentTrip.flight.departure.scheduledTime.local.replace('T', ' ')
                .replace('Z', '')
            );

            Flight__c newFlight = new Flight__c(
              Name = segmentTrip.flight.id,
              Arrival_Airport__c = segmentTrip.flight.arrival.station,
              Departure_Airport__c = segmentTrip.flight.departure.station,
              Scheduled_Arrival_Time__c = arrivalDate,
              Scheduled_Departure_Time__c = departureDate,
              TEDS_Identifier__c = segmentTrip.flight.id
            );

            flightsCreated.put(segmentTrip.flight.id, newFlight);

            uow.registerNew(newFlight);
            uow.registerRelationship(
              newSegment,
              Segment__c.Flight__c,
              newFlight
            );
          } else {
            uow.registerRelationship(
              newSegment,
              Segment__c.Flight__c,
              flightsCreated.get(segmentTrip.flight.id)
            );
          }
        }
      }
    }

    return bookingsToReturn;
  }
}
