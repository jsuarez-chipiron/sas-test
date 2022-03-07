global class CaseFormJSON2Apex {
  global FormData formData;
  global MetaData metaData;

  global class FormData {
    global String type; // claim, feedback, death-certificate, visa-rejection, (delay-certificate-request TODO: Should this be completely separate?)

    global String bookingReference;
    global String euroBonusNumber;

    global String comment; // free text field

    global String feedbackCategory; // list of options
    global String feedbackType; // list of options

    global List<String> contentVersionIds; // random attachments to here.

    global String contactType; // private,corporate,travel-agency,other, etc.
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
    global String referenceNumber;
    global String legalCaseNumber;

    global String powerOfAttorneyFileId; // TODO: This could be added to overall attachments.

    global String claimCategory; // baggage, flight-disruption, missing-services, in-flight-disruption, airport-disruption, booking, medical
    global String claimType; // baggage-delayed, baggage-damaged, flight-cancellation, flight-delay, missed-connection, denied-boarding, downgrading, WIFI, missing-food, extra-baggage, prepaid-seat, lounge, cabin-environment, food-poisoning, in-flight-service, airport-assistance, document-control, gate-issues, booking-errors, complaint-about-refund, personal-injury, regression, other
    global String delayLength; // 0-2, 2-3, 3-4, 4+, never-arrived
    global Boolean unaccompaniedMinor;
    global Boolean personWithReducedMobility;
    global String compensationCardId;

    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global String ticketNumber; // TODO: is this needed?

    global List<Traveler> travelers;
    global List<Expense> expenses;
    global List<Flight> rebookedFlights;

    global String bankAccountHolderName;
    global String bankAccountNumber;
    global String bankCountry;
    global String bankName;
    global String bankBic;

    global String preferredCurrency;
    global String preferredCompensationMethod; // eurobonus, monetary, voucher
    global String preferredReimbursementMethod; // eurobonus, monetary, voucher

    global String passengerIrregularityReportNumber;
    global String baggageType;
    global Integer baggagePurchasePrice;
    global Integer baggagePurchaseYear;
    global Integer totalClaimValue;
    global Integer claimAmount;
  }

  global class MetaData {
    global String market;
  }

  global class Flight {
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
    global String boardingPassFileId;
    global String ticketNumber;
  }

  global class Traveler {
    global String firstName;
    global String lastName;
  }

  global class Expense {
    global String expenseType;
    global String expenseCurrency;
    global Integer amount;
    global String receiptFileId;
  }

  public static CaseFormJSON2Apex parse(String json) {
    return (CaseFormJSON2Apex) System.JSON.deserialize(
      json,
      CaseFormJSON2Apex.class
    );
  }
}
