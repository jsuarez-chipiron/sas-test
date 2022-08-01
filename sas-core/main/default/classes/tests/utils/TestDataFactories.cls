@IsTest
public with sharing class TestDataFactories {
  /**
   * Create test bookings. Inserts all objects into DB.
   */
  public static List<Booking__c> createBookings(
    Integer amount,
    String bookingReference
  ) {
    List<Booking__c> newBookings = new List<Booking__c>();
    List<SObject> toInsert = new List<SObject>();

    Flight__c f = new Flight__c(TEDS_Identifier__c = C_Util.generateUUID());
    insert f;

    for (Integer i = 0; i < amount; i++) {
      Booking__c b = new Booking__c(
        Booking_Reference__c = bookingReference,
        TEDS_Identifier__c = bookingReference + String.valueOf(i)
      );
      newBookings.add(b);
    }
    insert newBookings;

    for (Integer i = 0; i < amount; i++) {
      Segment__c s = new Segment__c(
        Flight__c = f.Id,
        Booking__c = newBookings[i].Id,
        Identifier__c = String.valueOf(i)
      );
      toInsert.add(s);

      Passenger__c p = new Passenger__c(
        Booking__c = newBookings[i].Id,
        Identifier__c = String.valueOf(i)
      );
      toInsert.add(p);
    }
    insert toInsert;

    return newBookings;
  }

  public static List<IRR_MOD_TedsBooking> createParsedBookingData(
    String bookingReference,
    String euroBonusNumber
  ) {
    String ebNumber = '1234567890';
    if (euroBonusNumber != null) {
      ebNumber = euroBonusNumber;
    }

    String template = '{"id": "VKQLKR-20201126","reference": "{bookingReference}","type": "RoundTrip","isCancelled": false,"codsId": "000364992","travelAdmin": {"codsId": ""},"audit": {"created": {"officeId": "STOSK08RV","at": "2020-11-26T04:15:00Z"},"updated": {"officeId": "NCESK0553","at": "2021-02-19T22:25:00Z"}},"passengers": [{"id": "PT2","title": "MR","firstName": "GUSTAF","lastName": "DOUGLAS","contact": {"phone": [{"type": "APH","number": "+33492943368"},{"type": "APM","number": "+33492943368"},{"type": "APU","number": "+33492943368"},{"type": "APH","number": "+3312345879"},{"type": "APM","number": "+334647681157"},{"type": "APU","number": "+33123456897"}],"email": [{"type": "APE","address": "NO-REPLY_RECEIPT@AMADEUS.COM"},{"type": "APE","address": "NO-REPLY@AMADEUS.COM"}]},"frequentTraveler": {"euroBonus": [{"segmentIds": [],"carrier": "SK","tier": "EBB","number": "{euroBonusNumber}"}],"other": []},"specialServiceRequests": [],"segments": [{"segmentId": "ST1","isBoarded": false,"ticket": {"number": "117-2472136245","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "OSERSM"}},{"segmentId": "ST2","isBoarded": false,"ticket": {"number": "117-2472136245","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "TSERSM"}}]}],"trips": [{"type": "Outbound","segments": [{"id": "ST1","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK2569-20210410-ARN-CPH","operatingId": "SK2569-20210410-ARN-CPH","operatingCarrier": "SK","operatingFlightNumber": "2569","marketingCarrier": "SK","marketingFlightNumber": "2569","departure": {"station": "ARN","scheduledTime": {"utc": "2021-04-10T07:00:00Z","local": "2021-04-10T09:00:00"},"terminal": "5"},"arrival": {"station": "CPH","scheduledTime": {"utc": "2021-04-10T08:20:00Z","local": "2021-04-10T10:20:00"},"terminal": "3"}},"bookingClass": "O","serviceClass": "M"}]},{"type": "Inbound","segments": [{"id": "ST2","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK0402-20210420-CPH-ARN","operatingId": "SK0402-20210420-CPH-ARN","operatingCarrier": "SK","operatingFlightNumber": "0402","marketingCarrier": "SK","marketingFlightNumber": "0402","departure": {"station": "CPH","scheduledTime": {"utc": "2021-04-20T05:15:00Z","local": "2021-04-20T07:15:00"},"terminal": "3"},"arrival": {"station": "ARN","scheduledTime": {"utc": "2021-04-20T06:30:00Z","local": "2021-04-20T08:30:00"},"terminal": "5"}},"bookingClass": "T","serviceClass": "M"}]}]}';

    List<IRR_MOD_TedsBooking> toReturn = new List<IRR_MOD_TedsBooking>();
    toReturn.add(
      IRR_MOD_TedsBooking.parse(
        template.replace('{bookingReference}', bookingReference)
          .replace('{euroBonusNumber}', ebNumber)
      )
    );
    return toReturn;
  }

  public class CasesClaims {
    public List<Case> cases { get; set; }
    public List<LIA_Claim__c> claims { get; set; }

    CasesClaims(List<Case> cases, List<LIA_Claim__c> claims) {
      this.cases = cases;
      this.claims = claims;
    }
  }

  public class CasesClaimsBookings {
    public List<Case> cases { get; set; }
    public List<LIA_Claim__c> claims { get; set; }
    public List<Booking__c> bookings { get; set; }

    CasesClaimsBookings(
      List<Case> cases,
      List<LIA_Claim__c> claims,
      List<Booking__c> bookings
    ) {
      this.cases = cases;
      this.claims = claims;
      this.bookings = bookings;
    }
  }

  /**
   * Creates a collection of case and claim pairs and inserts them to the DB.
   *
   * @param count Number of case-claim pairs to create.
   * @param fieldsForCases Map of field to field value for fields to set for all created cases.
   * @param fieldsForClaims Map of field to field value for fields to set for all created claims.
   */
  public static CasesClaims createCasesWithClaims(
    Integer count,
    Map<Schema.SObjectField, Object> fieldsForCases,
    Map<Schema.SObjectField, Object> fieldsForClaims
  ) {
    List<Case> casesToCreate = new List<Case>();
    List<LIA_Claim__c> claimsToCreate = new List<LIA_Claim__c>();

    for (Integer i = 0; i < count; i++) {
      Case c = new Case(
        Origin = 'Form - Claims SE',
        RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
        Status = Cases.STATUS_IN_PROGRESS,
        SuppliedEmail = 'test@example.com'
      );
      LIA_Claim__c claim = new LIA_Claim__c(
        Customer_Claim_Category__c = 'Flight disruptions',
        Liability_PNR__c = 'ABC123',
        PIR__c = 'ARNSK12345',
        RecordTypeId = Claims.getRecordTypeId(Claims.RecordType.CustomerClaim)
      );

      if (fieldsForCases != null) {
        for (Schema.SObjectField field : fieldsForCases.keySet()) {
          c.put(field, fieldsForCases.get(field));
        }
      }

      if (fieldsForClaims != null) {
        for (Schema.SObjectField field : fieldsForClaims.keySet()) {
          claim.put(field, fieldsForClaims.get(field));
        }
      }
      casesToCreate.add(c);
      claimsToCreate.add(claim);
    }
    List<SObject> allToCreate = new List<SObject>();
    allToCreate.addAll((List<SObject>) casesToCreate);
    allToCreate.addAll((List<SObject>) claimsToCreate);
    insert allToCreate;

    for (Integer i = 0; i < count; i++) {
      Case c = casesToCreate[0];
      LIA_Claim__c claim = claimsToCreate[0];
      c.LIA_Claim__c = claim.Id;
      claim.Case__c = c.Id;
    }

    update allToCreate;

    return new CasesClaims(casesToCreate, claimsToCreate);
  }

  /**
   * Creates a collection of case, claims, bookings, flights and customers and inserts them to the DB.
   * @param fieldsForClaims A list with one instance of a map of field to value per object you want to create.
   * @param fieldsForCases Like fieldsForClaims but for Cases.
   * @param fieldsForBookings Like fieldsForClaims but for Bookings.
   * @param fieldsForFlightsPerBooking A list with lists of one instance of a map of field to value per object you want to create. So, if you create two bookings, one with one flight and one with two flights you will pass in a list with two lists, where one of the lists has the fields for one flight and one for two flights.
   * @param fieldsForCustomersPerBooking Like fieldsForFlightsPerBooking.
   *
   */
  public static CasesClaimsBookings createClaimsWithCasesBookingsFlightsAndCustomers(
    List<Map<Schema.SObjectField, Object>> fieldsForClaims,
    List<Map<Schema.SObjectField, Object>> fieldsForCases,
    List<Map<Schema.SObjectField, Object>> fieldsForBookings,
    List<List<Map<Schema.SObjectField, Object>>> fieldsForFlightsPerBooking,
    List<List<Map<Schema.SObjectField, Object>>> fieldsForCustomersPerBooking
  ) {
    Integer count = fieldsForClaims.size();
    // List of categories of lists of fields for a single object
    List<List<Map<Schema.SObjectField, Object>>> fieldsForEverySingleObject = new List<List<Map<Schema.SObjectField, Object>>>{
      fieldsForClaims,
      fieldsForCases,
      fieldsForBookings
    };
    // List of categories of lists of lists of fields for a single object
    List<List<List<Map<Schema.SObjectField, Object>>>> fieldsForEveryMultiObject = new List<List<List<Map<Schema.SObjectField, Object>>>>{
      fieldsForFlightsPerBooking,
      fieldsForCustomersPerBooking
    };
    Date today = Date.today();

    List<SObject> claimsToCreate = new List<SObject>();
    List<SObject> casesToCreate = new List<SObject>();
    List<SObject> flightsToCreate = new List<SObject>();
    List<SObject> bookingsToCreate = new List<SObject>();

    List<String> objectCreationOrder = new List<String>{
      'Claims',
      'Cases',
      'Bookings'
    };

    for (Integer i = 0; i < objectCreationOrder.size(); i++) {
      String currentObject = objectCreationOrder[i];
      List<Map<Schema.SObjectField, Object>> fieldsForObjects = fieldsForEverySingleObject[
        i
      ];

      for (Integer j = 0; j < count; j++) {
        Map<Schema.SObjectField, Object> fieldsForObject = fieldsForObjects[j];
        SObject toCreate = null;

        // Create default objects
        switch on currentObject {
          when 'Claims' {
            toCreate = new LIA_Claim__c(
              Customer_Claim_Category__c = 'Flight disruptions',
              Liability_PNR__c = 'AUTO' + String.valueOf(j),
              RecordTypeId = Claims.getRecordTypeId(
                Claims.RecordType.CustomerClaim
              ),
              Flight_Number__c = 'SK123' + String.valueOf(j),
              Flight_Date__c = today
            );
          }
          when 'Cases' {
            toCreate = new Case(
              Origin = 'Form - Claims SE',
              RecordTypeId = Cases.getRecordTypeId(
                Cases.RecordType.CustomerClaim
              ),
              Status = 'New',
              SuppliedEmail = 'test@example.com'
            );
          }
          when 'Bookings' {
            toCreate = new Booking__c(
              Name = 'Test' + String.valueOf(j),
              Booking_Reference__c = 'AUTO' + String.valueOf(j),
              TEDS_Identifier__c = 'Manual-' + String.valueOf(j)
            );
          }
        }

        // Fill with custom fields
        if (fieldsForObject != null) {
          for (Schema.SObjectField field : fieldsForObject.keySet()) {
            toCreate.put(field, fieldsForObject.get(field));
          }
        }

        // Divide into separate lists for linking
        switch on currentObject {
          when 'Claims' {
            claimsToCreate.add(toCreate);
          }
          when 'Cases' {
            casesToCreate.add(toCreate);
          }
          when 'Bookings' {
            bookingsToCreate.add(toCreate);
          }
        }
      }
    }

    List<SObject> objectsToCreate = new List<SObject>{};
    objectsToCreate.addAll(claimsToCreate);
    objectsToCreate.addAll(casesToCreate);
    objectsToCreate.addAll(bookingsToCreate);
    insert objectsToCreate;

    // Create flights and customers
    List<String> objectCreationOrder2 = new List<String>{
      'Flights',
      'Customers'
    };
    Map<Integer, List<Flight__c>> indexToFlights = new Map<Integer, List<Flight__c>>{};
    Map<Integer, List<Customer__c>> indexToCustomers = new Map<Integer, List<Customer__c>>{};
    List<SObject> multiObjectsToInsert = new List<SObject>{};
    for (Integer i = 0; i < objectCreationOrder2.size(); i++) {
      String currentObject = objectCreationOrder2[i];
      List<List<Map<Schema.SObjectField, Object>>> fieldsForObjectsPerBooking = fieldsForEveryMultiObject[
        i
      ];
      for (Integer j = 0; j < count; j++) {
        Id claimId = claimsToCreate[j].Id;
        List<Map<Schema.SObjectField, Object>> fieldsForObjectsOneBooking = fieldsForObjectsPerBooking[
          j
        ];
        List<SObject> objectsForThisBooking = new List<SObject>{};
        for (Integer k = 0; k < fieldsForObjectsOneBooking.size(); k++) {
          String dynamicInfo = String.valueOf(j) + '0' + String.valueOf(k);

          switch on currentObject {
            when 'Flights' {
              objectsForThisBooking.add(
                new Flight__c(
                  Arrival_Airport__c = 'ARN',
                  Departure_Airport__c = 'UME',
                  Scheduled_Arrival_Time__c = today,
                  Scheduled_Departure_Time__c = today,
                  TEDS_Identifier__c = 'SK1' + dynamicInfo
                )
              );
            }
            when 'Customers' {
              // Adding the email is a workaround for insert errors (not fantastic)
              objectsForThisBooking.add(
                new Customer__c(
                  Name = 'Test Testsson' + dynamicInfo,
                  First_Name__c = 'Test' + dynamicInfo,
                  Last_Name__c = 'Testsson' + dynamicInfo,
                  Claim__c = claimId,
                  Email__c = dynamicInfo + '@test.com'
                )
              );
            }
          }

          Map<Schema.SObjectField, Object> fieldsForObject = fieldsForObjectsOneBooking[
            k
          ];
          if (fieldsForObject != null) {
            for (Schema.SObjectField field : fieldsForObject.keySet()) {
              objectsForThisBooking[k].put(field, fieldsForObject.get(field));
            }
          }

          switch on currentObject {
            when 'Flights' {
              indexToFlights.put(j, objectsForThisBooking);
            }
            when 'Customers' {
              indexToCustomers.put(j, objectsForThisBooking);
            }
          }
          multiObjectsToInsert.add(objectsForThisBooking[k]);
        }
      }
    }

    insert multiObjectsToInsert;

    // Link objects
    List<SObject> objectsToUpdate = new List<SObject>{};
    List<SObject> linkingObjectsToCreate = new List<SObject>{};
    for (Integer i = 0; i < count; i++) {
      Case caseToUpdate = (Case) casesToCreate[i];
      LIA_Claim__c claimToUpdate = (LIA_Claim__c) claimsToCreate[i];
      Booking__c bookingToUpdate = (Booking__c) bookingsToCreate[i];
      List<Flight__c> flightsToUpdate = indexToFlights.get(i);

      caseToUpdate.LIA_Claim__c = claimToUpdate.Id;
      claimToUpdate.Case__c = caseToUpdate.Id;
      claimToUpdate.Liability_PNR__c = bookingToUpdate.Booking_Reference__c;
      claimToUpdate.Flight_Number__c = flightsToUpdate[0]
        .TEDS_Identifier__c.substring(0, 6); // First flight is selected as the "claim flight" as default
      claimToUpdate.Flight_Date__c = flightsToUpdate[0]
        .Scheduled_Arrival_Time__c.date();

      linkingObjectsToCreate.add(
        new CaseToBooking__c(
          Case__c = caseToUpdate.Id,
          Booking__c = bookingToUpdate.Id
        )
      );

      // TODO: handle segment type (Outbound, Inbound, Cancelled)
      for (Flight__c flight : flightsToUpdate) {
        linkingObjectsToCreate.add(
          new Segment__c(Flight__c = flight.Id, Booking__c = bookingToUpdate.Id)
        );
      }
      objectsToUpdate.add(caseToUpdate);
      objectsToUpdate.add(claimToUpdate);
    }

    linkingObjectsToCreate.sort(); // Chunking
    objectsToUpdate.sort(); // Chunking
    insert linkingObjectsToCreate;
    update objectsToUpdate;

    return new CasesClaimsBookings(
      casesToCreate,
      claimsToCreate,
      bookingsToCreate
    );
  }

  public static void insertEmailTemplates(Set<String> templateNamesToCreate) {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    System.runAs(thisUser) {
      BrandTemplate bt = [
        SELECT Id
        FROM BrandTemplate
        WHERE DeveloperName = 'SAS_Logo'
      ];

      List<EmailTemplate> toInsert = new List<EmailTemplate>();

      List<EmailTemplate> existingTemplates = EmailTemplatesSelector.newInstance()
        .selectByName(templateNamesToCreate);
      List<String> existingTemplateNames = new List<String>();
      for (EmailTemplate t : existingTemplates) {
        existingTemplateNames.add(t.Name);
      }

      for (String templateName : templateNamesToCreate) {
        if (!existingTemplateNames.contains(templateName)) {
          // Insert only templates which don't exist yet.
          EmailTemplate template = new EmailTemplate(
            Subject = 'Test',
            HtmlValue = '<html>test</html>',
            Body = 'test',
            Name = templateName,
            DeveloperName = templateName,
            BrandTemplateId = bt.Id,
            TemplateStyle = 'freeForm',
            TemplateType = 'html',
            FolderId = UserInfo.getUserId()
          );
          toInsert.add(template);
        }
      }

      insert toInsert;
    }
  }
}
