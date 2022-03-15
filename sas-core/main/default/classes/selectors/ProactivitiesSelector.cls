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
      Proactivity__c.PIR__c
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

  private static ClaimsSelector claims = ClaimsSelector.newInstance();

  public List<Proactivity__c> selectById(Set<Id> ids) {
    return (List<Proactivity__c>) selectSObjectsById(ids);
  }

  public List<Proactivity__c> selectByCaseId(Id caseId) {
    LIA_Claim__c claim = claims.selectByCaseIdWithCustomers( // TODO: Make sure I don't break if a claim doesn't exist
      new Set<Id>{ caseId }
    )[0];

    String flightId = claim.Flight_Number__c != null &&
      claim.Flight_Date__c != null
      ? claim.Flight_Number__c + '-' + String.valueOf(claim.Flight_Date__c)
      : null;

    List<String> passengerNames = null;
    if (claim.Customers__r != null) {
      passengerNames = new List<String>();
      for (Customer__c customer : claim.Customers__r) {
        if (customer.Name != null) {
          passengerNames.add(customer.Name);
        }
      }
    }

    String bankAccountNumber = claim.Bank_Account_Number__c;
    String bookingReference = claim.Liability_PNR__c;
    String email = claim.Contact_Email__c;
    String euroBonusNumber = claim.EuroBonus_Number__c;
    Id firm = claim.Claim_Firm__c;
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
        whereQuery += 'Booking_Reference__c = :bookingReference';
      } else {
        whereQuery += ' OR Booking_Reference__c = :bookingReference';
      }
    }

    if (!String.isBlank(email)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Email__c = :email';
      } else {
        whereQuery += ' OR Email__c = :email';
      }
    }

    if (!String.isBlank(euroBonusNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'EuroBonus_Number__c = :euroBonusNumber';
      } else {
        whereQuery += ' OR EuroBonus_Number__c = :euroBonusNumber';
      }
    }

    if (firm != null) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Claim_Firm__c = :firm';
      } else {
        whereQuery += ' OR Claim_Firm__c = :firm';
      }
    }

    if (!String.isBlank(flightId)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Flight_Id__c = :flightId';
      } else {
        whereQuery += ' OR Flight_Id__c = :flightId';
      }
    }

    if (passengerNames != null) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Passenger_Name__c IN :passengerNames';
      } else {
        whereQuery += ' OR Passenger_Name__c IN :passengerNames';
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

    return (List<Proactivity__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );
  }
}
