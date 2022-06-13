public with sharing class FlightDelayCertificateController {
  public List<FlightWrapper> flightWrappers { get; set; }
  public String enteredFlight { get; set; }
  public String bookingReference { get; set; }
  public String passengerName { get; set; }
  public String caseNumber { get; set; }
  public String imageLink { get; set; }

  public FlightDelayCertificateController() {
    Id bookingId = ApexPages.currentPage().getParameters().get('bookingId') !=
      null
      ? Id.valueOf(ApexPages.currentPage().getParameters().get('bookingId'))
      : null;
    enteredFlight = ApexPages.currentPage()
      .getParameters()
      .get('enteredFlight');
    passengerName = ApexPages.currentPage()
      .getParameters()
      .get('passengerName');
    bookingReference = ApexPages.currentPage()
      .getParameters()
      .get('bookingReference');
    caseNumber = ApexPages.currentPage().getParameters().get('caseNumber');

    imageLink =
      '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' +
      ContentVersionsSelector.newInstance().selectByTitle('SAS-Logo_B3_RGB')[0]
        ?.Id;

    flightWrappers = new List<FlightWrapper>();
    if (bookingId != null) {
      List<Flight__c> flightsInBooking = FlightsSelector.newInstance()
        .selectByBookingIds(new Set<Id>{ bookingId });
      for (Flight__c flight : flightsInBooking) {
        String flightId = flight.TEDS_Identifier__c.substringBefore('-');
        FlightWrapper fw = new FlightWrapper();
        fw.ScheduledTimeOfDeparture = flight.Scheduled_Departure_Time__c
          ?.format('yyyy-MM-dd HH:mm');
        fw.ScheduledTimeOfArrival = flight.Scheduled_Arrival_Time__c
          ?.format('yyyy-MM-dd HH:mm');
        fw.ActualTimeOfArrival = flight.Actual_Arrival_Time__c
          ?.format('yyyy-MM-dd HH:mm');
        fw.FlightNumber = flightId;
        fw.FlightDate = flight.TEDS_Identifier__c?.substring(6, 14);
        fw.ArrivalAirport = flight.Arrival_Airport__c;
        fw.DepartureAirport = flight.Departure_Airport__c;
        fw.FlightStatus = flight.Departure_Status__c;
        flightWrappers.add(fw);
      }
    }
  }

  /**
   * Wrapper class needed to retrieve flight data in the Visualforce page
   * Data is retrieved on the page by calling the getter as a property
   */
  public class FlightWrapper {
    public String ScheduledTimeOfDeparture { get; set; }
    public String ScheduledTimeOfArrival { get; set; }
    public String ActualTimeOfArrival { get; set; }
    public String FlightNumber { get; set; }
    public String FlightDate { get; set; }
    public String ArrivalAirport { get; set; }
    public String DepartureAirport { get; set; }
    public String FlightStatus { get; set; }
  }
}
