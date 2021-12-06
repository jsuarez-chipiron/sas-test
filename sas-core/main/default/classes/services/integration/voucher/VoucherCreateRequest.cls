/**
 * Data structure and parser for Voucher API POST /vouchers endpoint.
 */

public class VoucherCreateRequest {
  public String type; // See VoucherService.VoucherType enum. Internal representation as string to make JSON serialization straightforward.
  public String subType; // See VoucherService.VoucherSubType enum Internal representation as string to make JSON serialization straightforward.
  public String voucherCurrency; // See VoucherService.VoucherCurrency enum Internal representation as string to make JSON serialization straightforward.
  public PersonalDetails personalDetails;
  public VoucherCustomizations voucherCustomizations;

  public class PersonalDetails {
    public String firstName;
    public String lastName;
    public String email;
    public String accessCode;
    public String addressLine;
    public String postalCode;
    public String cityName;
    public String countryName;

    public PersonalDetails(
      String firstName,
      String lastName,
      String email,
      String accessCode,
      String addressLine,
      String postalCode,
      String cityName,
      String countryName
    ) {
      this.firstName = firstName;
      this.lastName = lastName;
      this.email = email;
      this.accessCode = accessCode;
      this.addressLine = addressLine;
      this.postalCode = postalCode;
      this.cityName = cityName;
      this.countryName = countryName;
    }
  }

  public class VoucherCustomizations {
    public Integer value;

    public VoucherCustomizations(Integer value) {
      this.value = value;
    }
  }

  public VoucherCreateRequest(
    VoucherService.VoucherType type,
    VoucherService.VoucherSubType subType,
    VoucherService.VoucherCurrency voucherCurrency,
    Integer value,
    String firstName,
    String lastName,
    String email,
    String accessCode,
    String addressLine,
    String postalCode,
    String cityName,
    String countryName
  ) {
    this.type = String.valueOf(type);
    this.subType = String.valueOf(subType);
    this.voucherCurrency = String.valueOf(voucherCurrency);

    personalDetails = new PersonalDetails(
      firstName,
      lastName,
      email,
      accessCode,
      addressLine,
      postalCode,
      cityName,
      countryName
    );
    voucherCustomizations = new voucherCustomizations(value);
  }
}
