public inherited sharing class ClaimsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      LIA_Claim__c.Id,
      LIA_Claim__c.Bank_Account_Number__c,
      LIA_Claim__c.Case__c,
      LIA_Claim__c.Claims_Exist_In_CARE_For_PNR__c,
      LIA_Claim__c.Claim_Firm__c,
      LIA_Claim__c.Contact_Email__c,
      LIA_Claim__c.EuroBonus_Number__c,
      LIA_Claim__c.Flight_Date__c,
      LIA_Claim__c.Flight_Number__c,
      LIA_Claim__c.Last_Checked_Claims_From_CARE__c,
      LIA_Claim__c.Liability_PNR__c,
      LIA_Claim__c.Phone_Number__c,
      LIA_Claim__c.PIR__c,
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

  private static ProactivitiesSelector proactivities = ProactivitiesSelector.newInstance();
  private static CustomersSelector customers = CustomersSelector.newInstance();

  public List<LIA_Claim__c> selectById(Set<Id> ids) {
    return (List<LIA_Claim__c>) selectSObjectsById(ids);
  }

  public List<LIA_Claim__c> selectByIdWithCustomers(Set<Id> ids) {
    fflib_QueryFactory claimsQF = newQueryFactory().setCondition('Id IN :ids');
    fflib_QueryFactory customersQF = new CustomersSelector()
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
    Proactivity__c proactivity = proactivities.selectById(
      new Set<Id>{ proactivityId }
    )[0];

    String flightNumber;
    Date flightDate;

    if (!String.isBlank(proactivity.Flight_Id__c)) {
      flightNumber = proactivity.Flight_Id__c.substringBefore('-');
      flightDate = Date.parse(proactivity.Flight_Id__c.substringAfter('-'));
    }

    String bankAccountNumber = proactivity.Bank_Account_Number__c;
    String bookingReference = proactivity.Booking_Reference__c;
    String email = proactivity.Email__c;
    String euroBonusNumber = proactivity.EuroBonus_Number__c;
    String passengerName = proactivity.Passenger_Name__c;
    String phoneNumber = proactivity.Phone_Number__c;
    String pirNumber = proactivity.PIR__c;

    fflib_QueryFactory query = newQueryFactory();
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

    if (!String.isBlank(email)) {
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
        whereQuery += 'Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate';
      } else {
        whereQuery += ' OR Flight_Number__c = :flightNumber AND Flight_Date__c = :flightDate';
      }
    }

    if (!String.isBlank(passengerName)) {
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
    }

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
}