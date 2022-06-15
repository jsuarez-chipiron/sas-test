/**
 * Service for fetching booking and flight data from the TEDS API.
 *
 * For the time being this duplicates some functionality from the IRR TEDS integration code.
 * This is intentional to not couple the teams' workflows. Let's look into a way to merge
 * these in future.
 *
 * For more information see:
 *   https://sas-digital.atlassian.net/wiki/spaces/CSSolutions/pages/2342289428/Planned%2BTEDS%2BAPI
 */
public without sharing class TEDSIntegrationService {
  private static final String API_PATH = 'callout:SAS_APIM_TEDS_FCS';
  private static final String SUBSCRIPTION_KEY = Test.isRunningTest()
    ? 'TESTKEY'
    : C_Settings.getSettings('APIM').get('APIM_TEDS_Subscription_Key');

  public static TEDSIntegrationService newInstance() {
    return (TEDSIntegrationService) SAS_Service_Application.Service.newInstance(
      TEDSIntegrationService.class
    );
  }

  /**
   * Query definition for searching bookings. Any fields can be set and query
   * will be combined with AND logic.
   */
  public class BookingsQuery extends APIMIntegrationService.BaseQuery {
    // return bookings that have a flight arriving to the station.
    public String arrivalStation { get; set; }
    // return bookings with the specified print status for boarding pass. NRP = needs print
    public String boardingPassPrintStatus { get; set; }
    // the CMP (Company) of the bookings to return
    public String cmp { get; set; }
    // format - date-time (as date-time in RFC3339). The earliest creation time in UTC.
    public String createdFromTimeUTC { get; set; }
    // format - date-time (as date-time in RFC3339). The latest creation time in UTC.
    public String createdToTimeUTC { get; set; }
    // list with the office ids that have created the bookings that should be returned
    public Set<String> creationOffices { get; set; }
    // the cods ID of the bookings to return
    public String codsId { get; set; }
    // return bookings that have a flight departing from the station
    public String departureStation { get; set; }
    // the eurobonus number of the bookings to return
    public String euroBonusNumber { get; set; }
    // the flight ID of the bookings to return
    public String flightId { get; set; }
    // format - date-time (as date-time in RFC3339). return bookings that have a flight departing or arriving from that time in UTC
    public String fromTimeUTC { get; set; }
    // return bookings that are Cancelled
    public String isCancelled { get; set; }
    // the booking reference of the bookings to return
    public String reference { get; set; }
    // return bookings that are Active or Passed
    public String status { get; set; }
    // the ticket number of the bookings to return
    public String ticketNumber { get; set; }
    // the travel admin cods ID of the bookings to return
    public String travelAdminCodsId { get; set; }
    // format - date-time (as date-time in RFC3339). return bookings that have a flight departing or arriving to that time in UTC
    public String toTimeUTC { get; set; }

    public override String toQueryParamString() {
      String toReturn = '';
      Boolean isFirst = true;

      if (arrivalStation != null) {
        toReturn += addField(isFirst, 'arrivalStation', arrivalStation);
      }
      if (boardingPassPrintStatus != null) {
        toReturn += addField(
          isFirst,
          'boardingPassPrintStatus',
          boardingPassPrintStatus
        );
      }
      if (cmp != null) {
        toReturn += addField(isFirst, 'cmp', cmp);
      }
      if (createdFromTimeUTC != null) {
        toReturn += addField(isFirst, 'createdFromTimeUTC', createdFromTimeUTC);
      }
      if (createdToTimeUTC != null) {
        toReturn += addField(isFirst, 'createdToTimeUTC', createdToTimeUTC);
      }
      if (codsId != null) {
        toReturn += addField(isFirst, 'codsId', codsId);
      }
      if (departureStation != null) {
        toReturn += addField(isFirst, 'departureStation', departureStation);
      }
      if (euroBonusNumber != null) {
        toReturn += addField(isFirst, 'euroBonusNumber', euroBonusNumber);
      }
      if (flightId != null) {
        toReturn += addField(isFirst, 'flightId', flightId);
      }
      if (fromTimeUTC != null) {
        toReturn += addField(isFirst, 'fromTimeUTC', fromTimeUTC);
      }
      if (isCancelled != null) {
        toReturn += addField(isFirst, 'isCancelled', isCancelled);
      }
      if (reference != null) {
        if (!Bookings.isValidBookingReference(reference)) {
          throw new APIMIntegrationService.IllegalArgumentsException(
            'Booking reference must be 5 or 6 characters'
          );
        }
        toReturn += addField(isFirst, 'reference', reference);
      }
      if (status != null) {
        toReturn += addField(isFirst, 'status', status);
      }
      if (ticketNumber != null) {
        toReturn += addField(isFirst, 'ticketNumber', ticketNumber);
      }
      if (travelAdminCodsId != null) {
        toReturn += addField(isFirst, 'travelAdminCodsId', travelAdminCodsId);
      }
      if (toTimeUTC != null) {
        toReturn += addField(isFirst, 'toTimeUTC', toTimeUTC);
      }
      if (creationOffices != null && !creationOffices.isEmpty()) {
        toReturn += this.addField(
          isFirst,
          'creationOffices',
          String.join(new List<String>(creationOffices), ',')
        );
      }
      return toReturn;
    }
  }

  public class FlightsQuery extends APIMIntegrationService.BaseQuery {
    public String aircraftRegistration { get; set; }
    public String arrivalStation { get; set; }
    public String callSign { get; set; }
    public String departureDate { get; set; }
    public String departureStation { get; set; }
    public String flightNumber { get; set; }
    public Set<String> ids { get; set; }

    public override String toQueryParamString() {
      String toReturn = '';
      Boolean isFirst = true;

      if (aircraftRegistration != null) {
        toReturn += addField(
          isFirst,
          'aircraftRegistration',
          aircraftRegistration
        );
      }
      if (arrivalStation != null) {
        toReturn += this.addField(isFirst, 'arrivalStation', arrivalStation);
      }
      if (callSign != null) {
        toReturn += this.addField(isFirst, 'callSign', callSign);
      }
      if (departureDate != null) {
        toReturn += this.addField(isFirst, 'departureDate', departureDate);
      }
      if (departureStation != null) {
        toReturn += this.addField(
          isFirst,
          'departureStation',
          departureStation
        );
      }
      if (flightNumber != null) {
        toReturn += this.addField(isFirst, 'flightNumber', flightNumber);
      }
      if (ids != null && !ids.isEmpty()) {
        if (ids.size() > 10) {
          throw new APIMIntegrationService.IllegalArgumentsException(
            'We can only search for maximum of 10 flights at a time.'
          );
        }
        toReturn += this.addField(
          isFirst,
          'ids',
          String.join(new List<String>(ids), ',')
        );
      }

      return toReturn;
    }
  }

  /** Fetches a single booking from TEDS based on the booking identifier.
   *
   * @param bookingIdentifier Full booking identifier in format {PNR}-{creationDate}. E.g. ABC123-20220506
   *
   * @return The parsed booking data as IRR_MOD_TedsBooking if one was found, null otherwise.
   */
  public IRR_MOD_TedsBooking fetchBookingByBookingIdentifier(
    String bookingIdentifier
  ) {
    HttpResponse response = makeRequest(
      '/teds-booking/bookings/' + bookingIdentifier,
      null
    );

    if (response.getStatusCode() == 404) {
      return null;
    }

    return IRR_MOD_TedsBooking.parse(response.getBody());
  }

  /** Fetches all bookings from TEDS which match the provided query.
   *
   * @param query Query to execute.
   *
   * @return List of the found bookings, or an empty list of none were found.
   */
  public List<IRR_MOD_TedsBooking> fetchBookingsByQuery(BookingsQuery query) {
    HttpResponse response = makeRequest('/teds-booking/bookings', query);

    return IRR_MOD_TedsBooking.parseArray(response.getBody());
  }

  /** Fetches all flights from TEDS which match the provided query.
   *
   * @param query Query to execute.
   *
   * @return List of the found flights, or an empty list of none were found.
   */
  public List<TEDSFlight> fetchFlightsByQuery(FlightsQuery query) {
    // TODO: Map<String, String>
    HttpResponse response = makeRequest('/teds-flight/flights', query);

    return TEDSFlight.parseArray(response.getBody());
  }

  /**
   * Constructs and fires a request to the TEDS API.
   *
   * Fills in authentication and tracing headers.
   *
   * @param method HTTP method to use as full caps String. See HttpRequest.setMethod for more info.
   * @param path The path to make the query to.
   * @param queryParams Query parameters as map of name to value.
   *
   * @throws IntegrationException On HTTP status codes larger than 400.
   *
   * @return Response object from making the query.
   */
  private HttpResponse makeRequest(
    String path,
    APIMIntegrationService.BaseQuery query
  ) {
    HttpRequest request = new HttpRequest();

    String fullPath = API_PATH + path;

    if (query != null) {
      fullPath += query.toQueryParamString();
    }

    Map<String, String> extraRequestHeaders = new Map<String, String>{
      'api-version' => 'v2',
      'Ocp-Apim-Subscription-Key' => SUBSCRIPTION_KEY
    };

    return APIMIntegrationService.makeRequest(
      HttpUtils.HTTP_METHOD.GET,
      fullPath,
      null,
      extraRequestHeaders
    );
  }
}
