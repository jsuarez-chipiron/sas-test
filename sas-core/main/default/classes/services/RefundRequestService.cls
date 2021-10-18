public without sharing class RefundRequestService {
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Refunds Customer DK',
    'no-no' => 'Form - Refunds Customer NO',
    'se-sv' => 'Form - Refunds Customer SE',
    'default' => 'Form - Refunds Customer International'
  };

  public static String createRefundForm(RefundJsonToApex form) {
    Case cse;

    try {
      String notes = '';

      RefundJsonToApex.FormData refundForm = form.formData;
      // Construct list of passenger in separate line
      if (refundForm.cancelAllPassengers == 'No') {
        for (String psgName : refundForm.passengerNames) {
          notes += psgName + '\r\n';
        }
      }

      // Refund creation
      Refund_Request__c refund = new Refund_Request__c(
        Booked_Via__c = refundForm.bookedTripVia, // FIXME: Parse data
        Cancel_All_Passengers__c = refundForm.cancelAllPassengers, // FIXME: Parse data
        Cancel_Direction__c = refundForm.cancelDirection, // FIXME: Parse data
        Cancel_Entire_Booking__c = refundForm.cancelEntireBooking, // FIXME: Parse data
        Country_of_Purchase__c = refundForm.countryOfPurchase, // FIXME: Parse data
        Email__c = refundForm.email,
        First_Name__c = refundForm.firstName,
        Last_Name__c = refundForm.lastName,
        Note__c = notes,
        Phone__c = refundForm.phone,
        PNR__c = refundForm.bookingReference,
        Ticket_Numbers__c = refundForm.ticketNumber
      );

      insert refund;

      String caseOrigin = marketToOrigin.get('default');

      if (marketToOrigin.get(form.metaData.market) != null) {
        caseOrigin = marketToOrigin.get(form.metaData.market);
      }

      // Case Creation
      cse = new Case(
        Subject = 'Refund Request, PNR: ' + refundForm.bookingReference,
        SuppliedEmail = refundForm.email,
        SuppliedPhone = refundForm.phone,
        Refund_Request__c = refund.Id,
        Origin = caseOrigin,
        RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL
      );

      insert cse;
    } catch (Exception e) {
      C_Log.logException(e, 'RefundRequest', null);
      return e.getMessage();
    }

    return cse.Id;
  }
}
