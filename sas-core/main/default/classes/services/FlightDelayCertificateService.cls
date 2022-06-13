public with sharing class FlightDelayCertificateService {
  private static final String TEMPLATE_IF_VALID_BOOKING = 'bookingExists';
  private static final String TEMPLATE_IF_INVALID_BOOKING = 'bookingDoesNotExist';
  private static final String replyToAddress = 'customercare@sas.se';
  private static Map<String, String> marketToOrigin = new Map<String, String>{
    'dk-da' => 'Form - Flight Delay Certificate DK',
    'no-no' => 'Form - Flight Delay Certificate NO',
    'se-sv' => 'Form - Flight Delay Certificate SE',
    'default' => 'Form - Flight Delay Certificate International'
  };

  public static String processFlightDelayCertificateRequest(
    FlightDelayCertificateFormJSON2Apex form
  ) {
    Id delayCertificateQueue = GroupsSelector.newInstance()
        .selectQueuesByDepartment(new Set<String>{ 'Customer Claim' })[0]
      .Id;
    Case caseToInsert = new Case(
      Origin = marketToOrigin.get(form.metaData.market) == null
        ? marketToOrigin.get('default')
        : marketToOrigin.get(form.metaData.market),
      Flight_Date__c = String.isBlank(form.formdata.departureDate)
        ? null
        : Date.valueOf(form.formdata.departureDate),
      Flight_Number__c = Flights.normalizeFlightNumber(
        form.formdata.flightNumber
      ),
      OwnerId = delayCertificateQueue,
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.CustomerClaim),
      Subject = 'Flight Delay Certificate: ' + form.formData.bookingReference,
      SuppliedEmail = form.formData.email
    );
    insert caseToInsert;

    Flight_Delay_Certificate_Request__c certificateRequest = new Flight_Delay_Certificate_Request__c(
      Booking_Reference__c = form.formData.bookingReference,
      Contact_First_Name__c = form.formData.firstName,
      Contact_Last_Name__c = form.formData.lastName,
      Flight_Number__c = Flights.normalizeFlightNumber(
        form.formdata.flightNumber
      ),
      Case__c = caseToInsert.Id
    );

    insert certificateRequest;

    System.enqueueJob(
      new FlightDelayCertificateJob(caseToInsert.Id, certificateRequest.Id)
    );

    return '';
  }

  public class FlightDelayCertificateJob implements Queueable, Database.AllowsCallouts {
    private String caseId;
    private String certificateRequestId;

    public FlightDelayCertificateJob(
      String caseId,
      String certificateRequestId
    ) {
      this.caseId = caseId;
      this.certificateRequestId = certificateRequestId;
    }

    public void execute(QueueableContext ctx) {
      fflib_ISObjectUnitOfWork uow = SAS_Service_Application.UnitOfWork.newInstance();
      Boolean bookingHasDelays = false;
      Booking__c currentBooking;

      Cases insertedCase = Cases.newInstance(
        CasesSelector.newInstance().selectById(new Set<Id>{ caseId })
      );

      FlightDelayCertificateRequests newRequests = FlightDelayCertificateRequests.newInstance(
        FlightDelayCertificateRequestsSelector.newInstance()
          .selectByIdFull(new Set<Id>{ certificateRequestId })
      );

      BookingService.addBookingToCase(
        insertedCase.instanceRecords[0].Id,
        newRequests.instanceRecords[0].Booking_Reference__c
      );
      List<Booking__c> bookingsForPassenger = BookingsSelector.newInstance()
        .selectByLastNameAndBookingReference(
          newRequests.instanceRecords[0].Contact_Last_Name__c,
          newRequests.instanceRecords[0].Booking_Reference__c
        );
      Map<Id, Boolean> bookingsIdToIrrStatus = Bookings.newInstance(
          bookingsForPassenger
        )
        .haveDelayedOrCancelledFlights();
      // Only handle one booking at a time
      if (bookingsForPassenger.size() == 1) {
        currentBooking = bookingsForPassenger[0];
        bookingHasDelays = bookingsIdToIrrStatus.get(currentBooking.Id);
      }
      String nameOfEmailTemplateToUse = bookingHasDelays
        ? TEMPLATE_IF_VALID_BOOKING
        : TEMPLATE_IF_INVALID_BOOKING;

      Messaging.SingleEmailMessage emailToSend = EmailMessages.createSingleEmailMessageFromTemplate(
        nameOfEmailTemplateToUse
      );
      emailToSend.setReplyTo(replyToAddress);
      // Send delay certificate if associated booking contains delayed/cancelled flights.
      // If booking does not exist or if the associated booking does not contain delayed/cancelled flights, we send a generic response
      if (bookingHasDelays) {
        String fileName =
          newRequests.instanceRecords[0].Contact_Full_Name__c +
          '_' +
          newRequests.instanceRecords[0].Booking_Reference__c +
          '.pdf';
        Blob fdcPdf = newRequests.generateFlightDelayCertificate(
          currentBooking.Id
        );
        Messaging.EmailFileAttachment pdfToAttach = EmailMessages.createEmailAttachmentFromBlob(
          fdcPdf,
          fileName,
          'application/pdf'
        );
        emailToSend.setFileAttachments(
          new List<Messaging.EmailFileAttachment>{ pdfToAttach }
        );
      }

      insertedCase.emailOwner(emailToSend, uow).close(uow);

      try {
        uow.commitWork();
      } catch (Exception e) {
        C_Log.log(
          C_Log.Severity.Error,
          e.getTypeName() +
          ': ' +
          e.getMessage(),
          e.getStackTraceString(),
          'FlightDelayCertificateService',
          null
        );
      }
    }
  }
}
