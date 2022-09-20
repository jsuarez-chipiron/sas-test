public without sharing class Claim extends AbstractSObjectWrapper {
  public RecordType recordType;
  public LIA_Claim__c underlyingSObject { get; private set; }

  public Id parentCaseId;

  public Category category;
  public Type type;

  public ContactType contactType;
  public String contactFirstName;
  public String contactLastName;
  public String contactAddressLine1;
  public String contactAddressLine2;
  public String contactCity;
  public String contactCountry;
  public String contactEmail;
  public String contactPhone;
  public String contactPostalCode;
  public String companyCode;
  public String companyName;

  public String eu261HandlingNote;
  public EU261HandlingStatus eu261HandlingStatus;

  public CompensationType preferredCompensationMethod;
  public CompensationType preferredReimbursementMethod;
  public String bankAccountHolderName;
  public String bankAccountNumber;
  public String bankCountry;
  public String bankName;
  public String bankBicSwift;
  public String referenceNumber;
  public Currencies.Code preferredCurrency;
  public String euroBonusNumber;

  public Boolean personWithReducedMobility;
  public Boolean unaccompaniedMinor;

  public DelayLength delayToDestination;
  public Date departureDate;
  public String flightNumber;
  public String ticketNumber;
  public String bookingReference;

  public BaggageDelayLength baggageDelayLength;
  public String pir;
  public Decimal baggagePurchasePrice;
  public Decimal baggagePurchaseYear;

  public String compensationCardNumber;

  public String comment;

  public Decimal submittedClaimExpenses { get; private set; } // Roll-up field

  public Boolean containsDetailObjectData { get; private set; }

  public override void updateSObjectFields() {
    this.underlyingSObject.Address_line_1__c = this.contactAddressLine1;
    this.underlyingSObject.Address_line_2__c = this.contactAddressLine2;
    this.underlyingSObject.Bank_Account_Holder_Name__c = this.bankAccountHolderName;
    this.underlyingSObject.Bank_Account_Number__c = this.bankAccountNumber;
    this.underlyingSObject.Bank_Country__c = this.bankCountry;
    this.underlyingSObject.Bank_Name__c = this.bankName;
    this.underlyingSObject.BIC_Swift__c = this.bankBicSwift;
    this.underlyingSObject.Case__c = this.parentCaseId;
    this.underlyingSObject.City__c = this.contactCity;
    this.underlyingSObject.Comment__c = this.comment;
    this.underlyingSObject.Company_Code__c = this.companyCode;
    this.underlyingSObject.Company_Name__c = this.companyName;
    this.underlyingSObject.Compensation_Card_Number__c = this.compensationCardNumber;
    this.underlyingSObject.Concerns_a_person_with_reduced_mobility__c = this.personWithReducedMobility;
    this.underlyingSObject.Concerns_an_unaccompanied_minor__c = this.unaccompaniedMinor;
    this.underlyingSObject.Contact_Email__c = this.contactEmail;
    this.underlyingSObject.Contact_First_Name__c = this.contactFirstName;
    this.underlyingSObject.Contact_Last_Name__c = this.contactLastName;
    this.underlyingSObject.Country__c = this.contactCountry;
    this.underlyingSObject.Currency__c = Currencies.CODE_ENUM_TO_PICKLIST_VALUE.get(
      this.preferredCurrency
    );
    this.underlyingSObject.Customer_Claim_Category__c = CATEGORY_ENUM_TO_PICKLIST_VALUE.get(
      this.category
    );
    this.underlyingSObject.Customer_Claim_Type__c = TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.type
    );
    this.underlyingSObject.Customer_s_Reference__c = this.referenceNumber;
    this.underlyingSObject.Delay_Length__c = BAGGAGE_DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE.get(
      this.baggageDelayLength
    );
    this.underlyingSObject.EU261_Handling_Note__c = this.eu261HandlingNote;
    this.underlyingSObject.EU261_Handling_Status__c = EU261_STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.eu261HandlingStatus
    );
    this.underlyingSObject.EuroBonus_Number__c = this.euroBonusNumber;
    this.underlyingSObject.Flight_Date__c = this.departureDate;
    this.underlyingSObject.Flight_Number__c = this.flightNumber;
    this.underlyingSObject.Liability_PNR__c = this.bookingReference;
    this.underlyingSObject.Phone_Number__c = this.contactPhone;
    this.underlyingSObject.PIR__c = this.pir;
    this.underlyingSObject.Postal_Code__c = this.contactPostalCode;
    this.underlyingSObject.Preferred_Compensation_Method__c = COMPENSATION_TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.preferredCompensationMethod
    );
    this.underlyingSObject.Preferred_Reimbursement_Method__c = COMPENSATION_TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.preferredReimbursementMethod
    );
    this.underlyingSObject.Purchase_Price__c = this.baggagePurchasePrice;
    this.underlyingSObject.Purchase_Year__c = this.baggagePurchaseYear;
    this.underlyingSObject.RecordTypeId = getRecordTypeIdByEnum(
      this.recordType
    );
    this.underlyingSObject.Ticket_Number__c = this.ticketNumber;
    this.underlyingSObject.Total_delay_to_final_destination__c = DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE.get(
      this.delayToDestination
    );
    this.underlyingSObject.Type_of_Customer__c = CUSTOMER_TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.contactType
    );
  }

  public Claim() {
    this.underlyingSObject = new LIA_Claim__c();
    this.containsDetailObjectData = false;
  }

  public Claim(LIA_Claim__c c) {
    this();
    this.underlyingSObject = c;
    this.id = c.Id;

    this.contactAddressLine1 = c.Address_line_1__c;
    this.contactAddressLine2 = c.Address_line_2__c;
    this.bankAccountHolderName = c.Bank_Account_Holder_Name__c;
    this.bankAccountNumber = c.Bank_Account_Number__c;
    this.bankCountry = c.Bank_Country__c;
    this.bankName = c.Bank_Name__c;
    this.bankBicSwift = c.BIC_Swift__c;
    this.parentCaseId = c.Case__c;
    this.contactCity = c.City__c;
    this.comment = c.Comment__c;
    this.companyCode = c.Company_Code__c;
    this.companyName = c.Company_Name__c;
    this.compensationCardNumber = c.Compensation_Card_Number__c;
    this.personWithReducedMobility = c.Concerns_a_person_with_reduced_mobility__c;
    this.unaccompaniedMinor = c.Concerns_an_unaccompanied_minor__c;
    this.contactEmail = c.Contact_Email__c;
    this.contactFirstName = c.Contact_First_Name__c;
    this.contactLastName = c.Contact_Last_Name__c;
    this.contactCountry = c.Country__c;
    this.preferredCurrency = Currencies.CODE_PICKLIST_VALUE_TO_ENUM.get(
      c.Currency__c
    );
    this.category = CATEGORY_PICKLIST_VALUE_TO_ENUM.get(
      c.Customer_Claim_Category__c
    );
    this.type = TYPE_PICKLIST_VALUE_TO_ENUM.get(c.Customer_Claim_Type__c);
    this.referenceNumber = c.Customer_s_Reference__c;
    this.baggageDelayLength = BAGGAGE_DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM.get(
      c.Delay_Length__c
    );
    this.eu261HandlingNote = c.EU261_Handling_Note__c;
    this.eu261HandlingStatus = EU261_STATUS_PICKLIST_VALUE_TO_ENUM.get(
      c.EU261_Handling_Status__c
    );
    this.euroBonusNumber = c.EuroBonus_Number__c;
    this.departureDate = c.Flight_Date__c;
    this.flightNumber = c.Flight_Number__c;
    this.bookingReference = c.Liability_PNR__c;
    this.contactPhone = c.Phone_Number__c;
    this.pir = c.PIR__c;
    this.contactPostalCode = c.Postal_Code__c;
    this.preferredCompensationMethod = COMPENSATION_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      c.Preferred_Compensation_Method__c
    );
    this.preferredReimbursementMethod = COMPENSATION_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      c.Preferred_Reimbursement_Method__c
    );
    this.baggagePurchasePrice = c.Purchase_Price__c;
    this.baggagePurchaseYear = c.Purchase_Year__c;
    this.recordType = getRecordTypeEnumById(c.RecordTypeId);
    this.submittedClaimExpenses = c.Submitted_Claim_Expenses_in_SEK__c;
    this.ticketNumber = c.Ticket_Number__c;
    this.delayToDestination = DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM.get(
      c.Total_delay_to_final_destination__c
    );
    this.contactType = CUSTOMER_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      c.Type_of_Customer__c
    );
  }

  public Claim(
    LIA_Claim__c c,
    List<Customer__c> customers,
    List<Claim_Expense__c> expenses,
    List<Claim_Rebooked_Flight__c> rebookedFlights
  ) {
    this(c);
  }

  public enum RecordType {
    CompensationCard,
    CustomerClaim,
    LiabilityClaim
  }

  public enum Category {
    AccidentAndInjury,
    AirportExperience,
    Baggage,
    Booking,
    FlightDisruptions,
    FlightExperience,
    Other,
    PassengerIrregularities,
    TravelExtras
  }

  public enum Type {
    BaggageDamaged,
    BaggageDelayedLost,
    BookingError,
    CabinEnvironment,
    ComplaintAboutRefund,
    DeniedBoarding,
    Downgrading,
    ExtraBaggage,
    FlightCancellation,
    FlightDelay,
    GateIssues,
    InFlightMeal,
    InFlightService,
    MissingItemsFromBaggage,
    Lounge,
    MealsDrinks,
    MissedConnection,
    PersonalInjury,
    PrepaidSeat,
    SpecialAssistance,
    TravelDocumentControl,
    WiFi,
    Other,
    InvoluntaryDeniedBoarding,
    InvoluntaryDowngrading,
    VoluntaryDeniedBoarding,
    VoluntaryDowngrading
  }

  public enum ContactType {
    PrivateCustomer,
    ClaimFirm,
    OtherRepresentative,
    InsuranceCompany
  }

  public enum CompensationType {
    Voucher,
    Monetary,
    EBPoints
  }

  public enum DelayLength {
    ZeroToTwo,
    TwoToThree,
    ThreeToFour,
    MoreThanFour,
    NeverArrived
  }

  public enum BaggageDelayLength {
    LessThan21Days,
    MoreThan21Days
  }

  public enum EU261HandlingStatus {
    Unhandled,
    EligibleForCompensation,
    IneligibleForCompensation,
    UnableToHandle
  }

  private static final Map<EU261HandlingStatus, String> EU261_STATUS_ENUM_TO_PICKLIST_VALUE = new Map<EU261HandlingStatus, String>{
    EU261HandlingStatus.Unhandled => 'Unhandled',
    EU261HandlingStatus.EligibleForCompensation => 'Eligible for compensation',
    EU261HandlingStatus.IneligibleForCompensation => 'Ineligible for compensation',
    EU261HandlingStatus.UnableToHandle => 'Unable to handle'
  };

  private static final Map<String, EU261HandlingStatus> EU261_STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, EU261HandlingStatus>{
    'Unhandled' => EU261HandlingStatus.Unhandled,
    'Eligible for compensation' => EU261HandlingStatus.EligibleForCompensation,
    'Ineligible for compensation' => EU261HandlingStatus.IneligibleForCompensation,
    'Unable to handle' => EU261HandlingStatus.UnableToHandle
  };

  private static final Map<CompensationType, String> COMPENSATION_TYPE_ENUM_TO_PICKLIST_VALUE = new Map<CompensationType, String>{
    CompensationType.Voucher => 'Voucher',
    CompensationType.Monetary => 'Monetary',
    CompensationType.EBPoints => 'EuroBonus Points'
  };

  private static final Map<String, CompensationType> COMPENSATION_TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, CompensationType>{
    'Voucher' => CompensationType.Voucher,
    'Monetary' => CompensationType.Monetary,
    'EuroBonus Points' => CompensationType.EBPoints
  };

  private static final Map<String, DelayLength> DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM = new Map<String, DelayLength>{
    '0-2' => DelayLength.ZeroToTwo,
    '2-3' => DelayLength.TwoToThree,
    '3-4' => DelayLength.ThreeToFour,
    '4+' => DelayLength.MoreThanFour,
    'Never arrived' => DelayLength.NeverArrived
  };

  private static final Map<DelayLength, String> DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE = new Map<DelayLength, String>{
    DelayLength.ZeroToTwo => '0-2',
    DelayLength.TwoToThree => '2-3',
    DelayLength.ThreeToFour => '3-4',
    DelayLength.MoreThanFour => '4+',
    DelayLength.NeverArrived => 'Never arrived'
  };

  private static final Map<String, BaggageDelayLength> BAGGAGE_DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM = new Map<String, BaggageDelayLength>{
    'Less than 21 days' => BaggageDelayLength.LessThan21Days,
    '21 days or more' => BaggageDelayLength.MoreThan21Days
  };

  private static final Map<BaggageDelayLength, String> BAGGAGE_DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE = new Map<BaggageDelayLength, String>{
    BaggageDelayLength.LessThan21Days => 'Less than 21 days',
    BaggageDelayLength.MoreThan21Days => '21 days or more'
  };

  private static final Map<String, Category> CATEGORY_PICKLIST_VALUE_TO_ENUM = new Map<String, Category>{
    'Accident &amp; injury' => Category.AccidentAndInjury,
    'Airport experience' => Category.AirportExperience,
    'Baggage' => Category.Baggage,
    'Booking' => Category.Booking,
    'Flight disruptions' => Category.FlightDisruptions,
    'Flight experience' => Category.FlightExperience,
    'Other' => Category.Other,
    'Passenger irregularities' => Category.PassengerIrregularities,
    'Travel extras bought not rendered' => Category.TravelExtras
  };

  private static final Map<Category, String> CATEGORY_ENUM_TO_PICKLIST_VALUE = new Map<Category, String>{
    Category.AccidentAndInjury => 'Accident & injury',
    Category.AirportExperience => 'Airport experience',
    Category.Baggage => 'Baggage',
    Category.Booking => 'Booking',
    Category.FlightDisruptions => 'Flight disruptions',
    Category.FlightExperience => 'Flight experience',
    Category.Other => 'Other',
    Category.PassengerIrregularities => 'Passenger irregularities',
    Category.TravelExtras => 'Travel extras bought not rendered'
  };

  private static final Map<ContactType, String> CUSTOMER_TYPE_ENUM_TO_PICKLIST_VALUE = new Map<ContactType, String>{
    ContactType.ClaimFirm => 'Claim firm',
    ContactType.InsuranceCompany => 'Insurance company',
    ContactType.OtherRepresentative => 'Other representative',
    ContactType.PrivateCustomer => 'Private customer'
  };

  private static final Map<String, ContactType> CUSTOMER_TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, ContactType>{
    'Claim firm' => ContactType.ClaimFirm,
    'Insurance company' => ContactType.InsuranceCompany,
    'Other representative' => ContactType.OtherRepresentative,
    'Private customer' => ContactType.PrivateCustomer
  };

  private static final Map<String, Type> TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, Type>{
    'Baggage damaged' => Type.BaggageDamaged,
    'Baggage delayed/lost' => Type.BaggageDelayedLost,
    'Booking error' => Type.BookingError,
    'Cabin environment' => Type.CabinEnvironment,
    'Complaint about a refund' => Type.ComplaintAboutRefund,
    'Denied boarding' => Type.DeniedBoarding,
    'Downgrading' => Type.Downgrading,
    'Extra baggage' => Type.ExtraBaggage,
    'Flight cancellation' => Type.FlightCancellation,
    'Flight delay' => Type.FlightDelay,
    'Gate issues' => Type.GateIssues,
    'In-flight meal' => Type.InFlightMeal,
    'In-flight service' => Type.InFlightService,
    'Items missing from checked-in baggage' => Type.MissingItemsFromBaggage,
    'Lounge' => Type.Lounge,
    'Meals/Drinks' => Type.MealsDrinks,
    'Missed connection' => Type.MissedConnection,
    'Personal injury' => Type.PersonalInjury,
    'Prepaid seat' => Type.PrepaidSeat,
    'Special assistance' => Type.SpecialAssistance,
    'Travel document control' => Type.TravelDocumentControl,
    'WiFi' => Type.WiFi,
    'Other' => Type.Other,
    'Involuntary Denied Boarding' => Type.InvoluntaryDeniedBoarding,
    'Involuntary Downgrading' => Type.InvoluntaryDowngrading,
    'Voluntary Denied Boarding' => Type.VoluntaryDeniedBoarding,
    'Voluntary Downgrading' => Type.VoluntaryDowngrading
  };

  private static final Map<Type, String> TYPE_ENUM_TO_PICKLIST_VALUE = new Map<Type, String>{
    Type.BaggageDamaged => 'Baggage damaged',
    Type.BaggageDelayedLost => 'Baggage delayed/lost',
    Type.BookingError => 'Booking error',
    Type.CabinEnvironment => 'Cabin environment',
    Type.ComplaintAboutRefund => 'Complaint about a refund',
    Type.DeniedBoarding => 'Denied boarding',
    Type.Downgrading => 'Downgrading',
    Type.ExtraBaggage => 'Extra baggage',
    Type.FlightCancellation => 'Flight cancellation',
    Type.FlightDelay => 'Flight delay',
    Type.GateIssues => 'Gate issues',
    Type.InFlightMeal => 'In-flight meal',
    Type.InFlightService => 'In-flight service',
    Type.MissingItemsFromBaggage => 'Items missing from checked-in baggage',
    Type.Lounge => 'Lounge',
    Type.MealsDrinks => 'Meals/Drinks',
    Type.MissedConnection => 'Missed connection',
    Type.PersonalInjury => 'Personal injury',
    Type.PrepaidSeat => 'Prepaid seat',
    Type.SpecialAssistance => 'Special assistance',
    Type.TravelDocumentControl => 'Travel document control',
    Type.WiFi => 'WiFi',
    Type.Other => 'Other',
    Type.InvoluntaryDeniedBoarding => 'Involuntary Denied Boarding',
    Type.InvoluntaryDowngrading => 'Involuntary Downgrading',
    Type.VoluntaryDeniedBoarding => 'Voluntary Denied Boarding',
    Type.VoluntaryDowngrading => 'Voluntary Downgrading'
  };

  private static Map<RecordType, String> recordTypeToEnumToDeveloperName = new Map<RecordType, String>{
    RecordType.CompensationCard => 'CompensationCard',
    RecordType.CustomerClaim => 'CustomerClaim',
    RecordType.LiabilityClaim => 'LiabilityClaim'
  };

  private static Map<String, RecordType> recordTypeDeveloperNameToEnum = new Map<String, RecordType>{
    'CompensationCard' => RecordType.CompensationCard,
    'CustomerClaim' => RecordType.CustomerClaim,
    'LiabilityClaim' => RecordType.LiabilityClaim
  };

  private static Map<RecordType, Id> recordTypeEnumToId = new Map<RecordType, Id>();
  private static Map<Id, RecordType> recordTypeIdToEnum = new Map<Id, RecordType>();

  public static Id getRecordTypeIdByEnum(RecordType rt) {
    // TODO: Make this private after we have removed all uses of it outside of this class.
    Id rtId = recordTypeEnumToId.get(rt);
    if (rtId == null) {
      rtId = Schema.SObjectType.LIA_Claim__c.getRecordTypeInfosByName()
        .get(recordTypeToEnumToDeveloperName.get(rt))
        .getRecordTypeId();
      recordTypeEnumToId.put(rt, rtId);
      recordTypeIdToEnum.put(rtId, rt);
    }
    return rtId;
  }

  private static RecordType getRecordTypeEnumById(Id rtId) {
    RecordType rt = recordTypeIdToEnum.get(rtId);
    if (rt == null) {
      rt = recordTypeDeveloperNameToEnum.get(
        Schema.SObjectType.LIA_Claim__c.getRecordTypeInfosById()
          .get(rtId)
          .getName()
      );
      recordTypeEnumToId.put(rt, rtId);
      recordTypeIdToEnum.put(rtId, rt);
    }
    return rt;
  }
}