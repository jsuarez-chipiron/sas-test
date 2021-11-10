@IsTest
public class RefundRequestFormTest {
  @IsTest
  public static void shouldCreateCustomerRefundCases() {
    RefundJsonToApex requestBody = RefundJsonToApex.parse(
      '{  ' +
      '  "formData": {' +
      '    "countryOfPurchase": "Sweden",' +
      '    "email": "example@example.com",' +
      '    "phone": "0000098000000",' +
      '    "passengerNames": [' +
      '      "Example Examplesson", ' +
      '      "Example Examplesdottir"' +
      '    ],' +
      '    "cancelEntireBooking": "already-cancelled",' +
      '    "cancelAllPassengers": "no",' +
      '    "cancelDirection": "return",' +
      '    "bookedTripVia": "sas-website",' +
      '    "bookingReference":"TEST12",' +
      '    "ticketNumber": "123-TEST567890",' +
      '    "type": "normal"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "se-sv"' +
      '  }' +
      '}'
    );
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    RefundRequestForm.createRefundRequest(requestBody);
    Test.StopTest();

    Refund_Request__c req = [
      SELECT Id, Cancel_Entire_Booking__c
      FROM Refund_Request__c
      WHERE Phone__c = '0000098000000'
    ];
    Case c = [
      SELECT Id, Department__c, Origin
      FROM Case
      WHERE Refund_Request__c = :req.Id
    ];

    System.assertEquals(
      'Already Cancelled',
      req.Cancel_Entire_Booking__c,
      'Form data should be parsed correctly into picklists.'
    );

    System.assertEquals(
      'Form - Refunds Customer SE',
      c.Origin,
      'Case Origin should be set according to market and form type.'
    );

    System.assertEquals(
      'Refunds',
      c.Department__c,
      'Case Department should be set by Case Origin to refunds.'
    );
  }

  @IsTest
  public static void shouldCreateTravelAgentRefundCases() {
    RefundJsonToApex requestBody = RefundJsonToApex.parse(
      '{  ' +
      '  "formData": {' +
      '    "countryOfPurchase": "Sweden",' +
      '    "email": "example@example.com",' +
      '    "phone": "0000098700000",' +
      '    "passengerNames": [' +
      '      "Example Examplesson", ' +
      '      "Example Examplesdottir"' +
      '    ],' +
      '    "cancelEntireBooking": "already-cancelled",' +
      '    "cancelAllPassengers": "no",' +
      '    "cancelDirection": "return",' +
      '    "bookedTripVia": "sas-website",' +
      '    "bookingReference":"TEST12",' +
      '    "notClaimedElsewhere": true,' +
      '    "ticketNumber": "123-TEST567890",' +
      '    "type": "travel-agent"' +
      '  },' +
      '  "metaData": {' +
      '    "market": "no-no"' +
      '  }' +
      '}'
    );
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    RefundRequestForm.createRefundRequest(requestBody);
    Test.StopTest();

    Refund_Request__c req = [
      SELECT Id, Refund_Not_Claimed_Elsewhere__c
      FROM Refund_Request__c
      WHERE Phone__c = '0000098700000'
    ];
    Case c = [
      SELECT Id, Department__c, Origin
      FROM Case
      WHERE Refund_Request__c = :req.Id
    ];

    System.assertEquals(
      true,
      req.Refund_Not_Claimed_Elsewhere__c,
      'Form data should be parsed correctly into checklists.'
    );

    System.assertEquals(
      'Form - Refunds Travel Agent NO',
      c.Origin,
      'Case Origin should be set according to market and form type.'
    );

    System.assertEquals(
      'Refunds',
      c.Department__c,
      'Case Department should be set by Case Origin to refunds.'
    );
  }
}
