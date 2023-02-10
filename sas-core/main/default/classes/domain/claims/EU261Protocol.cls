public without sharing class EU261Protocol {
  public enum DenialReason {
    CANCELLEDWELLINTIME,
    NOTWITHINSASCONTROL,
    NOTFILEDONTIME,
    CUSTOMERCANCELLED,
    NOTOUTSIDETIMEFRAME,
    DELAYTOOSMALL,
    NODELAYORCANCELLATION
  }

  public Flight claimFlight;
  public Trip initialTrip;
  public Trip replacementTrip;
  public FlightIrregularity irregularity;
  public Integer minutesEarlyOnDeparture;
  public Integer minutesLateOnArrival;
  public Integer flightDistanceInKm;
  public Boolean isOutsideTimeFrame;
  public Boolean compensationIsHalved;
  public Integer maxDelayForHalved;
  public EU261Claim.Decision decision;
  public DenialReason denialReason;
  public Claim claimObj;
  public Integer claimFilingTimeLimit;
  public Integer daysUntilFlightWhenInformedOfCancellation;
  public Integer delayWithinSASControl;
  public String delayExplanation;

  public EU261Protocol() {
  }

  public String getReport() {
    List<String> explanation = new List<String>();

    if (this.decision == null) {
      return 'Claim has not yet been handled';
    }

    switch on this.decision.verdict {
      when Unhandled {
        return 'Claim has not yet been handled';
      }
      when EligibleForCompensation {
        explanation.addAll(getEligibilityExplanation());
      }
      when PossiblyEligibleForCompensation {
        explanation.addAll(getEligibilityExplanation());
        explanation.addAll(getCaveats());
      }
      when IneligibleForCompensation {
        explanation.addAll(getIneligibilityExplanation());
      }
      when ReimbursementOnly {
        // TODO
      }
      when UnableToHandle {
        explanation.add('Claim cannot be handled.');
      }
      when else {
        throw new EU261Claim.AutomationException(
          'Unsupported verdict for protocol'
        );
      }
    }

    List<String> report = new List<String>();
    report.add('Automation report\n');
    report.addAll(explanation);
    report.add('\n');

    return String.join(report, '');
  }

  private List<String> getCaveats() {
    List<String> toReturn = new List<String>{};
    toReturn.add(
      '\nThere are caveats which need to be addressed before paying out compensation.'
    );
    for (EU261Claim.SemiAutomationReason caveat : decision.caveats) {
      switch on caveat {
        when RequiresPowerOfAttorney {
          toReturn.add(
            ' The claimant might not be able to claim for all passengers.'
          );
        }
      } // TODO: Maybe extend or remove
    }

    return toReturn;
  }

  private List<String> getEligibilityExplanation() {
    List<String> toReturn = new List<String>();

    if (EU261Claim.CANCELLATION_CLAIM_TYPES.contains(claimObj.type)) {
      toReturn.add(getCancellationInfo());
      toReturn.addAll(getDetailedExplanation());
    } else if (EU261Claim.DELAY_CLAIM_TYPES.contains(claimObj.type)) {
      toReturn.addAll(getDelayInfo());
      toReturn.addAll(getDetailedExplanationDelay());
    }

    return toReturn;
  }

  private List<String> getIneligibilityExplanation() {
    List<String> toReturn = new List<String>();
    if (EU261Claim.CANCELLATION_CLAIM_TYPES.contains(claimObj.type)) {
      toReturn.add(getCancellationInfo());
    }
    if (EU261Claim.CANCELLATION_CLAIM_TYPES.contains(claimObj.type)) {
      toReturn.addAll(getDelayInfo());
    }

    switch on denialReason {
      when CANCELLEDWELLINTIME {
        toReturn.addAll(getCancelledWellInTimeExplanation());
      }
      when NOTWITHINSASCONTROL {
        toReturn.addAll(getNotWithinControlExplanation());
      }
      when NOTFILEDONTIME {
        toReturn.addAll(getNotFiledInTimeExplanation());
      }
      when CUSTOMERCANCELLED {
        toReturn.addAll(getCustomerCancelledExplanation());
        // toReturn.addAll(getDetailedExplanation());
      }
      when NOTOUTSIDETIMEFRAME {
        toReturn.addAll(getDetailedExplanation());
        toReturn.addAll(getNotOutsideTimeFrameExplanation());
      }
      when DELAYTOOSMALL {
        toReturn.add(this.delayExplanation);
      }
      when NODELAYORCANCELLATION {
        toReturn.addAll(getNoDelayOrCancellationExplanation());
      }
      when else {
        throw new EU261Claim.AutomationException(
          'Unsupported ineligibility reason.'
        );
      }
    }

    return toReturn;
  }

  private List<String> getNoDelayOrCancellationExplanation() {
    List<String> toReturn = new List<String>();
    toReturn.add(
      this.claimFlight.tedsIdentifier.substring(0, 6) +
      ' was not cancelled and was not delayed.'
    );
    return toReturn;
  }

  private List<String> getCancelledWellInTimeExplanation() {
    List<String> toReturn = new List<String>();
    Datetime departureTime = claimFlight.scheduledDepartureTime;
    toReturn.add(
      'The flight was cancelled 14 days, or more, in advance. In accordance with the EU261 regulation, the passenger(s) is/are therefore not eligible for compensation.\n'
    );
    toReturn.add('Time of departure for the first flight in the trip: ');
    toReturn.add(StringUtils.dateTimeToReadable(departureTime) + '\n');
    toReturn.add('Time of cancellation:');
    toReturn.add(
      StringUtils.dateTimeToReadable(irregularity.cancellationTime) + '\n'
    );
    toReturn.add('Days between cancellation and departure: ');
    Decimal hoursBetween = DateUtils.getHoursBetween(
      departureTime,
      irregularity.cancellationTime
    );
    Integer daysBetween = (hoursBetween / 24).intValue();
    toReturn.add(String.valueOf(daysBetween));
    return toReturn;
  }

  private List<String> getNotWithinControlExplanation() {
    List<String> toReturn = new List<String>();
    toReturn.add(irregularity.getOutsideControlExplanationCancellation());
    toReturn.add(
      ' The customer is therefore not entitled to EU261 compensation.'
    );
    return toReturn;
  }
  private List<String> getNotFiledInTimeExplanation() {
    List<String> toReturn = new List<String>();
    Airport origin = this.initialTrip.originAirport;
    Airport destination = this.initialTrip.destinationAirport;
    Date dateFiled = claimObj.createdDate.date();
    Date dateOfClaimFlight = claimFlight.scheduledDepartureTime.date();
    Date lastDateToFile = dateOfClaimFlight.addMonths(
      this.claimFilingTimeLimit
    );
    String lastDateInfo = String.valueOf(lastDateToFile).substringBefore(' ');
    String dateFiledInfo = String.valueOf(dateFiled).substringBefore(' ');

    toReturn.add('The claim was not filed on time.\n');
    toReturn.add(
      'As the customer departed ' +
      origin.tedsIdentifier +
      ' (' +
      origin.countryName +
      ') and arrived at ' +
      destination.tedsIdentifier +
      ' (' +
      destination.countryName +
      ').\n'
    );
    toReturn.add(
      'The last date when the claim had to be filed was the ' +
      lastDateInfo +
      '.'
    );
    toReturn.add('However, the claim was filed the ' + dateFiledInfo + '.');

    return toReturn;
  }
  private List<String> getCustomerCancelledExplanation() {
    List<String> toReturn = new List<String>();
    Trip.CancellationTime cancellationInfo = this.initialTrip.cancellationTimeInfo;
    String meansOfCancellation = SegmentEvent.getOfficeCodeExplanation(
      cancellationInfo.officeRemoving
    );
    String customerCancellationTime = StringUtils.dateTimeToReadable(
      cancellationInfo.removed
    );
    String flightCancellationTime = StringUtils.dateTimeToReadable(
      irregularity.cancellationTime
    );

    toReturn.add('The customer cancelled the flight.\n');
    toReturn.add(
      'The ' +
      customerCancellationTime +
      ' ' +
      meansOfCancellation +
      '. The flight was cancelled by SAS at a later time (' +
      flightCancellationTime +
      ').'
    );
    toReturn.add(
      ' The customer is therefore not entitled to compensation in accordance with the EU261 regulation.'
    );

    return toReturn;
  }
  private List<String> getNotOutsideTimeFrameExplanation() {
    List<String> toReturn = new List<String>();
    toReturn.add(
      'The offered rebooking is not outside the timeframe allowed by EU261.\n'
    );
    toReturn.add(
      'The customer was advised of the cancellation ' +
      String.valueOf(daysUntilFlightWhenInformedOfCancellation) +
      ' days before the departure of the flight. '
    );
    toReturn.add(
      'The timeframe permitted by the EU261 regulation is therefore '
    );
    if (
      daysUntilFlightWhenInformedOfCancellation <= 14 &&
      daysUntilFlightWhenInformedOfCancellation > 7
    ) {
      toReturn.add('2 hours early departure and 4 hours late arrival.');
    } else if (daysUntilFlightWhenInformedOfCancellation <= 7) {
      toReturn.add('1 hours early departure and 2 hours late arrival.');
    } else {
      throw new EU261Claim.AutomationException(
        'Invalid cancellation time for denial "outside timeframe"'
      );
    }
    toReturn.add(
      ' Since the customer departed and arrived within this timeframe they are not entitled to EU261 compensation.'
    );

    return toReturn;
  }

  private String getCompensationExplanation() {
    String explanation = 'As the flight distance was ';
    explanation += String.valueOf(flightDistanceInKm) + 'km. ';
    explanation += 'The passenger';
    Set<ClaimCustomer> customers = this.decision.compensationPerCustomerInEUR.keySet();
    if (customers.size() == 1) {
      explanation += ' is ';
    } else {
      explanation += 's are ';
    }
    explanation += 'entitled to the following:\n';
    for (ClaimCustomer cc : customers) {
      Money m = this.decision.compensationPerCustomerInEUR.get(cc);
      explanation +=
        cc.firstName +
        ' ' +
        cc.lastName +
        ' is compensated ' +
        m.amount +
        ' ' +
        m.currencyCode +
        '.\n';
    }

    explanation += 'In accordance with the EU261 regulation.';

    return explanation;
  }

  public String getFlightPlanHistory() {
    String toReturn = '';
    toReturn += buildFlightPlan(this.initialTrip);

    if (this.replacementTrip == null) {
      toReturn += '\nThere was no replacement flight plan.\n';
    } else {
      toReturn += '\nThe offered replacement for this trip was:\n';
      toReturn += buildFlightPlan(this.replacementTrip);
    }

    return toReturn;
  }

  private List<String> getDetailedExplanation() {
    List<String> flightPlan = new List<String>();
    List<String> delayInfo = new List<String>();
    List<String> compensationInfo = new List<String>();

    flightPlan.add('The original flight plan was:\n');
    flightPlan.add(buildFlightPlan(this.initialTrip));

    if (this.replacementTrip == null) {
      flightPlan.add('\nThere was no replacement flight plan.\n');

      compensationInfo.add(getCompensationExplanation());
    } else {
      flightPlan.add('\nThe offered replacement for this trip was:\n');
      flightPlan.add(buildFlightPlan(this.replacementTrip));
      delayInfo = getDelayInfoCancellation();

      if (isOutsideTimeFrame) {
        compensationInfo.add(getCompensationExplanation());

        if (compensationIsHalved) {
          compensationInfo.add(
            ' The compensation is halved as the offered rebooking meant a delay of '
          );
          compensationInfo.add(String.valueOf(maxDelayForHalved));
          compensationInfo.add(
            ' minutes, or less, and the flight distance was '
          );
          compensationInfo.add(String.valueOf(flightDistanceInKm));
          compensationInfo.add('km.');
        }
      }
    }

    List<String> toReturn = new List<String>();
    toReturn.add('Flight plan:\n');
    toReturn.addAll(flightPlan);
    if (delayInfo.size() > 0) {
      toReturn.add('\nDelay:');
      toReturn.addAll(delayInfo);
    }
    toReturn.add('\nCompensation:\n');
    toReturn.addAll(compensationInfo);

    return toReturn;
  }

  // TODO
  private List<String> getDetailedExplanationDelay() {
    List<String> toReturn = new List<String>();
    return toReturn;
  }

  private String getCancellationInfo() {
    String cancellationInfo = '\n';
    cancellationInfo += this.claimFlight.tedsIdentifier.substringBefore('-');
    cancellationInfo +=
      ' from ' +
      this.claimFlight.departureAirport +
      ' to ' +
      this.claimFlight.arrivalAirport;
    cancellationInfo +=
      ' was cancelled because of ' +
      irregularity.getExplanation() +
      ' the ' +
      StringUtils.dateTimeToReadable(irregularity.cancellationTime) +
      '.\n';
    return cancellationInfo;
  }

  // TODO
  private List<String> getDelayInfo() {
    return new List<String>();
  }

  private List<String> getDelayInfoCancellation() {
    List<String> delayInfo = new List<String>();
    String earlyInfo = '';
    String lateInfo = '';
    if (minutesEarlyOnDeparture > 120) {
      earlyInfo = '120+';
    } else {
      earlyInfo = String.valueOf(minutesEarlyOnDeparture);
    }
    if (minutesLateOnArrival > 240) {
      lateInfo = '240+';
    } else {
      lateInfo = String.valueOf(minutesLateOnArrival);
    }

    if (minutesEarlyOnDeparture > 0) {
      delayInfo.add('\nThe passenger(s) departed ');
      delayInfo.add(earlyInfo);
      delayInfo.add(' minutes earlier than planned.\n');
    }

    if (minutesLateOnArrival > 0) {
      delayInfo.add('\nThe passenger(s) arrived ');
      delayInfo.add(lateInfo);
      delayInfo.add(' minutes later than planned.\n');
    }

    delayInfo.add('This means that the new flight plan was ');
    if (!isOutsideTimeFrame) {
      delayInfo.add('not ');
    }
    delayInfo.add('outside the timeframe allowed by the EU261 regulation.');

    return delayInfo;
  }

  private static String buildFlightPlan(Trip t) {
    if (t == null) {
      return 'No flights';
    }

    List<String> totalFlightPlan = new List<String>();
    for (Trip.Leg l : t.sortedLegs) {
      String flightPlan = 'Flight plan:\n';
      String actualDeparture = '';
      String actualArrival = '';
      Flight f = l.flight;
      if (f.actualDepartureTime != null) {
        actualDeparture = StringUtils.dateTimeToReadable(f.actualDepartureTime);
      }
      if (f.actualArrivalTime != null) {
        actualArrival = StringUtils.dateTimeToReadable(f.actualArrivalTime);
      }

      String departureTime = StringUtils.dateTimeToReadable(
        f.scheduledDepartureTime
      );
      String arrivalTime = StringUtils.dateTimeToReadable(
        f.scheduledArrivalTime
      );

      flightPlan +=
        f.tedsIdentifier.substringBefore('-') +
        ' ' +
        f.departureAirport +
        '-' +
        f.arrivalAirport +
        ' (scheduled: ' +
        departureTime +
        ' to ' +
        arrivalTime;

      if (actualDeparture != '' && actualArrival != '') {
        flightPlan +=
          ', actual: ' +
          actualDeparture +
          ' to ' +
          actualArrival +
          ')';
      } else {
        flightPlan += ')';
      }
      totalFlightPlan.add(flightPlan);
    }

    return String.join(totalFlightPlan, '\n');
  }
}
