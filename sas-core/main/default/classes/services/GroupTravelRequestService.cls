public class GroupTravelRequestService {
  public static String createGroupTravelForm(
    GroupTravelJsonToApex groupTravelForm
  ) {
    Case cse;
    try {
      GroupTravelJsonToApex.FormData travelRequest = groupTravelForm.formData;
      Group_Travel_Request__c grpTravelRequest = createGroupTravelRequestInstance(
        travelRequest
      );
      // insert groupTravelRequest
      insert grpTravelRequest;

      // insert Case
      cse = new Case(
        SuppliedEmail = travelRequest.email,
        SuppliedPhone = travelRequest.phone,
        RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
        Group_Travel_Request__c = grpTravelRequest.Id
      );

      insert cse;

      // insert contact
      Contact con = new Contact(
        phone = travelRequest.email,
        email = travelRequest.phone,
        firstName = travelRequest.firstName,
        lastName = travelRequest.lastName,
        MailingStreet = travelRequest.street,
        MailingCity = travelRequest.city,
        MailingState = travelRequest.state,
        MailingCountry = travelRequest.country,
        MailingPostalCode = travelRequest.postalcode,
        Group_Travel_Request__c = grpTravelRequest.Id
      );
    } catch (Exception e) {
      C_Log.logException(e, 'GroupTravelRequest', null);
      return e.getMessage();
    }

    return cse.Id;
  }
  static Group_Travel_Request__c createGroupTravelRequestInstance(
    GroupTravelJsonToApex.FormData travelRequest
  ) {
    Group_Travel_Request__c grpTravelRequest = new Group_Travel_Request__c();

    grpTravelRequest.Name = travelRequest.groupName;
    grpTravelRequest.From_Airport__c = travelRequest.fromAirport;
    grpTravelRequest.To_Airport__c = travelRequest.ToAirport;
    grpTravelRequest.Trip_Type__c = travelRequest.tripType;
    grpTravelRequest.Departure_time__c = travelRequest.departureTime;
    grpTravelRequest.Departure_date__c = Date.valueOf(
      travelRequest.departureDate
    );
    grpTravelRequest.Return_date__c = Date.valueOf(travelRequest.returndate);
    grpTravelRequest.Return_time__c = travelRequest.returnTime;

    grpTravelRequest.Number_Of_Adults__c = travelRequest.numberOfAdults;
    grpTravelRequest.Number_Of_Children__c = travelRequest.numberOfChildren;
    grpTravelRequest.Number_Of_Infants__c = travelRequest.numberOfInfants;

    grpTravelRequest.Invoice_agreement_with_SAS__c = travelRequest.invoiceAgreementWithSAS;
    grpTravelRequest.Travel_Class__c = travelRequest.travelClass;
    grpTravelRequest.Form_of_payment__c = travelRequest.formOfPayment;
    grpTravelRequest.Comments__c = travelRequest.comments;
    grpTravelRequest.Group_Type__c = travelRequest.groupType;

    if (travelRequest.haveCompanyCode) {
      grpTravelRequest.have_company_Code__c = travelRequest.haveCompanyCode;
      grpTravelRequest.Company_Code__c = travelRequest.companyCode;
    }
    if (travelRequest.alternativeDates) {
      grpTravelRequest.Alternate_Departure_date__c = Date.valueOf(
        travelRequest.alternateDepartureDate
      );
      grpTravelRequest.Alternate_Return_date__c = Date.valueOf(
        travelRequest.alternateReturnDate
      );
      grpTravelRequest.Alternate_Return_time__c = travelRequest.alternateReturnTime;
      grpTravelRequest.Alternate_Departure_time__c = travelRequest.alternateDepartureTime;
      grpTravelRequest.Alternative_Dates__c = travelRequest.alternativeDates;
    }
    if (travelRequest.proposeAlternativeDestinations) {
      grpTravelRequest.Propose_alternative_destinations__c = travelRequest.proposeAlternativeDestinations;
      grpTravelRequest.Other_destinations_of_interest__c = travelRequest.otherDestinationsOfInterest;
    }
    if (travelRequest.extraBags) {
      grpTravelRequest.Extra_Bags__c = travelRequest.extraBags;
      grpTravelRequest.Number_Of_Extra_Bags__c = travelRequest.numberOfExtraBags;
    }
    if (travelRequest.specialBaggage) {
      grpTravelRequest.Special_Baggage__c = travelRequest.specialBaggage;
      grpTravelRequest.Number_Of_Special_Baggage__c = travelRequest.numberOfSpecialBaggage;
      grpTravelRequest.Special_Baggage_Note__c = travelRequest.specialBaggageNote;
    }
    if (travelRequest.wheelchairs) {
      grpTravelRequest.Wheelchairs__c = travelRequest.wheelchairs;
      grpTravelRequest.Number_Of_Wheelchairs__c = travelRequest.numberOfWheelchairs;
    }
    if (travelRequest.visualOrHearingAssistance) {
      grpTravelRequest.Visual_or_hearing_assistance__c = travelRequest.visualOrHearingAssistance;
      grpTravelRequest.Number_Of_Travellers__c = travelRequest.numberOfTravelers;
    }
    return grpTravelRequest;
  }
}
