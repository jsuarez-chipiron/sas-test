public without sharing class ValidateBankNumber {
  /*
   * Checks if the bank account number conforms to the IBAN (International Bank Account Number) or the ABA (American Bank Association routing number) format.
   * If the bank country DOES NOT require IBAN (or ABA) the number is treated as valid and the function returns true.
   * If the bank country DOES require IBAN or ABA the function validates it and returns true if it is valid and false if it is invalid.
   */

  // Helper class to handle multiple inputs
  public class BankDetails {
    @InvocableVariable
    public String bankCountry;

    @InvocableVariable
    public String accountNumber;
  }

  @InvocableMethod(label='Validate Bank Account')
  public static List<Boolean> validate(List<BankDetails> bankDetails) {
    String bankCountry;
    String accountNumber;

    try {
      // This function should never crash
      bankCountry = bankDetails[0].bankCountry;
      accountNumber = bankDetails[0].accountNumber;
    } catch (Exception e) {
      return new List<Boolean>{ false };
    }

    return new List<Boolean>{
      BankAccountUtils.validateIBAN(accountNumber, bankCountry)
    };
  }
}
