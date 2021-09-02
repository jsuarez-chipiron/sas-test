public class RefundRequestService {
  public static String createRefundForm(RefundJsonToApex form) {
    fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
    Case cse;

    try {
      String notes;

      RefundJsonToApex.cls_formData refundForm = form.formData;
      // Construct list of passenger in separate line
      if (refundForm.cancelAllPassengers == 'No') {
        List<String> passengerNames = refundForm.passengerNames;
        Integer Index = 0;
        for (String psgName : passengerNames) {
          if (Index != passengerNames.size()) {
            if (Index == 0) {
              notes = psgName + '\r\n';
            } else {
              notes += psgName + '\r\n';
            }
          }
          Index++;
        }
      }
      // Refund creation
      Refund_Request__c refund = new Refund_Request__c(
        Country_of_Purchase__c = refundForm.countryOfPurchase,
        PNR__c = refundForm.pnr,
        Ticket_Numbers__c = refundForm.ticketNumber,
        Cancel_Entire_Booking__c = refundForm.cancelEntireBooking,
        cancel_All_Passengers__c = refundForm.cancelAllPassengers,
        Cancel_Direction__c = refundForm.cancelDirection,
        Booked_Via__c = refundForm.bookedTripVia,
        Note__c = notes
      );

      uow.registerNew(refund);

      // Case Creation
      cse = new Case(
        SuppliedEmail = refundForm.email,
        SuppliedPhone = refundForm.phone,
        Refund_Request__c = refund.Id,
        RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL
      );

      uow.registerNew(cse);
	  

      uow.registerRelationship(cse, Case.Refund_Request__c, refund);
      uow.commitWork();
    } catch (Exception e) {
      C_Log.logException(e, 'RefundRequest', null);
      return e.getMessage();
    }

    return cse.Id;
  }
}
