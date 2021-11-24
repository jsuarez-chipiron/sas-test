public class GroupTravelService {
  // TODO: This parsing logic should be at the API layer.
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

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'any-time' => 'Any Time',
    'morning' => 'Morning',
    'midmorning' => 'Midmorning',
    'afternoon' => 'Afternoon',
    'evening' => 'Evening',
    'credit-card' => 'Credit Card',
    'sas-invoice' => 'SAS Invoice',
    'normal' => 'Regular',
    'youth' => 'Youth',
    'sport' => 'Sports',
    'one-way' => 'One Way',
    'round-trip' => 'Round Trip',
    'return-from-another-city' => 'Return From Another City',
    'sas-go' => 'SAS Go',
    'sas-plus' => 'SAS Plus',
    'sas-business' => 'SAS Business'
  };

  private static Group groupSalesQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Group_Sales'
  ];

  public static void createGroupTravelRequest(
    GroupTravelJsonToApex groupTravelForm
  ) {
    GroupTravelJsonToApex.FormData travelRequest = groupTravelForm.formData;

    Group_Travel_Request__c grpTravelRequest = new Group_Travel_Request__c(
      Address__c = travelRequest.address,
      Alternate_Departure_date__c = travelRequest.alternateDepartureDate == null
        ? null
        : Date.valueOf(travelRequest.alternateDepartureDate),
      Alternate_Departure_time__c = jsonToPicklist.get(
        travelRequest.alternateDepartureTime
      ),
      Alternate_Return_date__c = travelRequest.alternateReturnDate == null
        ? null
        : Date.valueOf(travelRequest.alternateReturnDate),
      Alternate_Return_time__c = jsonToPicklist.get(
        travelRequest.alternateReturnTime
      ),
      Alternative_Dates__c = travelRequest.alternativeDates,
      City__c = travelRequest.city,
      C_o_Address__c = travelRequest.coAddress,
      Comments_From_Customer__c = travelRequest.comments,
      Company_Code__c = travelRequest.companyCode,
      Country__c = travelRequest.country,
      Departure_date__c = travelRequest.departureDate == null
        ? null
        : Date.valueOf(travelRequest.departureDate),
      Departure_time__c = jsonToPicklist.get(travelRequest.departureTime),
      Different_Return_City_Airport__c = travelRequest.differentReturnCityAirport,
      Email__c = travelRequest.email,
      Extra_Bags__c = travelRequest.extraBags == null
        ? false
        : travelRequest.extraBags,
      First_Name__c = travelRequest.firstName,
      Form_of_payment__c = jsonToPicklist.get(travelRequest.formOfPayment),
      From_Airport__c = travelRequest.fromAirport,
      Group_Type__c = jsonToPicklist.get(travelRequest.groupType),
      Have_Company_Code__c = travelRequest.haveCompanyCode == null
        ? false
        : travelRequest.haveCompanyCode,
      Invoice_Agreement_With_SAS__c = travelRequest.invoiceAgreementWithSAS,
      Invoice_Agreement_Number__c = travelRequest.invoiceAgreementNumber,
      Last_Name__c = travelRequest.lastName,
      Name = travelRequest.groupName,
      Number_Of_Adults__c = travelRequest.numberOfAdults == null
        ? 0
        : travelRequest.numberOfAdults,
      Number_Of_Children__c = travelRequest.numberOfChildren == null
        ? 0
        : travelRequest.numberOfChildren,
      Number_Of_Extra_Bags__c = travelRequest.numberOfExtraBags == null
        ? 0
        : travelRequest.numberOfExtraBags,
      Number_Of_Infants__c = travelRequest.numberOfInfants == null
        ? 0
        : travelRequest.numberOfInfants,
      Number_Of_Special_Assistance_Travellers__c = travelRequest.numberOfSpecialAssistanceTravelers ==
        null
        ? 0
        : travelRequest.numberOfSpecialAssistanceTravelers,
      Number_Of_Special_Baggage__c = travelRequest.numberOfSpecialBaggage ==
        null
        ? 0
        : travelRequest.numberOfSpecialBaggage,
      Number_Of_Youths__c = travelRequest.numberOfYouths == null
        ? 0
        : travelRequest.numberOfYouths,
      Number_Of_Wheelchairs__c = travelRequest.numberOfWheelchairs == null
        ? 0
        : travelRequest.numberOfWheelchairs,
      Other_destinations_of_interest__c = travelRequest.otherDestinationsOfInterest,
      Phone__c = travelRequest.phone,
      Postal_Code__c = travelRequest.postalCode,
      Propose_alternative_destinations__c = travelRequest.proposeAlternativeDestinations ==
        null
        ? false
        : travelRequest.proposeAlternativeDestinations,
      Return_date__c = travelRequest.returnDate == null
        ? null
        : Date.valueOf(travelRequest.returnDate),
      Return_time__c = jsonToPicklist.get(travelRequest.returnTime),
      Special_Baggage__c = travelRequest.specialBaggage == null
        ? false
        : travelRequest.specialBaggage,
      Special_Baggage_Note__c = travelRequest.specialBaggageNote,
      To_Airport__c = travelRequest.ToAirport,
      Travel_Class__c = jsonToPicklist.get(travelRequest.travelClass),
      Trip_Type__c = jsonToPicklist.get(travelRequest.tripType),
      Visual_or_hearing_assistance__c = travelRequest.visualOrHearingAssistance ==
        null
        ? false
        : travelRequest.visualOrHearingAssistance,
      Wheelchairs__c = travelRequest.wheelchairs == null
        ? false
        : travelRequest.wheelchairs
    );

    insert grpTravelRequest;

    String caseOrigin = marketToOrigin.get('default');

    if (marketToOrigin.get(groupTravelForm.metaData.market) != null) {
      caseOrigin = marketToOrigin.get(groupTravelForm.metaData.market);
    }

    Case caseToInsert = new Case(
      Group_Travel_Request__c = grpTravelRequest.Id,
      Origin = caseOrigin,
      OwnerId = groupSalesQueue.Id,
      RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
      Subject = 'Group Travel Request: ' + travelRequest.groupName,
      SuppliedEmail = travelRequest.email,
      SuppliedPhone = travelRequest.phone
    );

    insert caseToInsert;
  }
}
