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

  // This should likely be stored in CancellationCode.globalValueSet. However, db calls makes that very annoying.
  // TODO: Populate, get help from liability: https://docs.google.com/spreadsheets/d/1lo-pu7Ew-f-5z18Ke51962j_VZkI9FfA8kYiKTFUw5o/edit#gid=801456937
  public static final Map<String, Boolean> codeToSASIsResponsible = new Map<String, Boolean>{
    'WEAT' => false,
    'TECH' => true,
    'INDU' => true,
    'FA' => true,
    'CA' => true,
    'AF' => false
  };

  private static final Set<String> ROTATION_CODES = new Set<String>{
    'RA (93)',
    'RA',
    '93',
    'RC (95)',
    'RC',
    '95',
    'RS (94)',
    'RS',
    '94'
  };

  private static final Map<String, String> codeToExplanation = new Map<String, String>{
    'AIRS' => 'airspace restrictions',
    'ARPT' => 'airport restrictions',
    'AUTH' => 'a diversion caused by ATC, security control or local authorities',
    'COMM' => 'commercial reasons',
    'CREW' => 'crew shortage',
    'DAMA' => 'damage to the aircraft',
    'EQUI' => 'missing equipment (including aircraft)',
    'FUEL' => 'fuel related reasons',
    'HDLG' => 'the handling agent',
    'HOLI' => 'holiday season',
    'INDU' => 'industrial action',
    'NODE' => 'reduced or no commercial demand',
    'OPCO' => 'reroutings, diversions, consolidations, cancellations and/or revisions to timetable as decided by a third party', // as decided by MOVEMENT CONTROL CENTRE or by a local operational control centre or by a local operational control
    'OPER' => 'reroutings, diversions, consolidations, cancellations and/or revisions to timetable as decided by a third party',
    'PERF' => 'planned aircraft type not being able to lift planned payload or fuelstop necessary due to payload',
    'POLI' => 'political unrest, war or war-like situations etc.',
    'REPO' => 'aircraft repositioning',
    'RTNS' => 'an ad-hoc schedule change being withdrawn and the original schedule for the flight being reinstated',
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
    return this.type.substringBefore(' ') == 'Cancellation';
  }

  public Boolean isNA0Delay() {
    Boolean codeIsEmpty =
      this.code == 'N/A' ||
      this.code == null ||
      this.code == '';
    Boolean durationIsEmpty =
      this.durationMinutes == 0 ||
      this.durationMinutes == null;
    return codeIsEmpty && durationIsEmpty;
  }

  public Boolean isArrivalCancellation() {
    return this.type == 'Cancellation (arrival)';
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

  public static FlightIrregularities createFromEDWData(
    List<FetchEDWBookingResponse.Irregularity> irregularities
  ) {
    List<FlightIrregularities__c> processedIrregularities = new List<FlightIrregularities__c>();
    Map<String, List<FlightIrregularities__c>> flightIdToIrregularities = new Map<String, List<FlightIrregularities__c>>();
    for (FetchEDWBookingResponse.Irregularity irr : irregularities) {
      String irrFlightId = String.format(
        '{0}-{1}-{2}-{3}',
        new List<Object>{
          irr.fltId.deleteWhitespace(),
          Datetime.newInstance(irr.depDte).format('yyyyMMdd'),
          irr.stnFrCd,
          irr.stnToCd
        }
      );
      FlightIrregularity fi = new FlightIrregularity(
        new FlightIrregularities__c()
      );
      fi.cancellationTime = irr.cnlEventDts == null
        ? null
        : Datetime.newInstance(irr.cnlEventDts);
      fi.code = irr.fltStatus == 'X' ? irr.cnlRsnCd : irr.delayRsnCd;
      fi.description = irr.cnlSpplInfo;
      fi.durationMinutes = Decimal.valueOf(irr.duration);
      fi.nameC = '';
      fi.reason = irr.fltStatus == 'X' ? irr.cnlSpplInfo : irr.delayRsnText;
      fi.type = irr.status;
      fi.updateSObjectFields();
      processedIrregularities.add(fi.underlyingSObject);
      if (flightIdToIrregularities.get(irrFlightId) == null) {
        flightIdToIrregularities.put(
          irrFlightId,
          new List<FlightIrregularities__c>()
        );
      }
      flightIdToIrregularities.get(irrFlightId).add(fi.underlyingSObject);
    }
    FlightIrregularities newIrregularities = FlightIrregularities.newInstance(
      processedIrregularities
    );
    newIrregularities.TEDSIdToIrregularities = flightIdToIrregularities;
    return newIrregularities;
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
