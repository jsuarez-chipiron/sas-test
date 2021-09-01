public class RefundRequestService {
  public static String createRefundForm(RefundJsonToApex form) {
    Case cse;
    Refund_Request__c refund;
    String Notes;
    try {
      RefundJsonToApex.cls_formData refundForm = form.formData;

      // Refund creation
      refund = new Refund_Request__c();
      refund.Country_of_Purchase__c = refundForm.countryOfPurchase;
      refund.PNR__c = refundForm.pnr;
      refund.Ticket_Numbers__c = refundForm.ticketNumber;
      refund.Cancel_Entire_Booking__c = refundForm.cancelEntireBooking;
      refund.Cancel_All_Passengers__c = refundForm.cancelAllPassengers;
      refund.Cancel_Direction__c = refundForm.cancelDirection;
      refund.Booked_Via__c = refundForm.bookedTripVia;
      if (refundForm.cancelAllPassengers == 'No') {
        List<String> passengerNames = refundForm.passengerNames;
        Integer Index = 0;
        for (String psgName : passengerNames) {
          if (Index != passengerNames.size()) {
            if (Index == 0) {
              refund.Note__c = psgName + '\r\n';
            } else {
              refund.Note__c += psgName + '\r\n';
            }
          }
          Index++;
        }
      }
      insert refund;

      // Case Creation
      cse = new Case();
      cse.SuppliedEmail = refundForm.email;
      cse.SuppliedPhone = refundForm.phone;
      cse.Refund_Request__c = refund.Id;

      insert cse;
    } catch (Exception e) {
      C_Log.logException(e, 'RefundRequest', null);
      return e.getMessage();
    }

    return cse.Id;
  }
}
