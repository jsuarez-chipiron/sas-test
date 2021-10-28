@IsTest
public class SpecialServiceRequestTest {
  @IsTest
  public static void shouldCreateAnimalRequests() {
    SpecialServiceJSON2Apex requestBody = SpecialServiceJSON2Apex.parse(
      '{ ' +
      '  "formData": {' +
      '    "bookingReference": "AH2345",' +
      '    "email": "example@example.com",' +
      '    "phone": "012000000000",' +
      '    "firstName": "test",' +
      '    "lastName": "test1",' +
      '    "type": "service-animal",' +
      '    "passengerNeedingAssistance": "Example Examplesson",' +
      '    "typeOfServiceAnimal": "Dog. Woof."' +
      '   },' +
      '  "metaData": {' +
      '    "market": "se-sv"' +
      '  }' +
      '}'
    );

    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );
    Test.startTest();
    SpecialServiceRequestForm.createSpecialServiceRequest(requestBody);
    Test.StopTest();

    Special_Service_Request__c req = [
      SELECT Id, Type_Of_Service_Animal__c, Type__c
      FROM Special_Service_Request__c
      WHERE Phone__c = '012000000000'
    ];
    Case c = [
      SELECT Id, Origin
      FROM Case
      WHERE Special_Service_Request__c = :req.Id
    ];

    System.assertEquals(
      'Dog. Woof.',
      req.Type_Of_Service_Animal__c,
      'Request data should be set based on form data.'
    );
    System.assertEquals(
      'Service Animal',
      req.Type__c,
      'Request Type should be set based on form data.'
    );
    System.assertEquals(
      'Form - SSR SE',
      c.Origin,
      'Case Origin should be set according to market.'
    );
  }

  @IsTest
  public static void shouldCreateAssistanceRequests() {
    SpecialServiceJSON2Apex requestBody = SpecialServiceJSON2Apex.parse(
      '{ ' +
      '  "formData": {' +
      '    "bookingReference": "AH2345",' +
      '    "email": "example@example.com",' +
      '    "phone": "023000000000",' +
      '    "firstName": "test",' +
      '    "lastName": "test1",' +
      '    "type": "special-assistance",' +
      '    "passengerNeedingAssistance": "Example Examplesdottir",' +
      '    "typeOfSpecialAssistance": "deaf"' +
      '   },' +
      '  "metaData": {' +
      '    "market": "se-sv"' +
      '  }' +
      '}'
    );

    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );
    Test.startTest();
    SpecialServiceRequestForm.createSpecialServiceRequest(requestBody);
    Test.StopTest();

    Special_Service_Request__c req = [
      SELECT Id, Type_Of_Special_Assistance__c, Type__c
      FROM Special_Service_Request__c
      WHERE Phone__c = '023000000000'
    ];

    System.assertEquals(
      'Hearing disability',
      req.Type_Of_Special_Assistance__c,
      'Request data should be set based on form data.'
    );
    System.assertEquals(
      'Special Assistance',
      req.Type__c,
      'Request Type should be set based on form data.'
    );
  }

  @IsTest
  public static void shouldCreateBaggageRequests() {
    SpecialServiceJSON2Apex requestBody = SpecialServiceJSON2Apex.parse(
      '{ ' +
      '  "formData": {' +
      '    "bookingReference": "AH2345",' +
      '    "email": "example@example.com",' +
      '    "phone": "034000000000",' +
      '    "firstName": "test",' +
      '    "lastName": "test1",' +
      '    "type": "baggage",' +
      '    "numberOfSpecialBaggage": 2,' +
      '    "typeOfSpecialBaggage": "It is Yuuge."' +
      '  },' +
      '  "metaData": {' +
      '    "market": "se-sv"' +
      '  }' +
      '}'
    );

    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );
    Test.startTest();
    SpecialServiceRequestForm.createSpecialServiceRequest(requestBody);
    Test.StopTest();

    Special_Service_Request__c req = [
      SELECT Id, Number_Of_Special_Baggage__c, Type__c
      FROM Special_Service_Request__c
      WHERE Phone__c = '034000000000'
    ];

    System.assertEquals(
      2,
      req.Number_Of_Special_Baggage__c,
      'Request data should be set based on form data.'
    );
    System.assertEquals(
      'Special Baggage',
      req.Type__c,
      'Request Type should be set based on form data.'
    );
  }

  @IsTest
  public static void shouldCreateMobilityRequests() {
    SpecialServiceJSON2Apex requestBody = SpecialServiceJSON2Apex.parse(
      '{ ' +
      '  "formData": {' +
      '    "bookingReference": "AH2345",' +
      '    "email": "example@example.com",' +
      '    "phone": "045000000000",' +
      '    "firstName": "test",' +
      '    "lastName": "test1",' +
      '    "type": "wheelchair",' +
      '    "passengerNeedingAssistance": "we need assitence",' +
      '    "typeOfSpecialAssistance": "wchr-ramp",' +
      '    "bringsOwnMobilityDevice": true,' +
      '    "mobilityDeviceType": "wcbd",' +
      '    "mobilityDeviceDimensions": "20H 20W 20D 20W"' +
      '   },' +
      '  "metaData": {' +
      '    "market": "se-sv"' +
      '  }' +
      '}'
    );

    Test.setMock(
      HttpCalloutMock.class,
      new TEDSBookingSingleAndFlightSuccessMock()
    );
    Test.startTest();
    SpecialServiceRequestForm.createSpecialServiceRequest(requestBody);
    Test.StopTest();

    Special_Service_Request__c req = [
      SELECT
        Id,
        Brings_Own_Mobility_Device__c,
        Mobility_Device_Type__c,
        Type_Of_Special_Assistance__c,
        Type__c
      FROM Special_Service_Request__c
      WHERE Phone__c = '045000000000'
    ];

    System.assertEquals(
      'WCHR Ramp',
      req.Type_Of_Special_Assistance__c,
      'Request data should be set based on form data.'
    );
    System.assertEquals(
      true,
      req.Brings_Own_Mobility_Device__c,
      'Request Type should be set based on form data.'
    );
    System.assertEquals(
      'Dry Battery Wheelchair (WCBD)',
      req.Mobility_Device_Type__c,
      'Request Type should be set based on form data.'
    );
    System.assertEquals(
      'Mobility',
      req.Type__c,
      'Request Type should be set based on form data.'
    );
  }
}
