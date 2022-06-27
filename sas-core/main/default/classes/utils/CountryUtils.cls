/**
 * Utility class which handles Countries
 */
public without sharing class CountryUtils {
  // Maps the country codes which are associated with another country in a "child to parent"-type relationship, e.g. Åland (AX) to Finland (FI).
  private static Map<String, String> formCountryCodeToIBANCountryCode = new Map<String, String>{
    'GF' => 'FR',
    'GP' => 'FR',
    'MQ' => 'FR',
    'RE' => 'FR',
    'PF' => 'FR',
    'TF' => 'FR',
    'YT' => 'FR',
    'NC' => 'FR',
    'BL' => 'FR',
    'MF' => 'FR',
    'PM' => 'FR',
    'WF' => 'FR',
    'IM' => 'GB',
    'GG' => 'GB',
    'JE' => 'GB',
    'AX' => 'FI'
  };

  /**
   * Converts the contry codes which are available for selection in the front end to the country codes which their banking system uses for IBAN, e.g. AX -> FI.
   * Source 1: https://www.iban.com/structure
   * Source 2: https://www.iban.com/iban-mandatory
   *
   * @param formCountryCode A String of the country short code derived from the form.
   * @return A String of the name of the "Parent" country short code
   */
  public static String formCountryCodeToIBANCountryCode(
    String formCountryCode
  ) {
    if (formCountryCodeToIBANCountryCode.keySet().contains(formCountryCode)) {
      return formCountryCodeToIBANCountryCode.get(formCountryCode);
    }
    return formCountryCode;
  }
}
