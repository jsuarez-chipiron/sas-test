public without sharing class RefundRequestService {
  // TODO: This parsing logic should be at the API layer.
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'normal-dk-da' => 'Form - Refunds Customer DK',
    'normal-no-no' => 'Form - Refunds Customer NO',
    'normal-se-sv' => 'Form - Refunds Customer SE',
    'normal-default' => 'Form - Refunds Customer International',
    'travel-agent-dk-da' => 'Form - Refunds Travel Agent DK',
    'travel-agent-no-no' => 'Form - Refunds Travel Agent NO',
    'travel-agent-se-sv' => 'Form - Refunds Travel Agent SE',
    'travel-agent-default' => 'Form - Refunds Travel Agent International'
  };

  private static Map<String, String> jsonToPicklist = new Map<String, String>{
    'sas-site' => 'Website',
    'sas-customer-service' => 'Customer Service',
    'yes' => 'Yes',
    'no' => 'No',
    'already-cancelled' => 'Already Cancelled',
    'departure' => 'Outbound',
    'outbound' => 'Outbound',
    'return' => 'Inbound'
  };

  private static Group refundsQueue = [
    SELECT Id
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Refunds'
  ];

  public static void createRefundRequest(RefundJsonToApex form) {
    String notes = '';

    // Construct list of passenger in separate line
    if (form.formData.cancelAllPassengers == 'No') {
      for (String psgName : form.formData.passengerNames) {
        notes += psgName + '\r\n';
      }
    }

    Refund_Request__c refund = new Refund_Request__c(
      Booked_Via__c = jsonToPicklist.get(form.formData.bookedTripVia),
      Cancel_All_Passengers__c = jsonToPicklist.get(
        form.formData.cancelAllPassengers
      ),
      Cancel_Direction__c = jsonToPicklist.get(form.formData.cancelDirection),
      Cancel_Entire_Booking__c = jsonToPicklist.get(
        form.formData.cancelEntireBooking
      ),
      Country_of_Purchase__c = form.formData.countryOfPurchase,
      Email__c = form.formData.email,
      First_Name__c = form.formData.firstName,
      Last_Name__c = form.formData.lastName,
      Note__c = notes,
      Phone__c = form.formData.phone,
      PNR__c = form.formData.bookingReference,
      Refund_Not_Claimed_Elsewhere__c = form.formData.notClaimedElsewhere ==
        null
        ? false
        : form.formData.notClaimedElsewhere,
      Ticket_Numbers__c = form.formData.ticketNumber
    );

    insert refund;

    String refundType = form.formData.type == 'normal'
      ? 'Customer'
      : 'Travel Agent';
    Case caseToInsert = new Case(
      OwnerId = refundsQueue.Id,
      Subject = 'Refund ' +
        refundType +
        ' Webform ' +
        form.metaData.market.replace('-', ' ').toUpperCase() +
        ', PNR: ' +
        form.formData.bookingReference,
      SuppliedEmail = form.formData.email,
      SuppliedPhone = form.formData.phone,
      Refund_Request__c = refund.Id,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel),
      Initially_Provided_PNR__c = form.formData.bookingReference
    );

    String caseOrigin;
    if (
      marketToOrigin.get(form.formData.type + '-' + form.metaData.market) !=
      null
    ) {
      caseOrigin = marketToOrigin.get(
        form.formData.type +
        '-' +
        form.metaData.market
      );
    } else if (marketToOrigin.get(form.formData.type + '-default') != null) {
      caseOrigin = marketToOrigin.get(form.formData.type + '-default');
    }

    if (caseOrigin != null) {
      caseToInsert.Origin = caseOrigin;
    }

    insert caseToInsert;
  }
}
