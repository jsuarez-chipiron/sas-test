public without sharing class ValidateBIC {
  /*
   * Checks if the BIC number is correctly formatted.
   * If not, false is returned. Otherwise true is returned.
   */
  @InvocableMethod(label='Validate BIC')
  public static List<Boolean> validate(List<String> bicList) {
    String bic = bicList.get(0);
    return new List<Boolean>{ BankAccountUtils.validateBIC(bic) };
  }
}
