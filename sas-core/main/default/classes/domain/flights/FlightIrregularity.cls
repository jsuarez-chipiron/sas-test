public without sharing class FlightIrregularity extends AbstractSObjectWrapper {
  public FlightIrregularities__c underlyingSObject { get; private set; }

  public DateTime cancellationTime;
  public String code;
  public String description;
  public Decimal durationMinutes;
  public EU261Eligibility eligibleForEU261;
  public String flightId;
  public String nameC;
  public String reason;
  public String type;

  public class IrregularityException extends Exception {
  }

  public class IrregularityTypeException extends Exception {
  }

  public class CommercialCancellationException extends Exception {
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Cancellation_Time__c = this.cancellationTime;
    this.underlyingSObject.Code__c = this.code;
    this.underlyingSObject.Description__c = this.description;
    this.underlyingSObject.Duration_minutes__c = this.durationMinutes;
    this.underlyingSObject.Eligible_For_EU261__c = EU261_ENUM_TO_PICKLIST_VALUE.get(
      this.eligibleForEU261
    );
    this.underlyingSObject.Flight__c = this.flightId;
    this.underlyingSObject.Name__c = this.nameC;
    this.underlyingSObject.Reason__c = this.reason;
    this.underlyingSObject.Type__c = this.type;
  }

  public enum EU261Eligibility {
    Tentative,
    Yes,
    No
  }

  private FlightIrregularity() {
    this.underlyingSObject = new FlightIrregularities__c();
  }

  public FlightIrregularity(FlightIrregularities__c fi) {
    super(fi);
    this.underlyingSObject = fi;

    this.cancellationTime = fi.Cancellation_Time__c;
    this.code = fi.Code__c;
    this.description = fi.Description__c;
    this.durationMinutes = fi.Duration_minutes__c;
    this.eligibleForEU261 = EU261_PICKLIST_VALUE_TO_ENUM.get(
      fi.Eligible_For_EU261__c
    );
    this.flightId = fi.Flight__c;
    this.nameC = fi.Name__c;
    this.reason = fi.Reason__c;
    this.type = fi.Type__c;
  }

  public enum CODE {
  } // TODO

  public enum IrregularityType {
    CANCELLATION,
    DELAY,
    INVALID
  }

  // This should likely be stored in CancellationCode.globalValueSet. However, db calls makes that very annoying.
  // TODO: Populate, get help from liability: https://docs.google.com/spreadsheets/d/1lo-pu7Ew-f-5z18Ke51962j_VZkI9FfA8kYiKTFUw5o/edit#gid=801456937
  public static final Map<String, Boolean> codeToSASIsResponsible = new Map<String, Boolean>{
    'WEAT' => false,
    'TECH' => true,
    'FA' => true,
    'CA' => true,
    'AF' => false
  };

  private static final Set<String> ROTATION_CODES = new Set<String>{
    'RA',
    '93',
    'RC',
    '95',
    'RS',
    '94'
  };

  private static final Set<String> CANCELLATION_CODES = new Set<String>{
    'AIRS',
    'ARPT',
    'AUTH',
    'COMM',
    'CREW',
    'DAMA',
    'EQUI',
    'FUEL',
    'HDLG',
    'HOLI',
    'INDU',
    'NODE',
    'OPCO',
    'OPER',
    'PERF',
    'POLI',
    'REPO',
    'RTNS',
    'RUNW',
    'TECH',
    'WEAT'
  };

  private static final Set<String> DELAY_CODES = new Set<String>{
    'AE',
    '83',
    'AF',
    '87',
    'AG',
    '86',
    'AM',
    '89',
    'AS',
    '85',
    'AT',
    '81',
    'AW',
    '84',
    'AX',
    '82',
    'CA',
    '29',
    'CC',
    '23',
    'CD',
    '21',
    'CE',
    '27',
    'CI',
    '24',
    'CL',
    '28',
    'CO',
    '25',
    'CP',
    '22',
    'CU',
    '26',
    'D',
    'DF',
    '51',
    'DG',
    '52',
    'EC',
    '56',
    'ED',
    '55',
    'EF',
    '57',
    'EO',
    '58',
    'FA',
    '68',
    'FB',
    '69',
    'FC',
    '67',
    'FF',
    '62',
    'FL',
    '66',
    'FP',
    '61',
    'FR',
    '65',
    'FS',
    '64',
    'FT',
    '63',
    'GB',
    '37',
    'GC',
    '35',
    'GD',
    '31',
    'GE',
    '33',
    'GF',
    '36',
    'GL',
    '32',
    'GS',
    '34',
    'GT',
    '39',
    'GU',
    '38',
    'HL',
    '02',
    'MI',
    '97',
    'MO',
    '98',
    'MX',
    '99',
    'OA',
    '06',
    'PB',
    '18',
    'PC',
    '17',
    'PD',
    '11',
    'PE',
    '13',
    'PF',
    '03',
    'PH',
    '15',
    'PL',
    '12',
    'PO',
    '14',
    'PS',
    '16',
    'PW',
    '19',
    'RA',
    '93',
    'RC',
    '95',
    'RL',
    '91',
    'RO',
    '96',
    'RS',
    '94',
    'RT',
    '92',
    'RX',
    '04',
    'SK',
    '01',
    'TA',
    '45',
    'TC',
    '46',
    'TD',
    '41',
    'TL',
    '47',
    'TM',
    '42',
    'TN',
    '43',
    'TS',
    '44',
    'TV',
    '48',
    'WG',
    '77',
    'WI',
    '75',
    'WO',
    '71',
    'WR',
    '73',
    'WS',
    '76',
    'WT',
    '72'
  }; // Note! Does not contain subcode, e.g. WI01, TV02 etc.

  private static final Map<String, String> codeToExplanation = new Map<String, String>{
    'AIRS' => 'airspace restrictions',
    'ARPT' => 'airport restrictions',
    'AUTH' => 'a diversion caused by ATC, security control or local authorities',
    'COMM' => 'commercial reasons',
    'CREW' => 'crew shortage',
    'DAMA' => 'damage to the aircraft',
    'EQUI' => 'equipment short-falls',
    'FUEL' => 'fuel related reasons',
    'HDLG' => 'a ground staff and/or handling agent shortage',
    'HOLI' => 'the holiday season',
    'INDU' => 'industrial action',
    'NODE' => 'reduced or no commercial demand',
    'OPCO' => 'operational conditions causing timetable changes', // as decided by MOVEMENT CONTROL CENTRE or by a local operational control centre or by a local operational control
    'OPER' => 'operational conditions causing timetable changes',
    'PERF' => 'the aircraft being unable to perform the specific flight',
    'POLI' => 'political unrest, war, or war-like situations, etc.',
    'REPO' => 'aircraft repositioning',
    'RTNS' => 'a flight scheduling anomaly',
    'RUNW' => 'technical restrictions of a runway',
    'TECH' => 'technical issues',
    'WEAT' => 'weather conditions'
  }; // TODO: CHeck with liability and process owners that this is ok

  private static final Map<String, EU261Eligibility> EU261_PICKLIST_VALUE_TO_ENUM = new Map<String, EU261Eligibility>{
    'Tentative' => EU261Eligibility.Tentative,
    'Yes' => EU261Eligibility.Yes,
    'No' => EU261Eligibility.No
  };

  private static final Map<EU261Eligibility, String> EU261_ENUM_TO_PICKLIST_VALUE = new Map<EU261Eligibility, String>{
    EU261Eligibility.Tentative => 'Tentative',
    EU261Eligibility.Yes => 'Yes',
    EU261Eligibility.No => 'No'
  };

  public String getExplanation() {
    if (this.description != null && this.description != '') {
      return this.description;
    }

    String explanation = codeToExplanation.get(this.code);
    if (explanation == null) {
      explanation = 'cancellation code "' + this.code + '"'; // Should not happen
    }
    return explanation;
  }

  public String getOutsideControlExplanationCancellation() {
    String explanation = 'The flight was cancelled because of '; // TODO: improve
    explanation += getExplanation();
    explanation += ', which is not within SAS control.';

    return explanation;
  }

  public Boolean isRotation() {
    return ROTATION_CODES.contains(this.code);
  }

  public Boolean isCancellation() {
    return getType() == IrregularityType.CANCELLATION;
  }

  public Boolean isDelay() {
    return getType() == IrregularityType.DELAY;
  }

  public Boolean isInvalid() {
    return getType() == IrregularityType.INVALID;
  }

  @TestVisible
  private IrregularityType getType() {
    Boolean hasCancellationCode = CANCELLATION_CODES.contains(this.code);
    Boolean hasDelayCode = DELAY_CODES.contains(this.code);
    if (
      this.code != null &&
      this.code.length() == 4 &&
      this.code.substring(2, 4).isNumeric()
    ) {
      hasDelayCode = DELAY_CODES.contains(this.code.substring(2, 4));
    }

    if (hasDelayCode) {
      return IrregularityType.DELAY;
    } else if (hasCancellationCode) {
      return IrregularityType.CANCELLATION;
    }

    if (this.code == 'N/A' || this.code == null || this.code == '') {
      if (
        this.cancellationTime != null &&
        this.cancellationTime > DateTime.newInstance(1950, 1, 1)
      ) {
        // If the cancellationtime exist and is not invalid, it is a kind of valid cancellation
        return IrregularityType.CANCELLATION;
      } else if (this.durationMinutes != null && this.durationMinutes > 0) {
        // If the duration exisits and is more than 0, it is a kind of valid delay
        return IrregularityType.DELAY;
      } else if (
        (this.type.toLowerCase().contains('cancellation') ||
        this.type.toLowerCase().contains('cancelled')) &&
        !this.type.toLowerCase().contains('arrival')
      ) {
        // Special case, cancellation departure with no code or cancellation time
        throw new CommercialCancellationException(
          'Potential irregularity due to commercial reasons'
        );
      } else {
        // Cancellation N/A "arrival" with no cancellation time and delays without
        // a code or duration minutes get here.
        return IrregularityType.INVALID;
      }
    }

    throw new IrregularityTypeException(
      'Unknown irregularity: ' +
      this.code +
      '(' +
      this.id +
      ')'
    );
  }

  public Boolean isWithinSASControl() {
    Boolean SASIsResponsible;

    switch on this.eligibleForEU261 {
      when Yes {
        SASIsResponsible = true;
      }
      when No {
        SASIsResponsible = false;
      }
      when else {
        SASIsResponsible = codeToSASIsResponsible.get(this.code);
      }
    }

    if (SASIsResponsible == null) {
      throw new IrregularityException(
        'Cannot determine whether SAS is within control or not.'
      );
    }

    return SASisResponsible;
  }

  /**
   * Returns a new list with all duplicates from the given list removed.
   */
  public static List<FlightIrregularity> unique(
    List<FlightIrregularity> irregularities
  ) {
    List<FlightIrregularity> toReturn = new List<FlightIrregularity>{};

    for (FlightIrregularity fi : irregularities) {
      if (!toReturn.contains(fi)) {
        toReturn.add(fi);
      }
    }

    return toReturn;
  }

  /*
   * @return a List of 4 decimal values of:
   * delay on departure [0],
   * delay on arrival [1],
   * delay on departure within SAS' control [2],
   * delay on arrival within SAS' control [3].
   * TODO: refactor to use getType() instead of substringBefore/After (see over whole application)
   */
  public static List<Decimal> getTotalDelayInMinutesDivided(
    List<FlightIrregularity> irregularities
  ) {
    Decimal departureDelay = 0;
    Decimal arrivalDelay = 0;
    Decimal departureDelayWithinSASControl = 0;
    Decimal arrivalDelayWithinSASControl = 0;
    Boolean cancellationExists = false;

    for (FlightIrregularity f : irregularities) {
      String cancellationOrDelay = f.type.substringBefore(' ');
      String arrivalOrDeparture = f.type.substringAfter(' ');
      if (cancellationOrDelay == 'Cancellation') {
        cancellationExists = true;
      } else {
        Boolean SASisResponsible = f.isWithinSASControl();

        if (arrivalOrDeparture == '(departure)') {
          if (SASisResponsible) {
            departureDelayWithinSASControl += f.durationMinutes;
          }
          departureDelay += f.durationMinutes;
        } else if (arrivalOrDeparture == '(arrival)') {
          if (SASisResponsible) {
            arrivalDelayWithinSASControl += f.durationMinutes;
          }
          arrivalDelay += f.durationMinutes;
        } else {
          throw new IrregularityException('Invalid irregularity type');
        }
      }
    }

    if (cancellationExists && (departureDelay + arrivalDelay) != 0) {
      throw new IrregularityException(
        'There are both cancellation and delay irregularities'
      );
    }

    return new List<Decimal>{
      departureDelay,
      arrivalDelay,
      departureDelayWithinSASControl,
      arrivalDelayWithinSASControl
    };
  }

  /**
   * @return a String with an explanation which of the irregularities SAS is not responsible for.
   */
  public static String getOutsideSASControlExplanationDelay(
    List<FlightIrregularity> irregularities
  ) {
    Decimal totalDelayOutsideSASControl = 0;
    String explanation = 'SAS is not responsible for delay(s) with reason code(s): ';

    for (FlightIrregularity f : irregularities) {
      Boolean SASisResponsible = f.isWithinSASControl();
      if (!SASisResponsible) {
        totalDelayOutsideSASControl += f.durationMinutes;
        explanation += f.code + ' (' + f.durationMinutes + ' minutes), ';
      }
    }

    explanation += '(Total: ' + totalDelayOutsideSASControl + ' minutes)';

    return explanation;
  }

  public Boolean equals(Object compareTo) {
    FlightIrregularity otherIrregularity = (FlightIrregularity) compareTo;

    if (
      this.code == otherIrregularity.code &&
      this.flightId == otherIrregularity.flightId &&
      this.reason == otherIrregularity.reason &&
      this.durationMinutes == otherIrregularity.durationMinutes &&
      this.type == otherIrregularity.type &&
      this.description == otherIrregularity.description &&
      this.cancellationTime == otherIrregularity.cancellationTime
    ) {
      return true;
    } else {
      return false;
    }
  }
}
