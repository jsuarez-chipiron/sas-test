public class SpecialService {
  public static String createSpecialServiceForm(
    SpecialServiceJSON2Apex specialServiceForm
  ) {
    Case cse;

    try {
      SpecialServiceJSON2Apex.FormData specialServiceRequestForm = specialServiceForm.formData;

      //create Special Service Request
      Special_Service_Request__c specialServiceRequest = createSpecialServiceRequestInstance(
        specialServiceRequestForm
      );
      insert specialServiceRequest;

      // create Cases
      cse = new Case(
        SuppliedEmail = specialServiceRequestForm.email,
        SuppliedPhone = specialServiceRequestForm.phone,
        RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL,
        Special_Service_Request__c = specialServiceRequest.Id,
        Initially_Provided_PNR__c = specialServiceRequestForm.bookingReference
      );

      insert cse;

      // create contact
      Contact con = new Contact(
        FirstName = specialServiceRequestForm.FirstName,
        LastName = specialServiceRequestForm.LastName,
        Email = specialServiceRequestForm.email,
        phone = specialServiceRequestForm.phone,
        Special_Service_Request__c = specialServiceRequest.Id
      );

      insert con;
    } catch (Exception e) {
      C_Log.logException(e, 'RefundRequest', null);
      return e.getMessage();
    }

    return cse.Id;
  }

  static Special_Service_Request__c createSpecialServiceRequestInstance(
    SpecialServiceJSON2Apex.FormData formData
  ) {
    Special_Service_Request__c specialServiceRequest = new Special_Service_Request__c();
    specialServiceRequest.Type__c = formData.Type;
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
