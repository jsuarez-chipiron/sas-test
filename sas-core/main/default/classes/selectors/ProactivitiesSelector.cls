public inherited sharing class ProactivitiesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Proactivity__c.Id,
      Proactivity__c.Name,
      Proactivity__c.Bank_Account_Number__c,
      Proactivity__c.Booking_Reference__c,
      Proactivity__c.Email__c,
      Proactivity__c.EuroBonus_Number__c,
      Proactivity__c.Flight_Id__c,
      Proactivity__c.Claim_Firm__c,
      Proactivity__c.Note__c,
      Proactivity__c.Passenger_Name__c,
      Proactivity__c.Phone_Number__c,
      Proactivity__c.PIR__c,
      Proactivity__c.Type__c,
      Proactivity__c.Airport__c,
      Proactivity__c.Match_Flights_Arriving_To_Airport__c,
      Proactivity__c.Match_Flights_Departing_Airport__c,
      Proactivity__c.From_Date__c,
      Proactivity__c.To_Date__c,
      Proactivity__c.Cancellation_Code__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Proactivity__c.SObjectType;
  }

  public static ProactivitiesSelector newInstance() {
    return (ProactivitiesSelector) SAS_Service_Application.Selector.newInstance(
      Proactivity__c.SObjectType
    );
  }

  public List<Proactivity__c> selectById(Set<Id> ids) {
    return (List<Proactivity__c>) selectSObjectsById(ids);
  }

  public List<Proactivity__c> selectByCaseId(Id caseId) {
    Map<Proactivity__c, String> reasonToProactivites = selectByCaseIdWithMatchingReasons(
      caseId
    );
    return new List<Proactivity__c>(reasonToProactivites.keySet());
  }

  public Map<Proactivity__c, String> selectByCaseIdWithMatchingReasons(
    Id caseId
  ) {
    LIA_Claim__c claim;
    ClaimsSelector claims = ClaimsSelector.newInstance();
    CasesSelector cases = CasesSelector.newInstance();
    Set<String> queryParts = new Set<String>{};

    Id directlyLinkedProactivityId;
    try {
      directlyLinkedProactivityId = cases.selectById(new Set<Id>{ caseId })[0]
        .Proactivity__c;
    } catch (Exception e) {
      // The case does not exist (should not happen)
    }

    if (directlyLinkedProactivityId != null) {
      queryParts.add('Id = :directlyLinkedProactivityId');
    }

    try {
      claim = claims.selectByCaseIdWithCustomers(new Set<Id>{ caseId })[0];
    } catch (Exception e) {
      if (directlyLinkedProactivityId != null) {
        List<Proactivity__c> directlyLinkedProactivity = (List<Proactivity__c>) Database.query(
          newQueryFactory()
            .setCondition('Id = :directlyLinkedProactivityId')
            .toSOQL()
        );
        if (directlyLinkedProactivity.size() != 0) {
          return new Map<Proactivity__c, String>{
            directlyLinkedProactivity[0] => 'Directly linked'
          };
        }
      }

      return new Map<Proactivity__c, String>{};
    }

    String claimFlightNumber;
    String flightId1 = null;
    String flightId2 = null;
    if (claim.Flight_Number__c != null) {
      claimFlightNumber = Flights.normalizeFlightNumber(claim.Flight_Number__c);
      flightId1 = claimFlightNumber != null &&
        claim.Flight_Date__c != null
        ? claimFlightNumber +
          '-' +
          String.valueOf(claim.Flight_Date__c).remove('-')
        : null;
      flightId2 = claimFlightNumber != null &&
        claim.Flight_Date__c != null
        ? claimFlightNumber + '-' + String.valueOf(claim.Flight_Date__c)
        : null;
    }

    List<String> passengerNames = new List<String>();
    if (claim.Customers__r != null) {
      for (Customer__c customer : claim.Customers__r) {
        if (customer.Name != null) {
          passengerNames.add(customer.Name);
        }
      }
    }

    // Get query parameters related to claim
    String bankAccountNumber = claim.Bank_Account_Number__c;
    String bookingReference = claim.Liability_PNR__c;
    String email = claim.Contact_Email__c;
    String euroBonusNumber = claim.EuroBonus_Number__c;
    Id firm = claim.Claim_Firm__c;
    String phoneNumber = claim.Phone_Number__c;
    String pirNumber = claim.PIR__c;
    Map<Schema.SObjectField, String> claimFieldToQuery = new Map<Schema.SObjectField, String>{
      LIA_Claim__c.Bank_Account_Number__c => 'Bank_Account_Number__c = :bankAccountNumber',
      LIA_Claim__c.Liability_PNR__c => 'Booking_Reference__c = :bookingReference',
      LIA_Claim__c.Contact_Email__c => 'Email__c = :email',
      LIA_Claim__c.EuroBonus_Number__c => 'EuroBonus_Number__c = :euroBonusNumber',
      LIA_Claim__c.Phone_Number__c => 'Phone_Number__c = :phoneNumber',
      LIA_Claim__c.PIR__c => 'PIR__c = :pirNumber'
    };

    for (Schema.SObjectField field : claimFieldToQuery.keySet()) {
      if (!String.isBlank((String) claim.get(field))) {
        queryParts.add(claimFieldToQuery.get(field));
      }
    }

    if (firm != null) {
      queryParts.add('Claim_Firm__c = :firm');
    }

    Flight__c claimFlight;
    List<Flight__c> flightsConnectedToTheClaim = new List<Flight__c>{};
    if (claim.Liability_PNR__c != null) {
      flightsConnectedToTheClaim = FlightsSelector.newInstance()
        .selectByBookingReference(new Set<String>{ claim.Liability_PNR__c });
    }

    // Match on any flight in the booking:
    Set<Id> flightIds = new Set<Id>{};
    Set<String> stringFlightIds = new Set<String>{};
    for (Flight__c f : flightsConnectedToTheClaim) {
      List<String> simpleFlightIds = Flights.TEDSIdToSimpleFlightIds(
        f.TEDS_Identifier__c
      );
      stringFlightIds.addAll(simpleFlightIds);
      if (simpleFlightIds.contains(flightId1)) {
        claimFlight = f;
      }
      flightIds.add(f.Id);
    }
    if (flightId1 != null) {
      stringFlightIds.add(flightId2);
    }
    if (flightId1 != null) {
      stringFlightIds.add(flightId2);
    }

    // Match on claim flight (Two flight ids to handle different input formats):
    queryParts.add('Flight_Id__c IN :stringFlightIds');

    if (passengerNames.size() != 0) {
      queryParts.add('Passenger_Name__c IN :passengerNames');
    }

    if (
      claimFlight == null &&
      claimFlightNumber != null &&
      claim.Flight_Date__c != null
    ) {
      FlightsSelector flights = FlightsSelector.newInstance();
      try {
        claimFlight = flights.selectByFlightNumberAndDate(
          claimFlightNumber,
          claim.Flight_Date__c
        )[0];
        flightsConnectedToTheClaim.add(claimFlight);
        flightIds.add(claimFlight.Id);
      } catch (Exception e) {
        // No flight matches the claim
      }
    }

    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities = new Map<Id, List<FlightIrregularities__c>>{};

    if (flightsConnectedToTheClaim.size() > 0) {
      List<FlightIrregularities__c> irregularities = FlightIrregularitiesSelector.newInstance()
        .selectByFlightId(flightIds);

      FlightIrregularities irregs = new FlightIrregularities(irregularities);
      flightIdToIrregularities = irregs.getFlightIdToIrregularities();
    }

    List<FlightQuery> flightQueriesMetaData = new List<FlightQuery>{};
    for (Flight__c f : flightsConnectedToTheClaim) {
      FlightQuery flightQ = getFlightQuery(
        f,
        flightIdToIrregularities.get(f.Id)
      );

      if (!String.isBlank(flightQ.query)) {
        queryParts.add(flightQ.query);
        flightQueriesMetaData.add(flightQ);
      }
    }

    // Avoid db calls
    if (queryParts.size() == 0) {
      return new Map<Proactivity__c, String>{};
    }

    String whereQuery = buildQuery(queryParts);

    List<Proactivity__c> proactivites = (List<Proactivity__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );

    Map<Proactivity__c, String> proactivityToReason = getMatchingReasons(
      claim,
      proactivites,
      flightQueriesMetaData,
      stringFlightIds,
      passengerNames,
      directlyLinkedProactivityId
    );

    return proactivityToReason;
  }

  private class FlightQuery {
    public String query;
    public Flight__c flight;
    public List<String> cancellationCodes;

    public FlightQuery(String q, Flight__c f, List<String> ccs) {
      this.query = q;
      this.flight = f;
      this.cancellationCodes = ccs;
    }
  }

  private static FlightQuery getFlightQuery(
    Flight__c flight,
    List<FlightIrregularities__c> flightIrregularities
  ) {
    String airportQuery = '';
    List<String> cancellationCodes = new List<String>{};

    if (flight != null) {
      String arrivalTime = String.valueOf(
        flight.Scheduled_Arrival_Time__c.date()
      );
      String departureTime = String.valueOf(
        flight.Scheduled_Departure_Time__c.date()
      );

      String fromAirport = flight.Departure_Airport__c;
      String toAirport = flight.Arrival_Airport__c;
      String departingQuery =
        '(From_Date__c <= ' +
        departureTime +
        ' AND To_Date__c >= ' +
        departureTime +
        ' AND Match_Flights_Departing_Airport__c = TRUE AND Airport__c = \'' +
        fromAirport +
        '\')';
      String arrivingQuery =
        '(From_Date__c <= ' +
        arrivalTime +
        ' AND To_Date__c >= ' +
        arrivalTime +
        ' AND Match_Flights_Arriving_To_Airport__c = TRUE AND Airport__c = \'' +
        toAirport +
        '\')';

      if (flightIrregularities != null) {
        for (FlightIrregularities__c irregularity : flightIrregularities) {
          if (irregularity.Code__c != null) {
            cancellationCodes.add(irregularity.Code__c);
          }
        }
      }

      if (!String.isBlank(fromAirport)) {
        airportQuery = departingQuery;
      }

      if (!String.isBlank(toAirport)) {
        if (airportQuery == '') {
          airportQuery = arrivingQuery;
        } else {
          airportQuery += ' OR ' + arrivingQuery;
        }
      }

      String cancellationCodeRow = '';
      for (String cc : cancellationCodes) {
        cancellationCodeRow = buildReasons(
          cancellationCodeRow,
          '\'' +
          cc +
          '\''
        );
      }

      String cancellationCodeQuery =
        '((From_Date__c <= ' +
        arrivalTime +
        ' AND To_Date__c >= ' +
        departureTime +
        ') AND Cancellation_Code__c IN (' +
        cancellationCodeRow +
        '))';
      // If a proactivity has both airport and cancellation code matcher both of them must match
      if (cancellationCodes.size() != 0) {
        airportQuery =
          '((' +
          airportQuery +
          ') AND ' +
          cancellationCodeQuery +
          ') OR ((' +
          cancellationCodeQuery +
          ') AND Match_Flights_Departing_Airport__c != TRUE AND Match_Flights_Arriving_To_Airport__c != TRUE) OR ((' +
          airportQuery +
          ') AND Cancellation_Code__c = \'\')';
      } else {
        airportQuery =
          '((' +
          airportQuery +
          ') AND Cancellation_Code__c = \'\')';
      }
    }

    return new FlightQuery(airportQuery, flight, cancellationCodes);
  }

  private static String buildQuery(Set<String> queryParts) {
    String query = '';
    for (String queryPart : queryParts) {
      if (String.isBlank(query)) {
        query += queryPart;
      } else {
        query += ' OR ' + queryPart;
      }
    }
    return query;
  }

  private static Map<Proactivity__c, String> getMatchingReasons(
    LIA_Claim__c claim,
    List<Proactivity__c> proactivites,
    List<FlightQuery> flightQueriesMetaData,
    Set<String> stringFlightIds,
    List<String> passengerNames,
    Id directlyLinkedProactivityId
  ) {
    Map<Proactivity__c, String> proactivityToReason = new Map<Proactivity__c, String>{};

    for (Proactivity__c p : proactivites) {
      Set<String> reasons = new Set<String>{};
      if (
        !String.isBlank(p.Bank_Account_Number__c) &&
        p.Bank_Account_Number__c == claim.Bank_Account_Number__c
      ) {
        reasons.add('Bank');
      }
      if (
        !String.isBlank(p.Booking_Reference__c) &&
        p.Booking_Reference__c == claim.Liability_PNR__c
      ) {
        reasons.add('PNR');
      }
      if (!String.isBlank(p.Email__c) && p.Email__c == claim.Contact_Email__c) {
        reasons.add('Email');
      }
      if (
        !String.isBlank(p.EuroBonus_Number__c) &&
        p.EuroBonus_Number__c == claim.EuroBonus_Number__c
      ) {
        reasons.add('EB');
      }
      if (
        !String.isBlank(p.Passenger_Name__c) &&
        passengerNames.contains(p.Passenger_Name__c)
      ) {
        reasons.add('Name');
      }
      if (
        !String.isBlank(p.Phone_Number__c) &&
        p.Phone_Number__c == claim.Phone_Number__c
      ) {
        reasons.add('Phone');
      }
      if (!String.isBlank(p.PIR__c) && p.PIR__c == claim.PIR__c) {
        reasons.add('PIR');
      }
      if (p.Claim_Firm__c != null && p.Claim_Firm__c == claim.Claim_Firm__c) {
        reasons.add('Firm');
      }
      if (p.Id != null && p.Id == directlyLinkedProactivityId) {
        reasons.add('Directly linked');
      }
      for (String flightId : stringFlightIds) {
        if (!String.isBlank(p.Flight_Id__c) && (p.Flight_Id__c == flightId)) {
          reasons.add('Flight');
        }
      }
      for (FlightQuery fq : flightQueriesMetaData) {
        String matchReasons = getFlightMatchReason(fq, p);
        if (!String.isBlank(matchReasons)) {
          reasons.add(matchReasons);
        }
      }

      String reasonsExplanation = '';
      for (String reason : reasons) {
        reasonsExplanation = buildReasons(reasonsExplanation, reason);
      }

      proactivityToReason.put(p, reasonsExplanation);
    }

    return proactivityToReason;
  }

  private static String getFlightMatchReason(FlightQuery fq, Proactivity__c p) {
    Flight__c flight = fq.flight;
    List<String> cancellationCodes = fq.cancellationCodes;
    String reasons = '';

    // This is much less complex than it looks. If it were not for nullchecks this could be done in 4 lines.
    if (!String.isBlank(p.Airport__c) && flight != null) {
      Boolean matchesActualDepartureTime = false;
      Boolean matchesScheduledDepartureTime = false;
      if (
        flight.Actual_Departure_Time__c != null &&
        flight.Actual_Arrival_Time__c != null
      ) {
        matchesActualDepartureTime = (flight.Actual_Departure_Time__c.date() >=
        p.From_Date__c &&
        flight.Actual_Departure_Time__c.date() <= p.To_Date__c);
      }
      if (
        flight.Scheduled_Departure_Time__c != null &&
        flight.Scheduled_Arrival_Time__c != null
      ) {
        matchesScheduledDepartureTime = (flight.Scheduled_Departure_Time__c.date() >=
        p.From_Date__c &&
        flight.Scheduled_Departure_Time__c.date() <= p.To_Date__c);
      }

      Boolean matchesActualArrivalTime = false;
      Boolean matchesScheduledArrivalTime = false;
      if (
        flight.Actual_Arrival_Time__c != null &&
        flight.Actual_Arrival_Time__c != null
      ) {
        matchesActualArrivalTime = (flight.Actual_Arrival_Time__c.date() >=
        p.From_Date__c &&
        flight.Actual_Arrival_Time__c.date() <= p.To_Date__c);
      }
      if (
        flight.Scheduled_Arrival_Time__c != null &&
        flight.Scheduled_Arrival_Time__c != null
      ) {
        matchesScheduledArrivalTime = (flight.Scheduled_Arrival_Time__c.date() >=
        p.From_Date__c &&
        flight.Scheduled_Arrival_Time__c.date() <= p.To_Date__c);
      }

      if (
        p.Airport__c == flight.Departure_Airport__c &&
        (matchesActualDepartureTime || matchesScheduledDepartureTime) &&
        p.Match_Flights_Departing_Airport__c
      ) {
        reasons = buildReasons(reasons, 'Departure airport');
      }

      if (
        p.Airport__c == flight.Arrival_Airport__c &&
        (matchesActualArrivalTime || matchesScheduledArrivalTime) &&
        p.Match_Flights_Arriving_To_Airport__c
      ) {
        reasons = buildReasons(reasons, 'Arrival airport');
      }
    }
    for (String cancellationCode : cancellationCodes) {
      if (cancellationCode == p.Cancellation_Code__c) {
        reasons = buildReasons(reasons, 'Code "' + cancellationCode + '"');
        break; // A proactivity can only have one code
      }
    }

    if (!String.isBlank(reasons)) {
      reasons =
        flight.TEDS_Identifier__c.substringBefore('-') +
        ': (' +
        reasons +
        ')';
    }
    return reasons;
  }

  private static String buildReasons(String reasons, String reason) {
    if (!String.isBlank(reasons)) {
      return reasons + ', ' + reason;
    } else {
      return reason;
    }
  }
}
