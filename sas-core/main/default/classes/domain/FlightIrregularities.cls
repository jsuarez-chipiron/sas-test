public without sharing class FlightIrregularities extends fflib_SObjectDomain {
  public FlightIrregularities(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<FlightIrregularities__c>) Records;
  }
  public List<FlightIrregularities__c> instanceRecords;
  public Map<String, List<FlightIrregularities__c>> TEDSIdToIrregularities = new Map<String, List<FlightIrregularities__c>>{};

  // This should likely be stored in CancellationCode.globalValueSet. However, db calls makes that very annoying.
  // TODO: Populate, get help from liability: https://docs.google.com/spreadsheets/d/1lo-pu7Ew-f-5z18Ke51962j_VZkI9FfA8kYiKTFUw5o/edit#gid=801456937
  public static final Map<String, Boolean> codeToSASIsResponsible = new Map<String, Boolean>{
    'WEAT' => false,
    'TECH' => true,
    'FA' => true
  };

  public static final Set<String> POTENTIALROTATIONCODES = new Set<String>{
    'EQUI',
    'CREW',
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

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new FlightIrregularities(records);
    }
  }

  public class IrregularityException extends Exception {
  }

  public static FlightIrregularities newInstance(
    List<FlightIrregularities__c> sObjectList
  ) {
    return (FlightIrregularities) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  /**
   * Creates flight irregularities from TEDS data.
   * @param TEDSIds A List of Strings of TEDSIds
   * @param TEDSIdToflightArrivals A Map<String, TEDSFlight.Arrival> which maps the TEDSId of the flight to the Arrival information from TEDS
   * @param TEDSIdToflightDepartures A Map<String, TEDSFlight.Departure> which maps the TEDSId of the flight to the Departure information from TEDS
   * @return A Flightirregularities object created from the TEDS data.
   */
  public static FlightIrregularities createFromTEDSData(
    List<String> TEDSIds,
    Map<String, TEDSFlight.Arrival> TEDSIdToflightArrivals,
    Map<String, TEDSFlight.Departure> TEDSIdToflightDepartures
  ) {
    List<FlightIrregularities__c> processedIrregularities = new List<FlightIrregularities__c>{};
    Map<String, List<FlightIrregularities__c>> TEDSIdToIrregularities = new Map<String, List<FlightIrregularities__c>>{};
    for (String TEDSId : TEDSIds) {
      List<FlightIrregularities__c> flightSpecificIrregularities = new List<FlightIrregularities__c>{};
      TEDSFlight.Arrival arrival = TEDSIdToflightArrivals.get(TEDSId);
      TEDSFlight.Departure departure = TEDSIdToflightDepartures.get(TEDSId);

      if (arrival != null) {
        if (arrival.status == 'delayed') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromDelay(arrival.delayReasons, '(arrival)')
          );
        } else if (arrival.status == 'cancelled') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromCancellation(
              arrival.cancellationReasons,
              '(arrival)',
              null
            )
          );
        }
      }
      if (departure != null) {
        if (departure.status == 'delayed') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromDelay(
              departure.delayReasons,
              '(departure)'
            )
          );
        } else if (departure.status == 'cancelled') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromCancellation(
              departure.cancellationReasons,
              '(departure)',
              departure.cancellationTime
            )
          );
        }
      }
      TEDSIdToIrregularities.put(TEDSId, flightSpecificIrregularities);
      processedIrregularities.addAll(flightSpecificIrregularities);
    }

    FlightIrregularities newFlightIrregularities = FlightIrregularities.newInstance(
      processedIrregularities
    );
    newFlightIrregularities.TEDSIdToIrregularities = TEDSIdToIrregularities;

    return newFlightIrregularities;
  }

  public class FlightsAreMissingIdsException extends Exception {
  }

  /**
   * This function has to be called before insertion, otherwise the insert throws an exception
   * @return Returns "this" to enable chaining
   */
  public FlightIrregularities addFlightReferences(List<Flight__c> flights) {
    for (Flight__c flight : flights) {
      List<FlightIrregularities__c> irregularities = TEDSIdToIrregularities.get(
        flight.TEDS_Identifier__c
      );
      if (irregularities != null) {
        for (FlightIrregularities__c irregularity : irregularities) {
          Id flightId = flight.Id;
          if (flightId == null) {
            throw new flightsAreMissingIdsException(
              'The flights which the irregularities reference do not have Ids. Please insert the flights into the database before calling this function.'
            );
          }
          irregularity.Flight__c = flightId;
        }
      }
    }

    return this;
  }

  public Boolean containsRotationIrregularities() {
    for (FlightIrregularities__c f : instanceRecords) {
      if (POTENTIALROTATIONCODES.contains(f.Code__c)) {
        return true;
      }
    }
    return false;
  }

  public Map<Id, Boolean> isWithinSASControl() {
    Map<Id, Boolean> irregularityToIsWithinControl = new Map<Id, Boolean>{};
    Boolean test1 = codeToSASIsResponsible.get('AIRS');
    Boolean test2 = codeToSASIsResponsible.get('TECH');
    Boolean test3 = codeToSASIsResponsible.get('FA');
    Boolean test4 = codeToSASIsResponsible.get('WEAT');
    Boolean test5 = codeToSASIsResponsible.get('-----');

    for (FlightIrregularities__c f : instanceRecords) {
      Boolean SASisResponsible = codeToSASIsResponsible.get(f.Code__c);
      if (SASisResponsible == null) {
        throw new IrregularityException(
          'Cannot determine wether SAS is within control or not.'
        );
      }
      irregularityToIsWithinControl.put(f.Id, SASisResponsible);
    }

    return irregularityToIsWithinControl;
  }

  public Map<Id, List<FlightIrregularities__c>> getFlightIdToIrregularities() {
    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities = new Map<Id, List<FlightIrregularities__c>>();
    for (FlightIrregularities__c irregularity : instanceRecords) {
      List<FlightIrregularities__c> currentIrregularities = flightIdToIrregularities.get(
        irregularity.Flight__c
      );
      if (currentIrregularities == null) {
        flightIdToIrregularities.put(
          irregularity.Flight__c,
          new List<FlightIrregularities__c>{ irregularity }
        );
      } else {
        currentIrregularities.add(irregularity);
      }
    }
    return flightIdToIrregularities;
  }

  /*
   * @return a List of 4 decimal values of:
   * delay on departure [0],
   * delay on arrival [1],
   * delay on departure within SAS' control [2],
   * delay on arrival within SAS' control [3].
   */
  public List<Decimal> getTotalDelayInMinutesDivided() {
    Decimal departureDelay = 0;
    Decimal arrivalDelay = 0;
    Decimal departureDelayWithinSASControl = 0;
    Decimal arrivalDelayWithinSASControl = 0;
    Boolean cancellationExists = false;

    for (FlightIrregularities__c f : instanceRecords) {
      String cancellationOrDelay = f.Type__c.substringBefore(' ');
      String arrivalOrDeparture = f.Type__c.substringAfter(' ');
      if (cancellationOrDelay == 'Cancellation') {
        cancellationExists = true;
      } else {
        Boolean SASisResponsible = codeToSASIsResponsible.get(f.Code__c);
        if (SASisResponsible == null) {
          throw new IrregularityException(
            'Cannot determine wether SAS is within control or not.'
          );
        }

        if (arrivalOrDeparture == '(departure)') {
          if (SASisResponsible) {
            departureDelayWithinSASControl += f.Duration_minutes__c;
          }
          departureDelay += f.Duration_minutes__c;
        } else if (arrivalOrDeparture == '(arrival)') {
          if (SASisResponsible) {
            arrivalDelayWithinSASControl += f.Duration_minutes__c;
          }
          arrivalDelay += f.Duration_minutes__c;
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
  public String getOutsideSASControlExplanation() {
    Decimal totalDelayOutsideSASControl = 0;
    String explanation = 'SAS is not responsible for delay(s) with reason code(s): ';

    for (FlightIrregularities__c f : instanceRecords) {
      Boolean SASisResponsible = codeToSASIsResponsible.get(f.Code__c);
      if (SASisResponsible == null) {
        throw new IrregularityException(
          'Cannot get explanation of why SAS is within control or not.'
        );
      }
      if (!SASisResponsible) {
        totalDelayOutsideSASControl += f.Duration_minutes__c;
        explanation += f.Code__c + ' (' + f.Duration_minutes__c + ' minutes), ';
      }
    }

    explanation += '(Total: ' + totalDelayOutsideSASControl + ' minutes)';

    return explanation;
  }

  public void removeNA0Delay() {
    List<FlightIrregularities__c> irregularitiesToSave = new List<FlightIrregularities__c>{};
    for (FlightIrregularities__c fi : instanceRecords) {
      if (
        !((fi.Code__c == 'N/A' && fi.Duration_minutes__c == 0) ||
        (fi.Code__c == null &&
        fi.Duration_minutes__c == null))
      ) {
        irregularitiesToSave.add(fi);
      }
    }

    this.instanceRecords = irregularitiesToSave;
  }

  /**
   * Creates FlightIrregularities__c of type "Delay" from TEDS data.
   * @param reasons A list of TEDSFlight.DelayReasons from which the FlightIrregularities__c should be created.
   * @param additionalInfo A String with additional info to add to the type of the irregularity, either: "(arrival)" or "(departure)".
   * @return A List of the FlightIrregularities__c created from the TEDS data.
   */
  private static List<FlightIrregularities__c> createFlightIrregularityFromDelay(
    List<TEDSFlight.DelayReasons> reasons,
    String additionalInfo
  ) {
    List<FlightIrregularities__c> result = new List<FlightIrregularities__c>{};
    if (reasons != null) {
      for (TEDSFlight.DelayReasons reason : reasons) {
        String code = 'N/A';
        String reasonText = reason.reasonText;
        if (reason.reasonCode != null) {
          code = reason.reasonCode;
        }
        if (reasonText?.length() > 2000) {
          reasonText = reasonText.substring(0, 2000);
        }
        result.add(
          new FlightIrregularities__c(
            Code__c = code,
            Duration_minutes__c = DateUtils.convertISO8601DurationToMinutes(
              reason.duration
            ),
            Reason__c = reasonText,
            Type__c = 'Delay ' + additionalInfo
          )
        );
      }
    } else {
      // Delayed no reason
      result.add(
        new FlightIrregularities__c(
          Code__c = 'N/A',
          Reason__c = '',
          Type__c = 'Delay ' + additionalInfo
        )
      );
    }
    return result;
  }

  /**
   * Creates FlightIrregularities__c of type "Cancellation" from TEDS data.
   * @param reasons A list of TEDSFlight.CancellationReasons from which the FlightIrregularities__c should be created.
   * @param additionalInfo A String with additional info to add to the type of the irregularity, either: "(arrival)" or "(departure)".
   * @return A List of the FlightIrregularities__c created from the TEDS data.
   */
  private static List<FlightIrregularities__c> createFlightIrregularityFromCancellation(
    List<TEDSFlight.CancellationReasons> reasons,
    String additionalInfo,
    String isoCancellationTime
  ) {
    List<FlightIrregularities__c> result = new List<FlightIrregularities__c>{};
    if (reasons != null) {
      for (TEDSFlight.CancellationReasons reason : reasons) {
        String code = 'N/A';
        String reasonText = reason.supplementaryInformation;
        Datetime cancellationTime;
        if (reason.reasonCode != null) {
          code = reason.reasonCode;
        }
        if (reasonText?.length() > 2000) {
          reasonText = reasonText.substring(0, 2000);
        }
        if (isoCancellationTime != null) {
          try {
            cancellationTime = DateUtils.isoDatetimeToApexDateTime(
              isoCancellationTime
            );
          } catch (Exception e) {
          }
        }

        result.add(
          new FlightIrregularities__c(
            Code__c = code,
            Reason__c = reasonText,
            Type__c = 'Cancellation ' + additionalInfo,
            Cancellation_Time__c = cancellationTime
          )
        );
      }
    } else {
      // Cancelled no reason
      result.add(
        new FlightIrregularities__c(
          Code__c = 'N/A',
          Reason__c = '',
          Type__c = 'Cancellation ' + additionalInfo
        )
      );
    }
    return result;
  }
}
