global class CaseFormJSONV2 {
  global FormData formData;
  global MetaData metaData;

  global class Contact {
    global String type; // private, corporate, travel-agency, other-representative, insurance-company
    global String companyName;
    global String companyCode;
    global String firstName;
    global String lastName;
    global String email;
    global String phone;
    global String address;
    global String postalCode;
    global String city;
    global String country;
    global String euroBonusNumber;
  }

  global class Claim {
    global String category; // baggage, flight-disruption, missing-services, in-flight-disruption, airport-disruption, booking, medical
    global String type; // baggage-delayed, baggage-damaged, flight-cancellation, flight-delay, missed-connection, denied-boarding, downgrading, WIFI, missing-food, extra-baggage, prepaid-seat, lounge, cabin-environment, food-poisoning, in-flight-service, airport-assistance, document-control, gate-issues, booking-errors, complaint-about-refund, personal-injury, regression, other
    global String delayLength; // 0-2, 2-3, 3-4, 4+, never-arrived
    global Boolean unaccompaniedMinor;
    global Boolean personWithReducedMobility;

    global String bookingReference;
    global String travelAgentBookingReference;
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global String ticketNumber;
    global String passengerIrregularityReportNumber;

    global String comment; // free text field

    global String baggageDelayTime; // less-than-21-days, more-than-21-days
    global Decimal baggagePurchasePrice;
    global String baggagePurchaseCurrency;
    global Integer baggagePurchaseYear;

    global List<Traveler> travelers;
    global List<Expense> expenses;
    global List<Flight> rebookedFlights;
  }

  global class Feedback {
    global String category;
    global String type;

    global String bookingReference;
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global String ticketNumber; // TODO: is this needed?

    global String comment; // free text field
  }

  global class CompensationDetails {
    global String bankAccountHolderName;
    global String bankAccountNumber;
    global String bankCountry;
    global String bankName;
    global String bankBic;
    global String bankRoutingNumber;

    global String preferredCurrency; // SEK, USD, EUR...
    global String preferredCompensationMethod; // eurobonus, monetary, voucher
    global String preferredReimbursementMethod; // eurobonus, monetary, voucher

    global String referenceNumber;
  }

  global class FormData {
    global String type; // claim, feedback, group travel, SSR, refund request

    global Contact contact;

    global Claim claim; // One of these five must exist. Not more.
    global Feedback feedback; // One of these five must exist. Not more.
    //global GroupTravelRequest groupTravelRequest; // One of these five must exist. Not more.
    //global SpecialServiceRequest specialServiceRequest; // One of these five must exist. Not more.
    //global RefundRequest refundRequest; // One of these five must exist. Not more.

    global List<String> contentVersionIds;

    global CompensationDetails compensationDetails;
  }

  global class MetaData {
    global String market;
  }

  global class Flight {
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global List<String> contentVersionIds;
  }

  global class Traveler {
    global String firstName;
    global String lastName;
    global List<String> contentVersionIds;
  }

  global class Expense {
    global String expenseType; // food, transportation, phone-calls, accommodation
    global String expenseCurrency;
    global Decimal amount;
    global List<String> contentVersionIds;
  }

  public static CaseFormJSONV2 parse(String json) {
    return (CaseFormJSONV2) System.JSON.deserialize(json, CaseFormJSONV2.class);
  }
}
