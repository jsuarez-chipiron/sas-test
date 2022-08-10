/**
 * Utility class which handles Countries
 */
public without sharing class CountryUtils {
  // Maps the country codes which are associated with another country in a "child to parent"-type relationship, e.g. Åland (AX) to Finland (FI).
  private static Map<String, String> countryCodeToIBANCountryCode = new Map<String, String>{
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

  // TODO: Consider: This could be stored in the settlement country settings
  // Source: https://european-union.europa.eu/principles-countries-history/country-profiles_en
  private static Set<String> countryCodesInEU = new Set<String>{
    'AT',
    'BE',
    'BG',
    'HR',
    'CY',
    'CZ',
    'DK',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'HU',
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'NL',
    'PL',
    'PT',
    'RO',
    'SK',
    'SL',
    'ES',
    'SE'
  };

  private static Set<String> countryCodesNotInEUButEU261Applicable = new Set<String>{
    'NO',
    'CH',
    'IS'
  };

  public static String getCountryNameByShortCode(String countryShortCode) {
    String convertedShortCode = countryCodeToIBANCountryCode(countryShortCode);
    String countryName;
    try {
      countryName = [
        SELECT Country_Name__c
        FROM Settlement_Country_Setting__mdt
        WHERE Country_Short_Code__c = :convertedShortCode
      ]
      .Country_Name__c;
    } catch (Exception e) {
      // Incorrect country short code, return null
    }

    return countryName;
  }

  /**
   * Converts the contry codes which are available for selection in the front end to the country codes which their banking system uses for IBAN, e.g. AX -> FI.
   * Source 1: https://www.iban.com/structure
   * Source 2: https://www.iban.com/iban-mandatory
   *
   * @param formCountryCode A String of the country short code derived from the form.
   * @return A String of the name of the "Parent" country short code
   */
  public static String countryCodeToIBANCountryCode(String formCountryCode) {
    if (countryCodeToIBANCountryCode.keySet().contains(formCountryCode)) {
      return countryCodeToIBANCountryCode.get(formCountryCode);
    }
    return formCountryCode;
  }

  /**
   * Asserts whether the country is within the european union.
   * Source 1: https://european-union.europa.eu/principles-countries-history/country-profiles_en?page=0
   * Source 2: https://www.iban.com/country-codes
   *
   * @param countryOrTerritoryCode A String of a country (or territory) short code.
   * @return A Boolean
   */
  public static Boolean isInEU(String countryOrTerritoryCode) {
    String countryCode = countryCodeToIBANCountryCode(countryOrTerritoryCode);

    if (countryCodesInEU.contains(countryCode)) {
      return true;
    }

    return false;
  }

  /**
   * Asserts whether the country is within the european union, Norway, Switzerland or Iceland (EU261).
   * Source 1: https://european-union.europa.eu/principles-countries-history/country-profiles_en?page=0
   * Source 2: https://www.iban.com/country-codes
   * Source 3: https://europa.eu/youreurope/citizens/travel/passenger-rights/air/index_en.htm
   *
   * @param countryOrTerritoryCode A String of a country (or territory) short code.
   * @return A Boolean
   */
  public static Boolean isInEUOrNorwaySwitzerlandIceland(
    String countryOrTerritoryCode
  ) {
    if (isInEU(countryOrTerritoryCode)) {
      return true;
    } else if (
      countryCodesNotInEUButEU261Applicable.contains(countryOrTerritoryCode)
    ) {
      return true;
    }
    return false;
  }

  /**
   * Calculates the haversine distance in meters between two airports.
   *
   * @param airport1 an Airport__c
   * @param airport2 an Airport__c
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    Airport__c airport1,
    Airport__c airport2
  ) {
    Double dist = distanceBetweenAirportsInKilometers(airport1, airport2);
    return Integer.valueOf(
      Decimal.valueOf(dist * 1000).round(System.RoundingMode.HALF_UP)
    );
  }

  /**
   * Calculates the haversine distance in kilometers between two airports (rounded normally).
   *
   * @param airport1 an Airport__c
   * @param airport2 an Airport__c
   *
   * @return A Double value of the distance in kilometers between the two airports.
   */
  public static Double distanceBetweenAirportsInKilometers(
    Airport__c airport1,
    Airport__c airport2
  ) {
    if (airport1 == null || airport2 == null) {
      throw new AirportsNotDefinedException(
        'At least one of the airports equal to null.'
      );
    }

    Double long1 = Double.valueOf(airport1.Longitude__c);
    Double lat1 = Double.valueOf(airport1.Latitude__c);
    Double long2 = Double.valueOf(airport2.Longitude__c);
    Double lat2 = Double.valueOf(airport2.Latitude__c);

    Location loc1 = Location.newInstance(
      airport1.Latitude__c,
      airport1.Longitude__c
    );
    Location loc2 = Location.newInstance(
      airport2.Latitude__c,
      airport2.Longitude__c
    );
    return Location.getDistance(loc1, loc2, 'km');
  }

  public class AirportsNotDefinedException extends Exception {
  }
}
