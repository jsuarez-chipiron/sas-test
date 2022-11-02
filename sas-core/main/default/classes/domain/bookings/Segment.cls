public without sharing class Segment extends AbstractSObjectWrapper implements Comparable {
  public Segment__c underlyingSObject { get; private set; }

  public Id bookingId;
  public Id flightId;

  public Decimal baggageQuantity;
  public String bookingClass;
  public String checkInStatus;
  public String fareBasis;
  public Decimal farePrice;
  public String identifier;
  public Boolean isBoarded = false;
  public String seat;
  public String segmentStatus;
  public String segmentStatusCode;
  public String serviceClass;
  public String specialServiceRequests;
  public String ticketNumber;
  public String ticketType;
  public String tripType;

  public Flight flight;

  public List<SegmentEvent> events; // Todo: handle initialization

  private Segment() {
    this.underlyingSObject = new Segment__c();
  }

  public Segment(Segment__c s) {
    super(s);
    this.underlyingSObject = s;

    this.bookingId = s.Booking__c;
    this.flightId = s.Flight__c;
    this.baggageQuantity = s.Baggage_Quantity__c;
    this.bookingClass = s.Booking_Class__c;
    this.checkInStatus = s.Check_In_Status__c;
    this.fareBasis = s.Fare_Basis__c;
    this.farePrice = s.Fare_Price__c;
    this.identifier = s.Identifier__c;
    this.isBoarded = s.Is_Boarded__c;
    this.seat = s.Seat__c;
    this.segmentStatus = s.Segment_Status__c;
    this.segmentStatusCode = s.Segment_Status_Code__c;
    this.serviceClass = s.Service_Class__c;
    this.specialServiceRequests = s.Special_Service_Requests__c;
    this.ticketNumber = s.Ticket_Number__c;
    this.ticketType = s.Ticket_Type__c;
    this.tripType = s.Trip_Type__c;

    if (s.Flight__r != null) {
      this.flight = new Flight(s.Flight__r);
    }
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Baggage_Quantity__c = this.baggageQuantity;
    this.underlyingSObject.Booking__c = this.bookingId;
    this.underlyingSObject.Booking_Class__c = this.bookingClass;
    this.underlyingSObject.Check_In_Status__c = this.checkInStatus;
    this.underlyingSObject.Fare_Basis__c = this.fareBasis;
    this.underlyingSObject.Fare_Price__c = this.farePrice;
    this.underlyingSObject.Flight__c = this.flightId;
    this.underlyingSObject.Identifier__c = this.identifier;
    this.underlyingSObject.Is_Boarded__c = this.isBoarded;
    this.underlyingSObject.Seat__c = this.seat;
    this.underlyingSObject.Segment_Status__c = this.segmentStatus;
    this.underlyingSObject.Segment_Status_Code__c = this.segmentStatusCode;
    this.underlyingSObject.Service_Class__c = this.serviceClass;
    this.underlyingSObject.Special_Service_Requests__c = this.specialServiceRequests;
    this.underlyingSObject.Ticket_Number__c = this.ticketNumber;
    this.underlyingSObject.Ticket_Type__c = this.ticketType;
    this.underlyingSObject.Trip_Type__c = this.tripType;
  }

  public Integer compareTo(Object other) {
    Segment otherSegment = (Segment) other;

    Integer toReturn = 0;

    if (other == null) {
      return 1;
    }

    if (this.flight == null || otherSegment.flight == null) {
      return 0;
    }

    if (
      this.flight.scheduledDepartureTime >
      otherSegment.flight.scheduledDepartureTime
    ) {
      return 1;
    } else if (
      this.flight.scheduledDepartureTime <
      otherSegment.flight.scheduledDepartureTime
    ) {
      return -1;
    } else {
      return 0;
    }
  }

  public Boolean isActive(Datetime theTime) {
    events.sort();
    Boolean confirmed = false;
    for (SegmentEvent se : events) {
      if (se.updateDate > theTime) {
        break;
      }
      SegmentEvent.StatusCode newStatus = SegmentEvent.STATUS_PICKLIST_VALUE_TO_ENUM.get(
        se.newStatus
      );
      if (newStatus == SegmentEvent.StatusCode.C_HK) {
        // Holds confirmed
        confirmed = true;
      }
      if (newStatus == SegmentEvent.StatusCode.C_UN) {
        // Unable - no flight
        return false;
      }
    }
    return confirmed;
  }

  public Boolean isActive() {
    events.sort();
    Boolean confirmed = false;
    for (SegmentEvent se : events) {
      SegmentEvent.StatusCode newStatus = SegmentEvent.STATUS_PICKLIST_VALUE_TO_ENUM.get(
        se.newStatus
      );
      if (newStatus == SegmentEvent.StatusCode.C_HK) {
        // Holds confirmed
        confirmed = true;
      }
      if (newStatus == SegmentEvent.StatusCode.C_UN) {
        // Unable - no flight
        return false;
      }
    }
    return confirmed;
  }
}
