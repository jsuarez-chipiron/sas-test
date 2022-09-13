/**
 * Represents an individual claim with one-to-one mapping to the underlying
 * sObject.
 */
public without sharing class Claim {
  public RecordType recordType;
  public Category category;
  public Type type;
  public CustomerType customerType;
  public BaggageDelayLength baggageDelayLength;
  public DelayLength delayToDestination;
  public CompensationType preferredCompensationMethod;
  public CompensationType preferredReimbursementMethod;

  public Decimal submittedClaimExpenses { get; private set; } // Roll-up field
  public String contactFirstName;
  public String contactLastName;
  public String eu261HandlingNote;
  public EU261HandlingStatus eu261HandlingStatus;
  public String bookingReference;
  public String pir;

  public LIA_Claim__c underlyingSObject { get; private set; }

  public Boolean containsDetailObjectData { get; private set; }

  public Id parentCaseId;
  public Id id;

  public void updateSObjectFields() {
    this.underlyingSObject.Customer_Claim_Category__c = CATEGORY_ENUM_TO_PICKLIST_VALUE.get(
      this.category
    );
    this.underlyingSObject.Customer_Claim_Type__c = TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.type
    );
    this.underlyingSObject.Delay_Length__c = BAGGAGE_DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE.get(
      this.baggageDelayLength
    );
    this.underlyingSObject.Total_delay_to_final_destination__c = DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE.get(
      this.delayToDestination
    );
    this.underlyingSObject.Type_of_Customer__c = CUSTOMER_TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.customerType
    );
    this.underlyingSObject.Preferred_Compensation_Method__c = COMPENSATION_TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.preferredCompensationMethod
    );
    this.underlyingSObject.Preferred_Reimbursement_Method__c = COMPENSATION_TYPE_ENUM_TO_PICKLIST_VALUE.get(
      this.preferredReimbursementMethod
    );
    this.underlyingSObject.Contact_First_Name__c = this.contactFirstName;
    this.underlyingSObject.Contact_Last_Name__c = this.contactLastName;
    this.underlyingSObject.EU261_Handling_Note__c = this.eu261HandlingNote;
    this.underlyingSObject.EU261_Handling_Status__c = EU261_STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.eu261HandlingStatus
    );
    this.underlyingSObject.Liability_PNR__c = this.bookingReference;
    this.underlyingSObject.PIR__c = this.pir;
    this.underlyingSObject.RecordTypeId = getRecordTypeIdByEnum(
      this.recordType
    );
    this.underlyingSObject.Case__c = this.parentCaseId;
  }

  public Claim() {
    this.underlyingSObject = new LIA_Claim__c();
    this.containsDetailObjectData = false;
  }

  public Claim(LIA_Claim__c c) {
    this();

    // TODO: Throw here if c == null?

    this.id = c.Id;

    this.category = CATEGORY_PICKLIST_VALUE_TO_ENUM.get(
      c.Customer_Claim_Category__c
    );
    this.type = TYPE_PICKLIST_VALUE_TO_ENUM.get(c.Customer_Claim_Type__c);
    this.baggageDelayLength = BAGGAGE_DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM.get(
      c.Delay_Length__c
    );
    this.delayToDestination = DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM.get(
      c.Total_delay_to_final_destination__c
    );
    this.customerType = CUSTOMER_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      c.Type_of_Customer__c
    );
    this.preferredCompensationMethod = COMPENSATION_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      c.Preferred_Compensation_Method__c
    );
    this.preferredReimbursementMethod = COMPENSATION_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      c.Preferred_Reimbursement_Method__c
    );
    this.submittedClaimExpenses = c.Submitted_Claim_Expenses_in_SEK__c;
    this.contactFirstName = c.Contact_First_Name__c;
    this.contactLastName = c.Contact_Last_Name__c;
    this.eu261HandlingNote = c.EU261_Handling_Note__c;
    this.eu261HandlingStatus = EU261_STATUS_PICKLIST_VALUE_TO_ENUM.get(
      c.EU261_Handling_Status__c
    );
    this.bookingReference = c.Liability_PNR__c;
    this.pir = c.PIR__c;
    this.recordType = getRecordTypeEnumById(c.RecordTypeId);
    this.parentCaseId = c.Case__c;
    this.underlyingSObject = c;
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

  public enum CustomerType {
    PrivateCustomer,
    ClaimFirm,
    OtherRepresentative,
    InsuranceCompany
  }

  public enum ExpenseType {
    Accommodation,
    Food,
    Other,
    PhoneCalls,
    Transportation
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

  public static final Map<EU261HandlingStatus, String> EU261_STATUS_ENUM_TO_PICKLIST_VALUE = new Map<EU261HandlingStatus, String>{
    EU261HandlingStatus.Unhandled => 'Unhandled',
    EU261HandlingStatus.EligibleForCompensation => 'Eligible for compensation',
    EU261HandlingStatus.IneligibleForCompensation => 'Ineligible for compensation',
    EU261HandlingStatus.UnableToHandle => 'Unable to handle'
  };

  public static final Map<String, EU261HandlingStatus> EU261_STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, EU261HandlingStatus>{
    'Unhandled' => EU261HandlingStatus.Unhandled,
    'Eligible for compensation' => EU261HandlingStatus.EligibleForCompensation,
    'Ineligible for compensation' => EU261HandlingStatus.IneligibleForCompensation,
    'Unable to handle' => EU261HandlingStatus.UnableToHandle
  };

  public static final Map<CompensationType, String> COMPENSATION_TYPE_ENUM_TO_PICKLIST_VALUE = new Map<CompensationType, String>{
    CompensationType.Voucher => 'Voucher',
    CompensationType.Monetary => 'Monetary',
    CompensationType.EBPoints => 'EBPoints'
  };

  public static final Map<String, CompensationType> COMPENSATION_TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, CompensationType>{
    'Voucher' => CompensationType.Voucher,
    'Monetary' => CompensationType.Monetary,
    'EBPoints' => CompensationType.EBPoints
  };

  public static final Map<String, DelayLength> DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM = new Map<String, DelayLength>{
    '0-2' => DelayLength.ZeroToTwo,
    '2-3' => DelayLength.TwoToThree,
    '3-4' => DelayLength.ThreeToFour,
    '4+' => DelayLength.MoreThanFour,
    'Never arrived' => DelayLength.NeverArrived
  };

  public static final Map<DelayLength, String> DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE = new Map<DelayLength, String>{
    DelayLength.ZeroToTwo => '0-2',
    DelayLength.TwoToThree => '2-3',
    DelayLength.ThreeToFour => '3-4',
    DelayLength.MoreThanFour => '4+',
    DelayLength.NeverArrived => 'Never arrived'
  };

  public static final Map<String, BaggageDelayLength> BAGGAGE_DELAY_LENGTH_PICKLIST_VALUE_TO_ENUM = new Map<String, BaggageDelayLength>{
    'Less than 21 days' => BaggageDelayLength.LessThan21Days,
    '21 days or more' => BaggageDelayLength.MoreThan21Days
  };

  public static final Map<BaggageDelayLength, String> BAGGAGE_DELAY_LENGTH_ENUM_TO_PICKLIST_VALUE = new Map<BaggageDelayLength, String>{
    BaggageDelayLength.LessThan21Days => 'Less than 21 days',
    BaggageDelayLength.MoreThan21Days => '21 days or more'
  };

  public static final Map<String, ExpenseType> EXPENSE_TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, ExpenseType>{
    'Accommodation' => ExpenseType.Accommodation,
    'Food' => ExpenseType.Food,
    'Other' => ExpenseType.Other,
    'Phone calls' => ExpenseType.PhoneCalls,
    'Transportation' => ExpenseType.Transportation
  };

  public static final Map<ExpenseType, String> EXPENSE_TYPE_ENUM_TO_PICKLIST_VALUE = new Map<ExpenseType, String>{
    ExpenseType.Accommodation => 'Accommodation',
    ExpenseType.Food => 'Food',
    ExpenseType.Other => 'Other',
    ExpenseType.PhoneCalls => 'Phone calls',
    ExpenseType.Transportation => 'Transportation'
  };

  public static final Map<String, Category> CATEGORY_PICKLIST_VALUE_TO_ENUM = new Map<String, Category>{
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

  public static final Map<Category, String> CATEGORY_ENUM_TO_PICKLIST_VALUE = new Map<Category, String>{
    Category.AccidentAndInjury => 'Accident &amp; injury',
    Category.AirportExperience => 'Airport experience',
    Category.Baggage => 'Baggage',
    Category.Booking => 'Booking',
    Category.FlightDisruptions => 'Flight disruptions',
    Category.FlightExperience => 'Flight experience',
    Category.Other => 'Other',
    Category.PassengerIrregularities => 'Passenger irregularities',
    Category.TravelExtras => 'Travel extras bought not rendered'
  };

  public static final Map<CustomerType, String> CUSTOMER_TYPE_ENUM_TO_PICKLIST_VALUE = new Map<CustomerType, String>{
    CustomerType.ClaimFirm => 'Claim firm',
    CustomerType.InsuranceCompany => 'Insurance company',
    CustomerType.OtherRepresentative => 'Other representative',
    CustomerType.PrivateCustomer => 'Private customer'
  };

  public static final Map<String, CustomerType> CUSTOMER_TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, CustomerType>{
    'Claim firm' => CustomerType.ClaimFirm,
    'Insurance company' => CustomerType.InsuranceCompany,
    'Other representative' => CustomerType.OtherRepresentative,
    'Private customer' => CustomerType.PrivateCustomer
  };

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

  public static final Map<String, Type> TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, Type>{
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

  public static final Map<Type, String> TYPE_ENUM_TO_PICKLIST_VALUE = new Map<Type, String>{
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

  public static Map<RecordType, String> recordTypeToEnumToDeveloperName = new Map<RecordType, String>{
    RecordType.CompensationCard => 'CompensationCard',
    RecordType.CustomerClaim => 'CustomerClaim',
    RecordType.LiabilityClaim => 'LiabilityClaim'
  };

  public static Map<String, RecordType> recordTypeDeveloperNameToEnum = new Map<String, RecordType>{
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
