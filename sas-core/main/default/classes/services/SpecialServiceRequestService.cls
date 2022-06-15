public class SpecialServiceRequestService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - SSR DK',
    'no-no' => 'Form - SSR NO',
    'se-sv' => 'Form - SSR SE',
    'default' => 'Form - SSR International'
  };

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'baggage' => 'Special Baggage',
    'blind' => 'Sight disability',
    'deaf' => 'Hearing disability',
    'service-animal' => 'Service Animal',
    'special-assistance' => 'Special Assistance',
    'wchr-ramp' => 'WCHR Ramp',
    'wchs-steps' => 'WCHS Steps',
    'wchc-carry' => 'WCHC Carry',
    'wcbd' => 'Dry Battery Wheelchair (WCBD)',
    'wcbw' => 'Wet Battery Wheelchair (WCBW)',
    'wclb' => 'Lithium Battery Wheelchair (WCLB)',
    'wcmp' => 'Manual Power Wheelchair (WCMP)',
    'wheelchair' => 'Mobility'
  };

  private static final String SSR_QUEUE_NAME = 'Sales_Control_BOM';

  public static void createSpecialServiceRequest(
    SpecialServiceJSON2Apex specialServiceForm
  ) {
    String mobilityDimensions = '';
    if (
      specialServiceForm.formData.type == 'wheelchair' &&
      specialServiceForm.formData.bringsOwnMobilityDevice != null &&
      specialServiceForm.formData.bringsOwnMobilityDevice
    ) {
      mobilityDimensions =
        'Width: ' +
        specialServiceForm.formData.mobilityDeviceWidth +
        ' cm, Height: ' +
        specialServiceForm.formData.mobilityDeviceHeight +
        ' cm, Depth: ' +
        specialServiceForm.formData.mobilityDeviceDepth +
        ' cm, Weight: ' +
        specialServiceForm.formData.mobilityDeviceWeight +
        ' kg.';
    }
    Special_Service_Request__c specialServiceRequest = new Special_Service_Request__c(
      Brings_Own_Mobility_Device__c = specialServiceForm.formData.bringsOwnMobilityDevice ==
        null
        ? false
        : specialServiceForm.formData.bringsOwnMobilityDevice,
      Email__c = specialServiceForm.formData.email,
      First_Name__c = specialServiceForm.formData.firstName,
      Last_Name__c = specialServiceForm.formData.lastName,
      Mobility_Device_Dimensions__c = mobilityDimensions,
      Mobility_Device_Type__c = jsonToPicklist.get(
        specialServiceForm.formData.mobilityDeviceType
      ),
      Number_Of_Special_Baggage__c = specialServiceForm.formData.numberOfSpecialBaggage,
      Passenger_Needing_Assistance__c = specialServiceForm.formData.passengerNeedingAssistance,
      Phone__c = specialServiceForm.formData.phone,
      PNR__c = specialServiceForm.formData.bookingReference,
      Type__c = jsonToPicklist.get(specialServiceForm.formData.type),
      Type_Of_Service_Animal__c = specialServiceForm.formData.typeOfServiceAnimal,
      Type_Of_Special_Assistance__c = jsonToPicklist.get(
        specialServiceForm.formData.typeOfSpecialAssistance
      ),
      Type_Of_Special_Baggage__c = specialServiceForm.formData.specialBaggageNote
    );

    insert specialServiceRequest;

    String caseOrigin = marketToOrigin.get('default');

    if (marketToOrigin.get(specialServiceForm.metaData.market) != null) {
      caseOrigin = marketToOrigin.get(specialServiceForm.metaData.market);
    }

    Group salesControlQueue = GroupsSelector.newInstance()
      .selectQueuesByDeveloperName(new Set<String>{SSR_QUEUE_NAME})[0];

    Case caseToInsert = new Case(
      Initially_Provided_PNR__c = specialServiceForm.formData.bookingReference,
      Origin = caseOrigin,
      OwnerId = salesControlQueue.Id,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel),
      Subject = 'SSR, Type: ' +
        specialServiceRequest.Type__c +
        ', PNR: ' +
        specialServiceRequest.PNR__c,
      SuppliedEmail = specialServiceForm.formData.email,
      SuppliedPhone = specialServiceForm.formData.phone,
      Special_Service_Request__c = specialServiceRequest.Id
    );

    insert caseToInsert;
  }
}
