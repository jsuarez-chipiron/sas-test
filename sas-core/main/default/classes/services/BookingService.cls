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

  /**
   * Attempts to fetch the given booking from TEDS, and create necessary DB objects. 
   * Does nothing if one isn't found.
   * 
   * @param bookingReference The booking to find.
   * 
   * @throws IntegrationError If there is a problem with the integration.
   */
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
   * Updates existing bookings, creates new ones and removes bookings from SF that don't
   * exist in SF any more.
   *
   * @param euroBonusNumber The EB number to find bookings for.
   */
  @future(callout=true)
  public static void fetchBookingsByEBNumber(String euroBonusNumber) {
    AccountsSelector accounts = (AccountsSelector) SAS_Service_Application.Selector.newInstance(
      Account.SObjectType
    );
    BookingsSelector bookings = (BookingsSelector) SAS_Service_Application.Selector.newInstance(
      Booking__c.SObjectType
    );
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

    List<Account> ebAccount = accounts.selectByEuroBonusNumber(
      new Set<String>{ euroBonusNumber }
    );

    if (ebAccount.size() > 0) {
      // Remove bookings which don't exist in TEDS from SF.
      List<Booking__c> existingBookingsForAccount = bookings.selectByAccountId(
        new Set<Id>{ ebAccount[0].Id }
      );

      for (Booking__c existingBooking : existingBookingsForAccount) {
        Boolean foundInTEDS = false;
        for (Booking__c newBooking : newBookings) {
          if (
            newBooking.TEDS_Identifier__c == existingBooking.TEDS_Identifier__c
          ) {
            foundInTEDS = true;
          }
        }
        if (!foundInTEDS) {
          uow.registerDeleted(existingBooking);
        }
      }
    }

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
    Map<String, Flight__c> flightsProcessed = new Map<String, Flight__c>();

    // Loop through each booking and create all sub objects.
    for (IRR_MOD_TedsBooking booking : bookingData) {
      List<Passenger__c> passengersCreated = new List<Passenger__c>();
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

      // Remove all existing passengers and segments for existing bookings. Reliable updating is impossible.
      if (!isNew) {
        for (Passenger__c existingPassenger : bookingToUpsert.Passengers__r) {
          uow.registerDeleted(existingPassenger);
        }

        for (Segment__c existingSegment : bookingToUpsert.Segments__r) {
          uow.registerDeleted(existingSegment);
        }
      }

      // Create passengers
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

        passengersCreated.add(newPassenger);
        uow.registerNew(newPassenger);
        uow.registerRelationship(
          newPassenger,
          Passenger__c.Booking__c,
          bookingToUpsert
        );
      }

      // Loop through all segments in the trip and create segment and flight objects as necessary
      for (IRR_MOD_TedsBooking.Trip trip : booking.trips) {
        for (IRR_MOD_TedsBooking.SegmentTrip segmentTrip : trip.segments) {
          // Create flights
          Boolean flightNotYetProcessed =
            flightsProcessed.get(segmentTrip.flight.id) == null;

          if (flightNotYetProcessed) {
            Datetime arrivalDate = Datetime.valueOf(
              segmentTrip.flight.arrival.scheduledTime.local.replace('T', ' ')
                .replace('Z', '')
            );
            Datetime departureDate = Datetime.valueOf(
              segmentTrip.flight.departure.scheduledTime.local.replace('T', ' ')
                .replace('Z', '')
            );

            Flight__c flight = flightsAlreadyInSF.get(segmentTrip.flight.id);

            if (flight != null) {
              flight.Arrival_Airport__c = segmentTrip.flight.arrival.station;
              flight.Departure_Airport__c = segmentTrip.flight.departure.station;
              flight.Scheduled_Arrival_Time__c = arrivalDate;
              flight.Scheduled_Departure_Time__c = departureDate;

              flightsProcessed.put(segmentTrip.flight.id, flight);
              uow.registerDirty(flight);
            } else {
              Flight__c newFlight = new Flight__c(
                Name = segmentTrip.flight.id,
                Arrival_Airport__c = segmentTrip.flight.arrival.station,
                Departure_Airport__c = segmentTrip.flight.departure.station,
                Scheduled_Arrival_Time__c = arrivalDate,
                Scheduled_Departure_Time__c = departureDate,
                TEDS_Identifier__c = segmentTrip.flight.id
              );

              flightsProcessed.put(segmentTrip.flight.id, newFlight);
              uow.registerNew(newFlight);
            }
          }

          // Create one segment per passenger per flight in the booking.
          // TODO: Let's see if this works or if we get too much data.
          for (Passenger__c p : passengersCreated) {
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
              Service_Class__c = segmentTrip.serviceClass,
              Special_Service_Requests__c = ssrs,
              Ticket_Number__c = segmentPassenger.ticket == null
                ? ''
                : segmentPassenger.ticket.number_x,
              Ticket_Type__c = segmentPassenger.ticket == null
                ? ''
                : segmentPassenger.ticket.type
            );
            uow.registerNew(newSegment);
            uow.registerRelationship(
              newSegment,
              Segment__c.Booking__c,
              bookingToUpsert
            );
            uow.registerRelationship(
              newSegment,
              Segment__c.Flight__c,
              flightsProcessed.get(segmentTrip.flight.id)
            );
          }
        }
      }
    }

    return bookingsToReturn;
  }
}