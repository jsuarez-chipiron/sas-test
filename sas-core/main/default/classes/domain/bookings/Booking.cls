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

  public List<Flight> flights {
    get {
      if (this.segments == null) {
        return null;
      }
      List<Flight> toReturn = new List<Flight>();

      for (Segment s : this.segments) {
        if (s.flight != null) {
          toReturn.add(s.flight);
        }
      }

      return toReturn;
    }
  }

  public class MissingDataException extends Exception {
  }

  public enum Type {
    DayReturn,
    MultiCity,
    OneWay,
    RoundTrip,
    Unknown
  }

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
    return Trip.createFromBooking(this);
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
}