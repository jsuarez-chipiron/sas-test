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

    try {
      claim = claims.selectByCaseIdWithCustomers(new Set<Id>{ caseId })[0];
    } catch (Exception e) {
      new Map<Proactivity__c, String>{};
    }

    String flightId1 = claim.Flight_Number__c != null &&
      claim.Flight_Date__c != null
      ? claim.Flight_Number__c +
        '-' +
        String.valueOf(claim.Flight_Date__c).remove('-')
      : null;
    String flightId2 = claim.Flight_Number__c != null &&
      claim.Flight_Date__c != null
      ? claim.Flight_Number__c + '-' + String.valueOf(claim.Flight_Date__c)
      : null;

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

    String whereQuery = '';

    for (Schema.SObjectField field : claimFieldToQuery.keySet()) {
      whereQuery = buildQuery(
        whereQuery,
        claimFieldToQuery.get(field),
        !String.isBlank((String) claim.get(field))
      );
    }

    whereQuery = buildQuery(whereQuery, 'Claim_Firm__c = :firm', firm != null);

    // Two flight ids to handle different input formats.
    whereQuery = buildQuery(
      whereQuery,
      'Flight_Id__c = :flightId1',
      !String.isBlank(flightId1)
    );
    whereQuery = buildQuery(
      whereQuery,
      'Flight_Id__c = :flightId2',
      !String.isBlank(flightId2)
    );

    whereQuery = buildQuery(
      whereQuery,
      'Passenger_Name__c IN :passengerNames',
      passengerNames.size() != 0
    );

    // Get query parameters related to flight
    Date arrivalTime;
    Date departureTime;
    String fromAirport;
    String toAirport;
    List<String> cancellationCodes = new List<String>{};
    Flight__c flight;

    if (flightId1 != null) {
      FlightsSelector flights = FlightsSelector.newInstance();
      try {
        flight = flights.selectByFlightNumberAndDate(
          claim.Flight_Number__c,
          claim.Flight_Date__c
        )[0];
      } catch (Exception e) {
        // No flight matches the claim
      }
    }

    if (flight != null) {
      FlightIrregularitiesSelector flightIrregularities = FlightIrregularitiesSelector.newInstance();
      String departingQuery = '(From_Date__c <= :departureTime AND To_Date__c >= :departureTime AND Match_Flights_Departing_Airport__c = TRUE AND Airport__c = :fromAirport)';
      String arrivingQuery = '(From_Date__c <= :arrivalTime AND To_Date__c >= :arrivalTime AND Match_Flights_Arriving_To_Airport__c = TRUE AND Airport__c = :toAirport)';
      arrivalTime = flight.Scheduled_Arrival_Time__c.date();
      departureTime = flight.Scheduled_Departure_Time__c.date();
      fromAirport = flight.Departure_Airport__c;
      toAirport = flight.Arrival_Airport__c;

      List<FlightIrregularities__c> irregularities = flightIrregularities.selectByFlightNumberDateAndAirports(
        claim.Flight_Number__c,
        claim.Flight_Date__c,
        fromAirport,
        toAirport
      );

      for (FlightIrregularities__c irregularity : irregularities) {
        cancellationCodes.add(irregularity.Code__c);
      }

      String airportQuery = '';
      airportQuery = buildQuery(
        airportQuery,
        departingQuery,
        !String.isBlank(fromAirport)
      );
      airportQuery = buildQuery(
        airportQuery,
        arrivingQuery,
        !String.isBlank(toAirport)
      );

      String cancellationCodeQuery = '((From_Date__c <= :arrivalTime AND To_Date__c >= :departureTime) AND Cancellation_Code__c IN :cancellationCodes)';
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

      whereQuery = buildQuery(
        whereQuery,
        airportQuery,
        !String.isBlank(airportQuery)
      );
    }

    // Avoid db calls
    if (whereQuery.length() == 0) {
      return new Map<Proactivity__c, String>{};
    }

    List<Proactivity__c> proactivites = (List<Proactivity__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );

    Map<Proactivity__c, String> proactivityToReason = getMatchingReasons(
      claim,
      proactivites,
      flight,
      cancellationCodes,
      flightId1,
      flightId2,
      passengerNames
    );

    return proactivityToReason;
  }

  private static String buildQuery(
    String whereQuery,
    String queryToAdd,
    Boolean shouldBeAdded
  ) {
    if (shouldBeAdded) {
      if (String.isBlank(whereQuery)) {
        whereQuery += queryToAdd;
      } else {
        whereQuery += ' OR ' + queryToAdd;
      }
    }
    return whereQuery;
  }

  private static Map<Proactivity__c, String> getMatchingReasons(
    LIA_Claim__c claim,
    List<Proactivity__c> proactivites,
    Flight__c flight,
    List<String> cancellationCodes,
    String flightId1,
    String flightId2,
    List<String> passengerNames
  ) {
    Map<Proactivity__c, String> proactivityToReason = new Map<Proactivity__c, String>{};

    for (Proactivity__c p : proactivites) {
      String reasons = '';
      if (
        !String.isBlank(p.Bank_Account_Number__c) &&
        p.Bank_Account_Number__c == claim.Bank_Account_Number__c
      ) {
        reasons = buildReasons(reasons, 'Bank');
      }
      if (
        !String.isBlank(p.Booking_Reference__c) &&
        p.Booking_Reference__c == claim.Liability_PNR__c
      ) {
        reasons = buildReasons(reasons, 'PNR');
      }
      if (!String.isBlank(p.Email__c) && p.Email__c == claim.Contact_Email__c) {
        reasons = buildReasons(reasons, 'Email');
      }
      if (
        !String.isBlank(p.EuroBonus_Number__c) &&
        p.EuroBonus_Number__c == claim.EuroBonus_Number__c
      ) {
        reasons = buildReasons(reasons, 'EB');
      }
      if (
        !String.isBlank(p.Flight_Id__c) &&
        (p.Flight_Id__c == flightId1 ||
        p.Flight_Id__c == flightId2)
      ) {
        reasons = buildReasons(reasons, 'Flight');
      }
      if (
        !String.isBlank(p.Passenger_Name__c) &&
        passengerNames.contains(p.Passenger_Name__c)
      ) {
        reasons = buildReasons(reasons, 'Name');
      }
      if (
        !String.isBlank(p.Phone_Number__c) &&
        p.Phone_Number__c == claim.Phone_Number__c
      ) {
        reasons = buildReasons(reasons, 'Phone');
      }
      if (!String.isBlank(p.PIR__c) && p.PIR__c == claim.PIR__c) {
        reasons = buildReasons(reasons, 'PIR');
      }
      if (p.Claim_Firm__c != null && p.Claim_Firm__c == claim.Claim_Firm__c) {
        reasons = buildReasons(reasons, 'Firm');
      }
      if (
        !String.isBlank(p.Airport__c) &&
        p.Airport__c == flight.Departure_Airport__c &&
        ((flight.Actual_Departure_Time__c >= p.From_Date__c &&
        flight.Actual_Departure_Time__c <= p.To_Date__c) ||
        (flight.Scheduled_Departure_Time__c >= p.From_Date__c &&
        flight.Scheduled_Departure_Time__c <= p.To_Date__c)) &&
        p.Match_Flights_Departing_Airport__c
      ) {
        reasons = buildReasons(reasons, 'Departure airport');
      }
      if (
        !String.isBlank(p.Airport__c) &&
        p.Airport__c == flight.Arrival_Airport__c &&
        ((flight.Actual_Arrival_Time__c >= p.From_Date__c &&
        flight.Actual_Arrival_Time__c <= p.To_Date__c) ||
        (flight.Scheduled_Arrival_Time__c >= p.From_Date__c &&
        flight.Scheduled_Arrival_Time__c <= p.To_Date__c)) &&
        p.Match_Flights_Arriving_To_Airport__c
      ) {
        reasons = buildReasons(reasons, 'Arrival airport');
      }
      for (String cancellationCode : cancellationCodes) {
        if (cancellationCode == p.Cancellation_Code__c) {
          reasons = buildReasons(
            reasons,
            'Cancellation code "' +
            cancellationCode +
            '"'
          );
          break; // A proactivity can only have one code
        }
      }
      proactivityToReason.put(p, reasons);
    }

    return proactivityToReason;
  }

  private static String buildReasons(String reasons, String reason) {
    if (!String.isBlank(reasons)) {
      return reasons + ', ' + reason;
    } else {
      return reason;
    }
  }
}
