public class GroupTravelService {
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Group Travel DK',
    'no-no' => 'Form - Group Travel NO',
    'se-sv' => 'Form - Group Travel SE',
    'be-en' => 'Form - Group Travel BE',
    'fi-en' => 'Form - Group Travel FI',
    'fr-fr' => 'Form - Group Travel FR',
    'de-de' => 'Form - Group Travel DE',
    'ie-en' => 'Form - Group Travel IE',
    'it-en' => 'Form - Group Travel IT',
    'nl-en' => 'Form - Group Travel NL',
    'pl-en' => 'Form - Group Travel PL',
    'ru-ru' => 'Form - Group Travel RU',
    'es-es' => 'Form - Group Travel ES',
    'ch-de' => 'Form - Group Travel CH-de',
    'ch-fr' => 'Form - Group Travel CH-fr',
    'gb-en' => 'Form - Group Travel GB',
    'us-en' => 'Form - Group Travel US',
    'lu-en' => 'Form - Group Travel LU',
    'default' => 'Form - Group Travel GB'
  };

  public static String createGroupTravelForm(
    GroupTravelJsonToApex groupTravelForm
  ) {
    Case cse;
    try {
      GroupTravelJsonToApex.FormData travelRequest = groupTravelForm.formData;
      Group_Travel_Request__c grpTravelRequest = createGroupTravelRequestInstance(
        travelRequest
      );

      insert grpTravelRequest;

      String caseOrigin = marketToOrigin.get('default');

      if (marketToOrigin.get(groupTravelForm.metaData.market) != null) {
        caseOrigin = marketToOrigin.get(groupTravelForm.metaData.market);
      }

      cse = new Case(
        Origin = caseOrigin,
        RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
        Subject = 'Group Travel Request: ' + travelRequest.groupName,
        SuppliedEmail = travelRequest.email,
        SuppliedPhone = travelRequest.phone
      );

      insert cse;
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
    grpTravelRequest.Departure_time__c = travelRequest.departureTime;
    grpTravelRequest.Departure_date__c = Date.valueOf(
      travelRequest.departureDate
    );
    grpTravelRequest.Return_date__c = Date.valueOf(travelRequest.returndate);
    grpTravelRequest.Return_time__c = travelRequest.returnTime;

    grpTravelRequest.Email__c = travelRequest.email;
    grpTravelRequest.Phone__c = travelRequest.phone;
    grpTravelRequest.First_Name__c = travelRequest.firstName;
    grpTravelRequest.Last_Name__c = travelRequest.lastName;
    grpTravelRequest.Address__c = travelRequest.address;
    grpTravelRequest.C_o_Address__c = travelRequest.coAddress;
    grpTravelRequest.City__c = travelRequest.city;
    grpTravelRequest.Postal_Code__c = travelRequest.postalCode;
    grpTravelRequest.Country__c = travelRequest.country;

    grpTravelRequest.Number_Of_Adults__c = travelRequest.numberOfAdults;
    grpTravelRequest.Number_Of_Children__c = travelRequest.numberOfChildren;
    grpTravelRequest.Number_Of_Infants__c = travelRequest.numberOfInfants;

    grpTravelRequest.Invoice_agreement_with_SAS__c = travelRequest.invoiceAgreementWithSAS;
    grpTravelRequest.Travel_Class__c = travelRequest.travelClass;
    grpTravelRequest.Form_of_payment__c = travelRequest.formOfPayment;
    grpTravelRequest.Comments_From_Customer__c = travelRequest.comments;
    grpTravelRequest.Group_Type__c = travelRequest.groupType;

    if (travelRequest.haveCompanyCode) {
      grpTravelRequest.Have_Company_Code__c = travelRequest.haveCompanyCode;
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
    if (travelRequest.tripType == 'Return From Another City') {
      grpTravelRequest.Trip_Type__c = travelRequest.tripType;
      grpTravelRequest.Different_Return_City_Airport__c = travelRequest.differentReturnCityAirport;
    }
    return grpTravelRequest;
  }
}
