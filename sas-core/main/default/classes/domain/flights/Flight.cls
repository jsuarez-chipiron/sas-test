public without sharing class Flight extends AbstractSObjectWrapper {
  public Flight__c underlyingSObject { get; private set; }

  public String tedsIdentifier;
  public String operationalControlCenter;
  public String aircraftRegistration;

  public String arrivalAirport;
  public Decimal arrivalDelayedMinutes;
  public String arrivalGate;
  public Status arrivalStatus;
  public String arrivalTerminal;

  public String departureAirport;
  public Decimal departureDelayedMinutes;
  public String departureGate;
  public Status departureStatus;
  public String departureTerminal;

  public DateTime actualArrivalTime;
  public String actualArrivalTimeLocal;
  public DateTime actualDepartureTime;
  public String actualDepartureTimeLocal;

  public DateTime estimatedArrivalTime;
  public String estimatedArrivalTimeLocal;
  public DateTime estimatedDepartureTime;
  public String estimatedDepartureTimeLocal;

  public DateTime scheduledArrivalTime;
  public String scheduledArrivalTimeLocal;
  public DateTime scheduledDepartureTime;
  public String scheduledDepartureTimeLocal;

  public Airport departureAirportObject;
  public Airport arrivalAirportObject;

  public String operatingCarrier;

  public List<FlightIrregularity> irregularities;

  public enum Status {
    Ontime,
    Delayed,
    Cancelled,
    Unknown
  }

  public class FlightException extends Exception {
  }

  private static final Map<String, Status> STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, Status>{
    'ontime' => Status.Ontime,
    'delayed' => Status.Delayed,
    'cancelled' => Status.Cancelled,
    'unknown' => Status.Unknown
  };

  private static final Map<Status, String> STATUS_ENUM_TO_PICKLIST_VALUE = new Map<Status, String>{
    Status.Ontime => 'ontime',
    Status.Delayed => 'delayed',
    Status.Cancelled => 'cancelled',
    Status.Unknown => 'unknown'
  };

  private static final String SAS_AIRLINE_IATA_DESIGNATOR = 'SK';

  private static final Set<String> STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS = new Set<String>{
    'A3',
    'AC',
    'AI',
    'AV',
    'BR',
    'CA',
    'CM',
    'ET',
    'LH',
    'LO',
    'LX',
    'MS',
    'NH',
    'NZ',
    'OS',
    'OU',
    'OZ',
    'SA',
    'SK',
    'SN',
    'SQ',
    'TG',
    'TK',
    'TP',
    'UA',
    'ZH'
  };

  private static final Set<String> hubAirports = new Set<String>{
    'ARN',
    'CPH',
    'OSL'
  };

  @TestVisible
  private Flight() {
    this.underlyingSObject = new Flight__c();
  }

  public Flight(Flight__c f) {
    super(f);
    this.underlyingSObject = f;

    this.tedsIdentifier = f.TEDS_Identifier__c;
    this.operationalControlCenter = f.Operational_Control_Center__c;
    this.operatingCarrier = f.Operating_Carrier__c;
    this.aircraftRegistration = f.Aircraft_Registration__c;

    this.arrivalAirport = f.Arrival_Airport__c;
    this.arrivalDelayedMinutes = f.Arrival_Delayed_Minutes__c;
    this.arrivalGate = f.Arrival_Gate__c;
    this.arrivalStatus = STATUS_PICKLIST_VALUE_TO_ENUM.get(f.Arrival_Status__c);
    this.arrivalTerminal = f.Arrival_Terminal__c;

    this.departureAirport = f.Departure_Airport__c;
    this.departureDelayedMinutes = f.Departure_Delayed_Minutes__c;
    this.departureGate = f.Departure_Gate__c;
    this.departureStatus = STATUS_PICKLIST_VALUE_TO_ENUM.get(
      f.Departure_Status__c
    );
    this.departureTerminal = f.Departure_Terminal__c;

    this.actualArrivalTime = f.Actual_Arrival_Time__c;
    this.actualArrivalTimeLocal = f.Actual_Arrival_Time_Local__c;
    this.actualDepartureTime = f.Actual_Departure_Time__c;
    this.actualDepartureTimeLocal = f.Actual_Departure_Time_Local__c;

    this.estimatedArrivalTime = f.Estimated_Arrival_Time__c;
    this.estimatedArrivalTimeLocal = f.Estimated_Arrival_Time_Local__c;
    this.estimatedDepartureTime = f.Estimated_Departure_Time__c;
    this.estimatedDepartureTimeLocal = f.Estimated_Departure_Time_Local__c;

    this.scheduledArrivalTime = f.Scheduled_Arrival_Time__c;
    this.scheduledArrivalTimeLocal = f.Scheduled_Arrival_Time_Local__c;
    this.scheduledDepartureTime = f.Scheduled_Departure_Time__c;
    this.scheduledDepartureTimeLocal = f.Scheduled_Departure_Time_Local__c;
  }

  public Flight(Flight__c f, Airport departureAirport, Airport arrivalAirport) {
    this(f);

    this.arrivalAirportObject = arrivalAirport;
    this.departureAirportObject = departureAirport;
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.TEDS_Identifier__c = this.tedsIdentifier;
    this.underlyingSObject.Operational_Control_Center__c = this.operationalControlCenter;
    this.underlyingSObject.Operating_Carrier__c = this.operatingCarrier;
    this.underlyingSObject.Aircraft_Registration__c = this.aircraftRegistration;

    this.underlyingSObject.Arrival_Airport__c = this.arrivalAirport;
    this.underlyingSObject.Arrival_Delayed_Minutes__c = this.arrivalDelayedMinutes;
    this.underlyingSObject.Arrival_Gate__c = this.arrivalGate;
    this.underlyingSObject.Arrival_Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.arrivalStatus
    );
    this.underlyingSObject.Arrival_Terminal__c = this.arrivalTerminal;

    this.underlyingSObject.Departure_Airport__c = this.departureAirport;
    this.underlyingSObject.Departure_Delayed_Minutes__c = this.departureDelayedMinutes;
    this.underlyingSObject.Departure_Gate__c = this.departureGate;
    this.underlyingSObject.Departure_Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.departureStatus
    );
    this.underlyingSObject.Departure_Terminal__c = this.departureTerminal;

    this.underlyingSObject.Actual_Arrival_Time__c = this.actualArrivalTime;
    this.underlyingSObject.Actual_Arrival_Time_Local__c = this.actualArrivalTimeLocal;
    this.underlyingSObject.Actual_Departure_Time__c = this.actualDepartureTime;
    this.underlyingSObject.Actual_Departure_Time_Local__c = this.actualDepartureTimeLocal;

    this.underlyingSObject.Estimated_Arrival_Time__c = this.estimatedArrivalTime;
    this.underlyingSObject.Estimated_Arrival_Time_Local__c = this.estimatedArrivalTimeLocal;
    this.underlyingSObject.Estimated_Departure_Time__c = this.estimatedDepartureTime;
    this.underlyingSObject.Estimated_Departure_Time_Local__c = this.estimatedDepartureTimeLocal;

    this.underlyingSObject.Scheduled_Arrival_Time__c = this.scheduledArrivalTime;
    this.underlyingSObject.Scheduled_Arrival_Time_Local__c = this.scheduledArrivalTimeLocal;
    this.underlyingSObject.Scheduled_Departure_Time__c = this.scheduledDepartureTime;
    this.underlyingSObject.Scheduled_Departure_Time_Local__c = this.scheduledDepartureTimeLocal;
  }

  /**
   * Returns true if this flight if the operating carrier of this flight belongs
   * to Star Alliance.
   */
  public Boolean isOperatedByStarAlliance() {
    return STAR_ALLIANCE_AIRLINE_IATA_DESIGNATORS.contains(this.getOperator());
  }

  public Boolean isOperatedBySAS() {
    return this.getOperator() == SAS_AIRLINE_IATA_DESIGNATOR;
  }

  /**
   * Returns true if this flight is delayed or cancelled based on departure and
   * arrival statuses.
   */
  public Boolean isDelayedOrCancelled() {
    return this.arrivalStatus == Status.Delayed ||
      (this.arrivalStatus == Status.Cancelled &&
      this.departureStatus == Status.Cancelled);
  }

  public List<FlightIrregularity> getCancellations() {
    if (this.irregularities == null) {
      throw new MissingDataException('Irregularities have not been set');
    }
    List<FlightIrregularity> cancellations = new List<FlightIrregularity>{};
    for (FlightIrregularity fi : this.irregularities) {
      if (fi.isCancellation() && !fi.isArrivalCancellation()) {
        cancellations.add(fi);
      }
    }

    return cancellations;
  }

  public static Status getStatusFromPicklistValue(String picklistValue) {
    return STATUS_PICKLIST_VALUE_TO_ENUM.get(picklistValue);
  }

  /**
   * Calculates the direct distance between this flight's departure and
   * arrival airports.
   *
   * @throws MissingDataException if airport object fields have not been set for this flight.
   */
  public Integer getFlightDistancesInMeters() {
    if (
      this.arrivalAirportObject == null ||
      this.departureAirportObject == null
    ) {
      throw new MissingDataException('Missing airports.');
    }
    return this.departureAirportObject.distanceInMetersTo(
      this.arrivalAirportObject
    );
  }

  public Boolean departsHub() {
    return hubAirports.contains(this.departureAirport);
  }

  /*
   * Returns variations of the flight id written in plain text
   * @param TEDSId flightId in TEDS format, e.g. SK0151-20220713-RIX-OSL
   *
   * @return A tuple with ids with the following formats: BT0151-20220713, BT0151-2022-07-13
   */
  public static List<String> TEDSIdToSimpleFlightIds(String TEDSId) {
    String flightNumber = TEDSId.substringBefore('-'); // Should be normalized
    String flightDateConcat = TEDSId.substringAfter('-').substringBefore('-');
    String flightDateSeparated =
      flightDateConcat.substring(0, 4) +
      '-' +
      flightDateConcat.substring(4, 6) +
      '-' +
      flightDateConcat.substring(6, 8);

    String format1 = flightNumber + '-' + flightDateConcat;
    String format2 = flightNumber + '-' + flightDateSeparated;

    return new List<String>{ format1, format2 };
  }

  /**
   * Constructs a flightNumber + date combination like the one used in TEDS
   *
   * @param flightNumber E.g. SK1234
   * @param flightDate
   * @return a string like: SK1234-20220101
   */
  public static String constructTEDSFlightNumberDate(
    String flightNumber,
    Date flightDate
  ) {
    return normalizeFlightNumber(flightNumber) +
      '-' +
      StringUtils.dateToTEDSString(flightDate);
  }

  /**
   * Method to normalize a valid IATA flight number to the format used by TEDS.
   * TEDS format is valid IATA format with trailing numbers leftpadded with 0
   * Returns a normalized flight number.
   *
   *  @param enteredFlightNumber The flight number as entered by manual input (forms etc.)
   */
  public static String normalizeFlightNumber(String enteredFlightNumber) {
    String toNormalize = enteredFlightNumber.toUpperCase();
    String toReturn = '';
    Pattern validTEDSFormat = Pattern.compile('^([A-Z]\\w|\\w[A-Z])(\\d{4})$');
    Pattern validFlightNumberFormat = Pattern.compile(
      '^([A-Z]\\w|\\w[A-Z])(\\d{1,4})$'
    );
    Boolean validIATAFlightNumber = isValidIATAFlightNumber(toNormalize);
    if (validIATAFlightNumber) {
      String airlineCode = toNormalize.substring(0, 2);
      String flightNumber = toNormalize.substring(2, toNormalize.length());
      toReturn = airlineCode + flightNumber.leftPad(4, '0');
    }
    if (validTEDSFormat.matcher(toReturn).matches()) {
      return toReturn;
    } else {
      throw new FlightException('Unable to normalize Flight Number');
    }
  }

  /* Method to validate if an entered flight number is a valid IATA flight number
   * Valid formats are:
   * [LETTER][NUMBER] followed by 1-4 numbers
   * [NUMBER][LETTER] followed by 1-4 numbers
   * [LETTER][LETTER] followed by 1-4 numbers
   */
  public static Boolean isValidIATAFlightNumber(String toCheck) {
    Pattern validFlightNumberFormat = Pattern.compile(
      '^([A-Z]\\w|\\w[A-Z])(\\d{1,4})$'
    );
    Matcher matcher = validFlightNumberFormat.matcher(toCheck);
    return matcher.matches();
  }

  //Flights and Irregularities are stored in the same table in EDW
  public static Flights createFromEDWData(
    List<FetchEDWBookingResponse.Irregularity> flightSourceData
  ) {
    Map<String, Flight__c> flightIdToRecord = new Map<String, Flight__c>();
    List<FetchEDWBookingResponse.Irregularity> irregularitiesToCreate = new List<FetchEDWBookingResponse.Irregularity>();
    for (FetchEDWBookingResponse.Irregularity irr : flightSourceData) {
      //The input data contains different data based on if flight belongs to SK or other carrier
      String flightStatus = 'unknown';
      String arrivalStatus = 'unknown';
      String departureStatus = 'unknown';
      switch on irr.status {
        when 'DEPARTURE DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'ontime';
          departureStatus = 'delayed';
        }
        when 'ARRIVAL DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'delayed';
          departureStatus = 'ontime';
        }
        when 'DEPARTUE AND ARRIVAL DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'delayed';
          departureStatus = 'delayed';
        }
        when 'CANCELLED' {
          flightStatus = 'cancelled';
          arrivalStatus = 'cancelled';
          departureStatus = 'cancelled';
        }
        when 'ON TIME' {
          flightStatus = 'ontime';
          arrivalStatus = 'ontime';
          departureStatus = 'ontime';
        }
        when else {
          flightStatus = 'unknown';
          arrivalStatus = 'unknown';
          departureStatus = 'unknown';
        }
      }
      Boolean cancelledOrDelayed =
        flightStatus == 'delayed' ||
        irr.fltStatus == 'X';
      if (cancelledOrDelayed) {
        irregularitiesToCreate.add(irr);
      }
      String irrFlightId = String.format(
        '{0}-{1}-{2}-{3}',
        new List<Object>{
          irr.fltId.deleteWhitespace(),
          Datetime.newInstance(irr.depDte).format('yyyyMMdd'),
          irr.stnFrCd,
          irr.stnToCd
        }
      );
      if (flightIdToRecord.get(irrFlightId) != null) {
        continue;
      }
      Flight f = new Flight(new Flight__c(Name = irrFlightId));
      f.tedsIdentifier = irrFlightId;
      f.aircraftRegistration = irr.aircraftRegistration;
      f.arrivalAirport = irr.stnToCd;
      f.arrivalDelayedMinutes = irr.arrivalDelayMins;
      f.arrivalStatus = Flight.getStatusFromPicklistValue(arrivalStatus);
      f.departureAirport = irr.stnFrCd;
      f.departureDelayedMinutes = irr.depDelayMins;
      f.departureStatus = Flight.getStatusFromPicklistValue(departureStatus);
      f.actualArrivalTime = irr.ataTms == null
        ? null
        : Datetime.newInstance(irr.ataTms);
      f.actualDepartureTime = irr.atdTms == null
        ? null
        : Datetime.newInstance(irr.atdTms);
      f.estimatedArrivalTime = irr.etaTms == null
        ? null
        : Datetime.newInstance(irr.etaTms);
      f.estimatedDepartureTime = irr.etdTms == null
        ? null
        : Datetime.newInstance(irr.etdTms);
      f.scheduledArrivalTime = irr.staTms == null
        ? null
        : Datetime.newInstance(irr.staTms);
      f.scheduledDepartureTime = irr.stdTms == null
        ? null
        : Datetime.newInstance(irr.stdTms);
      f.updateSObjectFields();
      flightIdToRecord.put(irrFlightId, f.underlyingSObject);
    }

    Flights newFlights = Flights.newInstance(flightIdToRecord.values());
    newFlights.flightIrregularities = FlightIrregularity.createFromEDWData(
      irregularitiesToCreate
    );
    return newFlights;
  }

  public Boolean equals(Object obj) {
    if (obj instanceof Flight) {
      Flight that = (Flight) obj;

      return this.tedsIdentifier == that.tedsIdentifier;
    } else {
      return false;
    }
  }

  public Integer hashCode() {
    return 31 * this.tedsIdentifier.hashCode();
  }

  // If operatingCarrier is null, try to parse it from the teds identifier
  public String getOperator() {
    String oper = this.operatingCarrier;
    if (oper == null && this.tedsIdentifier != null) {
      oper = this.tedsIdentifier.substring(0, 2);
      if (oper == 'SK' && this.tedsIdentifier.substring(2, 3) == '3') {
        // Codeshare
        oper = null;
      }
    }
    return oper;
  }
}
