public class SpecialServiceRequestService {
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - SSR DK',
    'no-no' => 'Form - SSR NO',
    'se-sv' => 'Form - SSR SE',
    'default' => 'Form - SSR International'
  };

  public static String createSpecialServiceForm(
    SpecialServiceJSON2Apex specialServiceForm
  ) {
    Case cse;

    try {
      SpecialServiceJSON2Apex.FormData specialServiceRequestForm = specialServiceForm.formData;

      Special_Service_Request__c specialServiceRequest = createSpecialServiceRequestInstance(
        specialServiceRequestForm
      );
      insert specialServiceRequest;

      String caseOrigin = marketToOrigin.get('default');

      if (marketToOrigin.get(specialServiceForm.metaData.market) != null) {
        caseOrigin = marketToOrigin.get(specialServiceForm.metaData.market);
      }

      cse = new Case(
        Initially_Provided_PNR__c = specialServiceRequestForm.bookingReference,
        Origin = caseOrigin,
        RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
        Subject = 'SSR, Type: ' +
          specialServiceRequest.Type__c +
          ', PNR: ' +
          specialServiceRequest.PNR__c,
        SuppliedEmail = specialServiceRequestForm.email,
        SuppliedPhone = specialServiceRequestForm.phone,
        Special_Service_Request__c = specialServiceRequest.Id
      );

      insert cse;
    } catch (Exception e) {
      C_Log.logException(e, 'SpecialServiceRequest', null);
      return e.getMessage();
    }

    return cse.Id;
  }

  static Special_Service_Request__c createSpecialServiceRequestInstance(
    SpecialServiceJSON2Apex.FormData formData
  ) {
    Special_Service_Request__c specialServiceRequest = new Special_Service_Request__c(
      Email__c = formData.email,
      First_Name__c = formData.firstName,
      Last_Name__c = formData.lastName,
      Phone__c = formData.phone,
      PNR__c = formData.bookingReference,
      Type__c = formData.type
    );

    specialServiceRequest.Type_Of_Special_Assistance__c = formData.typeOfSpecialAssistance;
    specialServiceRequest.Passenger_Needing_Assistance__c = formData.passengerNeedingAssistance;
    if (formData.bringsOwnMobilityDevice && formData.Type == 'Mobility') {
      specialServiceRequest.Brings_Own_Mobility_Device__c = formData.bringsOwnMobilityDevice;
      specialServiceRequest.Mobility_Device_Type__c = formData.mobilityDeviceType;
      specialServiceRequest.Mobility_Device_Dimensions__c = formData.mobilityDeviceDimensions;
    }
    if (formData.Type == 'Special Baggage') {
      specialServiceRequest.Number_Of_Special_Baggage__c = formData.numberOfSpecialBaggage;
      specialServiceRequest.Type_Of_Special_Baggage__c = formData.typeOfSpecialBaggage;
    }
    if (formData.Type == 'Service Animal') {
      specialServiceRequest.Type_Of_Service_Animal__c = formData.typeOfServiceAnimal;
    }
    return specialServiceRequest;
  }
}
