global class BookingJSON implements Comparable {
  @AuraEnabled
  public String bookingReference { get; set; }
  @AuraEnabled
  public Boolean isCancelled { get; set; }
  @AuraEnabled
  public String type { get; set; }

  @AuraEnabled
  public List<Flight> flights { get; set; }
  @AuraEnabled
  public List<Passenger> passengers { get; set; }

  global class Flight implements Comparable {
    @AuraEnabled
    public String arrivalAirport { get; set; }
    @AuraEnabled
    public String bookingClass { get; set; }
    @AuraEnabled
    public String departureAirport { get; set; }
    @AuraEnabled
    public String flightNumber { get; set; }
    @AuraEnabled
    public Datetime scheduledArrivalTime { get; set; }
    @AuraEnabled
    public Datetime scheduledDepartureTime { get; set; }

    public Flight(Segment__c s) {
      arrivalAirport = s.Flight__r.Arrival_Airport__c;
      bookingClass = s.Booking_Class__c;
      departureAirport = s.Flight__r.Departure_Airport__c;
      flightNumber = s.Flight__r.TEDS_Identifier__c.substringBefore('-');
      scheduledArrivalTime = s.Flight__r.Scheduled_Arrival_Time__c;
      scheduledDepartureTime = s.Flight__r.Scheduled_Departure_Time__c;
    }

    global Integer compareTo(Object other) {
      BookingJSON.Flight otherFlight = (BookingJSON.Flight) other;

      Integer toReturn = 0;
      if (scheduledDepartureTime > otherFlight.scheduledDepartureTime) {
        toReturn = 1;
      } else if (scheduledDepartureTime < otherFlight.scheduledDepartureTime) {
        toReturn = -1;
      }

      return toReturn;
    }
  }

  global class Passenger implements Comparable {
    @AuraEnabled
    public String euroBonusNumber { get; set; }
    @AuraEnabled
    public String firstName { get; set; }
    @AuraEnabled
    public String identifier { get; set; }
    @AuraEnabled
    public String lastName { get; set; }
    @AuraEnabled
    public List<String> specialServiceRequests { get; set; }

    public Passenger(Passenger__c p, List<String> SSRs) {
      euroBonusNumber = p.EuroBonus_Number__c;
      firstName = p.First_Name__c;
      identifier = p.Identifier__c;
      lastName = p.Last_Name__c;
      specialServiceRequests = SSRs;
    }

    global Integer compareTo(Object other) {
      BookingJSON.Passenger otherPassenger = (BookingJSON.Passenger) other;
      Integer thisOrder = Integer.valueOf(identifier.substringAfter('PT'));
      Integer otherOrder = Integer.valueOf(
        otherPassenger.identifier.substringAfter('PT')
      );

      Integer toReturn = 0;
      if (thisOrder > otherOrder) {
        toReturn = 1;
      } else if (thisOrder < otherOrder) {
        toReturn = -1;
      }

      return toReturn;
    }
  }

  public BookingJSON(Booking__c booking) {
    bookingReference = booking.Booking_Reference__c;
    isCancelled = booking.Is_Cancelled__c;
    type = booking.Type__c;
    List<BookingJSON.Flight> tempFlights = new List<BookingJSON.Flight>();
    List<BookingJSON.Passenger> tempPassengers = new List<BookingJSON.Passenger>();

    Map<String, List<String>> specialServiceRequests = new Map<String, List<String>>();

    String firstPassengerIdHandled;

    // Constructing the flights of this booking from segments.
    // Each passenger has the same flights, so we'll collect flights from only one.
    for (Segment__c s : booking.Segments__r) {
      String segmentId = s.Identifier__c.substringBetween('ST', 'PT');
      String passengerId = s.Identifier__c.substringAfter('PT');

      List<String> existingSSRs = specialServiceRequests.get(passengerId);
      if (existingSSRs == null) {
        specialServiceRequests.put(
          passengerId,
          new List<String>{ s.Special_Service_Requests__c }
        );
      } else {
        existingSSRs.add(s.Special_Service_Requests__c);
        specialServiceRequests.put(passengerId, existingSSRs);
      }

      if (firstPassengerIdHandled == null) {
        firstPassengerIdHandled = passengerId;
        tempFlights.add(new BookingJSON.Flight(s));
      } else if (firstPassengerIdHandled == passengerId) {
        tempFlights.add(new BookingJSON.Flight(s));
      }
    }

    for (Passenger__c p : booking.Passengers__r) {
      tempPassengers.add(
        new BookingJSON.Passenger(
          p,
          specialServiceRequests.get(p.Identifier__c.substringAfter('PT'))
        )
      );
    }

    tempFlights.sort();
    tempPassengers.sort();

    flights = tempFlights;
    passengers = tempPassengers;
  }

  global Integer compareTo(Object other) {
    BookingJSON otherBooking = (BookingJSON) other;

    Integer toReturn = 0;
    if (
      flights[0].scheduledDepartureTime >
      otherBooking.flights[0].scheduledDepartureTime
    ) {
      toReturn = 1;
    } else if (
      flights[0].scheduledDepartureTime <
      otherBooking.flights[0].scheduledDepartureTime
    ) {
      toReturn = -1;
    }

    return toReturn;
  }
}
