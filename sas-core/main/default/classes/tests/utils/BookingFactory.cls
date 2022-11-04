public with sharing class BookingFactory {
  public class FactoryException extends Exception {
  }

  private static List<Claim.Type> supportedClaimTypes = new List<Claim.Type>{
    Claim.Type.FlightCancellation
  };

  public static Booking createValidForClaim(Claim c) {
    if (!supportedClaimTypes.contains(c.type)) {
      throw new FactoryException('Claim type not supported');
    }

    Booking b = create();

    b.bookingReference = c.bookingReference;
    b.tedsIdentifier =
      c.bookingReference +
      '-' +
      c.departureDate.year() +
      c.departureDate.month() +
      c.departureDate.day();

    if (c.customers != null) {
      for (ClaimCustomer cc : c.customers) {
        b.passengers.add(PassengerFactory.create(b, cc));
      }
    }

    return b;
  }

  public static Booking create() {
    Booking b = new Booking(new Booking__c());

    b.id = Id.valueOf('001xa000003DIlo'); // TODO: fix;
    b.bookingReference = '000000';
    b.createdAtTravelOfficeId = 'STOSK08RV';
    b.isCancelled = false;
    b.isStaffBooking = false;
    b.tedsIdentifier = '000000-20220101';
    b.passengers = new List<Passenger>{};

    return b;
  }
}
