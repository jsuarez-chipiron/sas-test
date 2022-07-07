public inherited sharing class ClaimsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      LIA_Claim__c.Id,
      LIA_Claim__c.Address_line_1__c,
      LIA_Claim__c.Address_line_2__c,
      LIA_Claim__c.Bank_Account_Holder_Name__c,
      LIA_Claim__c.Bank_Account_Number__c,
      LIA_Claim__c.Bank_Country__c,
      LIA_Claim__c.Bank_Name__c,
      LIA_Claim__c.BIC_Swift__c,
      LIA_Claim__c.Case__c,
      LIA_Claim__c.City__c,
      LIA_Claim__c.Claims_Exist_In_CARE_For_PNR__c,
      LIA_Claim__c.Claim_Firm__c,
      LIA_Claim__c.Compensation_Card_Number__c,
      LIA_Claim__c.Contact_Email__c,
      LIA_Claim__c.Contact_First_Name__c,
      LIA_Claim__c.Contact_Full_Name__c,
      LIA_Claim__c.Contact_Last_Name__c,
      LIA_Claim__c.Country__c,
      LIA_Claim__c.Currency__c,
      LIA_Claim__c.Customer_Claim_Category__c,
      LIA_Claim__c.Customer_Claim_Type__c,
      LIA_Claim__c.Customer_s_Reference__c,
      LIA_Claim__c.EuroBonus_Number__c,
      LIA_Claim__c.Flight_Date__c,
      LIA_Claim__c.Flight_Number__c,
      LIA_Claim__c.Last_Checked_Claims_From_CARE__c,
      LIA_Claim__c.Liability_PNR__c,
      LIA_Claim__c.Phone_Number__c,
      LIA_Claim__c.PIR__c,
      LIA_Claim__c.Postal_Code__c,
      LIA_Claim__c.Preferred_Compensation_Method__c,
      LIA_Claim__c.RecordTypeId,
      LIA_Claim__c.Type_of_Customer__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return LIA_Claim__c.SObjectType;
  }

  public static ClaimsSelector newInstance() {
    return (ClaimsSelector) SAS_Service_Application.Selector.newInstance(
      LIA_Claim__c.SObjectType
    );
  }

  public List<LIA_Claim__c> selectById(Set<Id> ids) {
    return (List<LIA_Claim__c>) selectSObjectsById(ids);
  }

  public List<LIA_Claim__c> selectByIdWithCustomers(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory().setCondition('Id IN :ids');
    fflib_QueryFactory customersQF = new CustomersSelector()
      .addQueryFactorySubselect(claimsQF);

    return (List<LIA_Claim__c>) Database.query(claimsQF.toSOQL());
  }

  public List<LIA_Claim__c> selectByIdWithSettlements(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory().setCondition('Id IN :ids');
    fflib_QueryFactory settlementsQF = new SettlementsSelector()
      .addQueryFactorySubselect(claimsQF);

    return (List<LIA_Claim__c>) Database.query(claimsQF.toSOQL());
  }

  public List<LIA_Claim__c> selectByCaseIdWithCustomers(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory()
      .setCondition('Case__c in :ids');
    fflib_QueryFactory customersQF = new CustomersSelector()
      .addQueryFactorySubselect(claimsQF);

    return (List<LIA_Claim__c>) Database.query(claimsQF.toSOQL());
  }

  public List<LIA_Claim__c> selectByProactivityId(Id proactivityId) {
    ProactivitiesSelector proactivities = ProactivitiesSelector.newInstance();
    Proactivity__c proactivity = proactivities.selectById(
      new Set<Id>{ proactivityId }
    )[0];

    String flightNumber;
    Date flightDate;

    if (!String.isBlank(proactivity.Flight_Id__c)) {
      flightNumber = proactivity.Flight_Id__c.substringBefore('-');
      flightDate = DateUtils.parseDateFromFlightId(proactivity.Flight_Id__c);
    }

    String bankAccountNumber = proactivity.Bank_Account_Number__c;
    String bookingReference = proactivity.Booking_Reference__c;
    String email = proactivity.Email__c;
    String euroBonusNumber = proactivity.EuroBonus_Number__c;
    String passengerName = proactivity.Passenger_Name__c;
    String phoneNumber = proactivity.Phone_Number__c;
    String pirNumber = proactivity.PIR__c;

    fflib_QueryFactory query = newQueryFactory();
    Map<Schema.SObjectField, String> proactivityFieldToQuery = new Map<Schema.SObjectField, String>{
      Proactivity__c.Bank_Account_Number__c => 'Bank_Account_Number__c = :bankAccountNumber',
      Proactivity__c.Booking_Reference__c => 'Liability_PNR__c = :bookingReference',
      Proactivity__c.Email__c => 'Contact_Email__c = :email',
      Proactivity__c.EuroBonus_Number__c => 'EuroBonus_Number__c = :euroBonusNumber',
      Proactivity__c.Phone_Number__c => 'Phone_Number__c = :phoneNumber',
      Proactivity__c.PIR__c => 'PIR__c = :pirNumber'
    };

    // Check directly linked cases with claims
    Set<Id> directlyLinkedCasesIds = new Set<Id>{};
    CasesSelector cases = CasesSelector.newInstance();
    List<Case> directlyLinkedCases = cases.selectByDirectlyLinkedProactivityId(
      new Set<Id>{ proactivityId }
    );
    for (Case c : directlyLinkedCases) {
      directlyLinkedCasesIds.add(c.Id);
    }

    String whereQuery = '';
    whereQuery = buildQuery(
      whereQuery,
      'Case__c IN :directlyLinkedCasesIds',
      directlyLinkedCasesIds.size() > 0
    );

    for (Schema.SObjectField field : proactivityFieldToQuery.keySet()) {
      whereQuery = buildQuery(
        whereQuery,
        proactivityFieldToQuery.get(field),
        !String.isBlank((String) proactivity.get(field))
      );
    }

    whereQuery = buildQuery(
      whereQuery,
      '(Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate)',
      !String.isBlank(flightNumber) && flightDate != null
    );

    CustomersSelector customers = CustomersSelector.newInstance();
    if (!String.isBlank(passengerName)) {
      List<Customer__c> matchingCustomers = customers.selectByName(
        new Set<String>{ passengerName }
      );
      if (matchingCustomers.size() > 0) {
        Set<Id> claimIdsFromCustomers = new Set<Id>();
        for (Customer__c c : matchingCustomers) {
          claimIdsFromCustomers.add(c.Claim__c);
        }

        whereQuery = buildQuery(
          whereQuery,
          'Id IN :claimIdsFromCustomers',
          true
        );
      }
    }

    List<LIA_Claim__c> flightClaimList = new List<LIA_Claim__c>();

    Boolean matchArriving = proactivity.Match_Flights_Arriving_To_Airport__c;
    Boolean matchDeparting = proactivity.Match_Flights_Departing_Airport__c;
    String airport = proactivity.Airport__c;
    Date fromDate = proactivity.From_Date__c;
    Date toDate = proactivity.To_Date__c;
    String cancellationCode = proactivity.Cancellation_Code__c;
    List<Id> bookingList = new List<Id>();
    List<Id> flightIdsWithMatchingCancellationCode = new List<Id>();
    List<Segment__c> allSegments = new List<Segment__c>();
    String arrivalQuery = '(Flight__r.Scheduled_Arrival_Time__c >= :fromDate AND Flight__r.Scheduled_Arrival_Time__c <= :toDate AND Flight__r.Arrival_Airport__c = :airport)';
    String departingQuery = '(Flight__r.Scheduled_Departure_Time__c >= :fromDate AND Flight__r.Scheduled_Departure_Time__c <= :toDate AND Flight__r.Departure_Airport__c = :airport)';
    String advancedMatcherQuery = '';

    if (matchArriving && matchDeparting) {
      advancedMatcherQuery += arrivalQuery + ' OR ' + departingQuery;
    } else if (matchArriving) {
      advancedMatcherQuery = arrivalQuery;
    } else if (matchDeparting) {
      advancedMatcherQuery = departingQuery;
    }

    if (cancellationCode != null) {
      List<FlightIrregularities__c> irregularityList = [
        SELECT Flight__c
        FROM FlightIrregularities__c
        WHERE Code__c = :cancellationCode
      ];

      for (FlightIrregularities__c fi : irregularityList) {
        flightIdsWithMatchingCancellationCode.add(fi.Flight__c);
      }
      if (advancedMatcherQuery.length() > 0) {
        advancedMatcherQuery =
          '(' +
          advancedMatcherQuery +
          ') AND Flight__r.Id IN :flightIdsWithMatchingCancellationCode';
      } else {
        advancedMatcherQuery = 'Flight__r.Id IN :flightIdsWithMatchingCancellationCode';
      }
    }

    if (!String.isBlank(advancedMatcherQuery)) {
      allSegments = Database.query(
        'SELECT Booking__r.Id FROM Segment__c WHERE ' + advancedMatcherQuery
      );
    }

    for (Segment__c s : allSegments) {
      bookingList.add(s.Booking__c);
    }

    flightClaimList = [
      SELECT Id, Case__c
      FROM LIA_Claim__c
      WHERE
        Case__c IN (
          SELECT Case__c
          FROM CaseToBooking__c
          WHERE Booking__r.Id IN :bookingList
        )
    ];

    if (whereQuery.length() == 0) {
      if (flightClaimList.size() != 0) {
        return flightClaimList;
      }
      return new List<LIA_Claim__c>{};
    }

    List<LIA_Claim__c> results = (List<LIA_Claim__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );

    results.addAll(flightClaimList);

    return results;
  }

  public List<LIA_Claim__c> selectSimilarClaimsByCaseId(Id caseId) {
    List<LIA_Claim__c> claims = selectByCaseIdWithCustomers(
      new Set<Id>{ caseId }
    );
    if (claims == null || claims.size() == 0) {
      return new List<LIA_Claim__c>();
    }

    LIA_Claim__c claim = claims[0];

    String bankAccountNumber = claim.Bank_Account_Number__c;
    String bookingReference = claim.Liability_PNR__c;
    String email = claim.Contact_Email__c;
    String euroBonusNumber = claim.EuroBonus_Number__c;
    Date flightDate = claim.Flight_Date__c;
    String flightNumber = claim.Flight_Number__c;
    //String passengerName = claim.Passenger_Name__c; // TODO: What should this be?
    String phoneNumber = claim.Phone_Number__c;
    String pirNumber = claim.PIR__c;

    String whereQuery = '';

    if (!String.isBlank(bankAccountNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Bank_Account_Number__c = :bankAccountNumber';
      } else {
        whereQuery += ' OR Bank_Account_Number__c = :bankAccountNumber';
      }
    }

    if (!String.isBlank(bookingReference)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Liability_PNR__c = :bookingReference';
      } else {
        whereQuery += ' OR Liability_PNR__c = :bookingReference';
      }
    }

    if (
      !String.isBlank(email) && claim.Type_of_Customer__c == 'Private customer'
    ) {
      // Email should be checked only for private customers.
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Contact_Email__c = :email';
      } else {
        whereQuery += ' OR Contact_Email__c = :email';
      }
    }

    if (!String.isBlank(euroBonusNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'EuroBonus_Number__c = :euroBonusNumber';
      } else {
        whereQuery += ' OR EuroBonus_Number__c = :euroBonusNumber';
      }
    }

    if (!String.isBlank(flightNumber) && flightDate != null) {
      if (String.isBlank(whereQuery)) {
        whereQuery += '(Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate)';
      } else {
        whereQuery += ' OR (Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate)';
      }
    }

    /*if (!String.isBlank(passengerName)) {
      List<Customer__c> matchingCustomers = customers.selectByName(
        new Set<String>{ passengerName }
      );
      if (matchingCustomers.size() > 0) {
        Set<Id> claimIdsFromCustomers = new Set<Id>();
        for (Customer__c c : matchingCustomers) {
          claimIdsFromCustomers.add(c.Claim__c);
        }
        if (String.isBlank(whereQuery)) {
          whereQuery += 'Id IN :claimIdsFromCustomers';
        } else {
          whereQuery += ' OR Id IN :claimIdsFromCustomers';
        }
      }
    }*/

    if (!String.isBlank(phoneNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Phone_Number__c = :phoneNumber';
      } else {
        whereQuery += ' OR Phone_Number__c = :phoneNumber';
      }
    }

    if (!String.isBlank(pirNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'PIR__c = :pirNumber';
      } else {
        whereQuery += ' OR PIR__c = :pirNumber';
      }
    }

    return (List<LIA_Claim__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );
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
}
