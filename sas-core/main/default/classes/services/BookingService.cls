public without sharing class BookingService {
  public static BookingService newInstance() {
    return (BookingService) SAS_Service_Application.Service.newInstance(
      BookingService.class
    );
  }

  public class IllegalArgumentsException extends Exception {
  }

  /**
   * Adds a booking to the case. If necessary booking or flight objects do not exist
   * in Salesforce, attempts to fetch them from TEDS and commit to SF DB.
   *
   * Also fetches detailed flight information from the TEDS Flights API for the
   * flights in the booking.
   *
   * @param caseId The case to which the booking should be added.
   * @param bookingReference The 6 character code of the booking.
   * @return The bookings object representing the booking, or null if none could be found.
   *
   */
  public static Bookings addBookingToCase(ID caseId, String bookingReference) {
    if (caseId == null) {
      throw new IllegalArgumentsException('caseId cannot be null.');
    }

    TEDSIntegrationService.BookingsQuery query = new TEDSIntegrationService.BookingsQuery();
    query.reference = bookingReference;

    Bookings newBookings = fetchBookingsByQuery(query);

    if (newBookings == null) {
      return null;
    }

    List<CaseToBooking__c> caseToBooking = CaseToBookingsSelector.newInstance()
      .selectByCaseIdAndBookingReference(caseId, bookingReference);

    if (caseToBooking.isEmpty()) {
      // Add case to booking only if the lookup doesn't exist yet.
      CaseToBooking__c newJoin = new CaseToBooking__c(
        Booking__c = newBookings.instanceRecords[0].Id, // FIXME: we now always use the first one. Users should get a choice instead.
        Case__c = caseId
      );
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      uow.registerNew(newJoin);
      uow.commitWork();
    }

    return newBookings;
  }

  /**
   * Removes a booking from a case. I.e. removes the CaseToBooking
   * junction object linking the referenced case and a booking.
   *
   * @param caseId The case from which a booking should be removed.
   * @param bookingReference The 6 character code of the booking.
   *
   */
  public static void removeBookingFromCase(ID caseId, String bookingReference) {
    List<CaseToBooking__c> caseToBooking = CaseToBookingsSelector.newInstance()
      .selectByCaseIdAndBookingReference(caseId, bookingReference);

    if (!caseToBooking.isEmpty()) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      uow.registerDeleted(caseToBooking);
      uow.commitWork();
    }
  }

  /**
   * Attempts to fetch the given booking from TEDS, and create necessary DB objects.
   * Does nothing if one isn't found.
   *
   * @param bookingIdentifier The booking to find. {PNR}-{creationDate}
   *
   * @throws IntegrationError If there is a problem with the integration.
   */
  public static Bookings fetchBookingByBookingIdentifier(
    String bookingIdentifier
  ) {
    IRR_MOD_TedsBooking bookingData = TEDSIntegrationService.newInstance()
      .fetchBookingByBookingIdentifier(bookingIdentifier);

    if (bookingData == null) {
      // Not found in TEDS either. Booking reference doesn't exist in recent flight data (3 months or so).
      // TODO: Check EDW when an integration exists.
      return null;
    }

    Bookings newBookings = Bookings.createFromTEDSData(
      new List<IRR_MOD_TedsBooking>{ bookingData }
    );

    Set<String> flightIdsForBookings = new Set<String>();

    for (Bookings.FullBookingData fbd : newBookings.fullRecords) {
      for (Flight__c flight : fbd.flights) {
        flightIdsForBookings.add(flight.TEDS_Identifier__c);
      }
    }

    if (flightIdsForBookings.size() > 0) {
      Flights newFlights = FlightService.newInstance()
        .fetchFlightsByReference(flightIdsForBookings, false);
      newBookings.upsertToDB();
      if (newFlights != null) {
        newFlights.upsertToDB();
      }
    } else {
      newBookings.upsertToDB();
    }

    return newBookings;
  }

  /**
   * Fetches all bookings related to an EB customer from TEDS and inserts them into SF DB.
   *
   * Updates existing bookings, creates new ones and removes bookings from SF that don't
   * exist in SF any more.
   *
   * @param euroBonusNumber The EB number to find bookings for.
   */
  public static Bookings fetchBookingsByEBNumber(String euroBonusNumber) {
    TEDSIntegrationService.BookingsQuery query = new TEDSIntegrationService.BookingsQuery();
    query.euroBonusNumber = euroBonusNumber;
    return fetchBookingsByQuery(query);
  }

  /**
   *
   */
  public class AddBookingToCaseAsync implements Queueable, Database.AllowsCallouts {
    private Id caseId;
    private String bookingReference;
    public AddBookingToCaseAsync(Id caseId, String bookingReference) {
      this.caseId = caseId;
      this.bookingReference = bookingReference;
    }
    public void execute(QueueableContext ctx) {
      try {
        addBookingToCase(this.caseId, this.bookingReference);
      } catch (IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      } catch (APIMIntegrationService.IllegalArgumentsException e) {
        // Invalid PNR or caseId, most likely due to user error. We can't do
        // anything about these in the async flow.
      }
    }
  }

  public class FetchBookingsByEBNumberAsync implements Queueable, Database.AllowsCallouts {
    private String euroBonusNumber;
    public FetchBookingsByEBNumberAsync(String euroBonusNumber) {
      this.euroBonusNumber = euroBonusNumber;
    }
    public void execute(QueueableContext ctx) {
      fetchBookingsByEBNumber(this.euroBonusNumber);
    }
  }

  public static Bookings fetchBookingsByQuery(
    TEDSIntegrationService.BookingsQuery query
  ) {
    List<IRR_MOD_TedsBooking> bookingData = TEDSIntegrationService.newInstance()
      .fetchBookingsByQuery(query);

    if (bookingData == null || bookingData.size() == 0) {
      // Not found in TEDS. Booking reference doesn't exist in recent flight data (6 months or so).
      // TODO: Check EDW when an integration exists.
      return null;
    }

    Bookings newBookings = Bookings.createFromTEDSData(bookingData);

    if (newBookings != null) {
      List<Flights> newFlights = new List<Flights>();

      Set<String> flightIds = new Set<String>();

      for (Bookings.FullBookingData fbd : newBookings.fullRecords) {
        for (Flight__c flight : fbd.flights) {
          flightIds.add(flight.TEDS_Identifier__c);
        }
      }

      if (flightIds.size() > 0) {
        if (flightIds.size() <= 10) {
          newFlights.add(
            FlightService.newInstance()
              .fetchFlightsByReference(flightIds, false)
          );
        } else {
          // We can only search 10 flights at a time so let's bunch these up.
          final Integer ITEMS_IN_BUCKET = 10;
          List<Set<String>> bucketedFlights = new List<Set<String>>();

          for (Integer i = 0; i < flightIds.size(); i = i + ITEMS_IN_BUCKET) {
            bucketedFlights.add(new Set<String>());
          }
          Integer count = 0;

          for (String flightIdentifier : flightIds) {
            Integer bucket = count / ITEMS_IN_BUCKET;
            bucketedFlights[bucket].add(flightIdentifier);

            count++;
          }

          for (Set<String> bucket : bucketedFlights) {
            newFlights.add(
              FlightService.newInstance().fetchFlightsByReference(bucket, false)
            );
          }
        }
      }

      newBookings.upsertToDB();

      for (Flights f : newFlights) {
        // DML in a loop, but there really shouldn't be too many of these as
        // each instance holds 10 flights.
        if (f != null) {
          f.upsertToDB();
        }
      }
    }

    return newBookings;
  }
}
