public without sharing class Segments extends ApplicationDomain {
  public Segments(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Segment__c>) Records;
  }

  public List<Segment__c> instanceRecords;
  public Map<String, List<Segment__c>> flightIdToSegments;
  public SegmentEvents segmentEvents;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Segments(records);
    }
  }

  public static Segments newInstance(List<Segment__c> sObjectList) {
    return (Segments) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public Segments addBookingReference(Id bookingId) {
    for (Segment__c s : instanceRecords) {
      s.Booking__c = bookingId;
    }
    return this;
  }

  public Segments addFlightReferences(List<Flight__c> flights) {
    for (Flight__c flight : flights) {
      List<Segment__c> segmentsForFlight = flightIdToSegments.get(
        flight.TEDS_Identifier__c
      );
      if (segmentsForFlight != null && segmentsForFlight.size() > 0) {
        for (Segment__c segment : segmentsForFlight) {
          segment.Flight__c = flight.Id;
        }
      }
    }
    return this;
  }

  public Segments addEDWTicketInformation(
    List<FetchEDWBookingResponse.TicketInfo> ticketInfo
  ) {
    Map<String, FetchEDWBookingResponse.TicketInfo> segmentIdentifierToTicketInfo = new Map<String, FetchEDWBookingResponse.TicketInfo>();
    for (FetchEDWBookingResponse.TicketInfo ticket : ticketInfo) {
      String ticketIdentifier = String.format(
        'ST{0}PT{1}',
        new List<Object>{ ticket.segTattoo, ticket.tktTattoo }
      );
      if (segmentIdentifierToTicketInfo.get(ticketIdentifier) == null) {
        segmentIdentifierToTicketInfo.put(ticketIdentifier, ticket);
      }
    }
    for (Segment__c createdSegment : instanceRecords) {
      FetchEDWBookingResponse.TicketInfo ticketForSegment = segmentIdentifierToTicketInfo.get(
        createdSegment.Identifier__c
      );
      if (ticketForSegment != null) {
        createdSegment.Ticket_Number__c = String.format(
          '{0}-{1}',
          new List<Object>{ ticketForSegment.tktAirlCd, ticketForSegment.tktNo }
        );
        createdSegment.Seat__c = ticketForSegment.seatNo;
        createdSegment.Baggage_Quantity__c = ticketForSegment.bagCnt;
        createdSegment.Fare_Basis__c = ticketForSegment.fareBasis;
        createdSegment.Is_Boarded__c = ticketForSegment.boardingInd == 'Y';
        createdSegment.Check_In_Status__c = Segment.ACCEPTANCE_STATUS_TO_PICKLIST_VALUE.get(
            ticketForSegment.acceptanceSts
          ) == null
          ? null
          : Segment.ACCEPTANCE_STATUS_TO_PICKLIST_VALUE.get(
              ticketForSegment.acceptanceSts
            );
      }
    }

    return this;
  }
  public Segments upsertToDB(List<Passenger__c> passengersInBooking) {
    upsert this.instanceRecords;
    segmentEvents.addSegmentReferences(instanceRecords, passengersInBooking);
    upsert segmentEvents.instanceRecords;
    return this;
  }
}
