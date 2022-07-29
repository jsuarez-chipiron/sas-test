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
   * @param airport1Id String of the IATA airport code.
   * @param airport2Id String of the IATA airport code.
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    String airport1Id,
    String airport2Id
  ) {
    Double dist = distanceBetweenAirportsInKilometers(airport1Id, airport2Id);
    return Integer.valueOf(
      Decimal.valueOf(dist * 1000).round(System.RoundingMode.HALF_UP)
    );
  }

  /**
   * Calculates the haversine distance in kilometers between two airports (rounded normally).
   *
   * @param airport1Id String of the IATA airport code.
   * @param airport2Id String of the IATA airport code.
   *
   * @return A Double value of the distance in kilometers between the two airports.
   */
  public static Double distanceBetweenAirportsInKilometers(
    String airport1Id,
    String airport2Id
  ) {
    List<Airport__c> airports = getAirports(airport1Id, airport2Id);

    Double long1 = Double.valueOf(airports[0].Longitude__c);
    Double lat1 = Double.valueOf(airports[0].Latitude__c);
    Double long2 = Double.valueOf(airports[1].Longitude__c);
    Double lat2 = Double.valueOf(airports[1].Latitude__c);

    Location loc1 = Location.newInstance(
      airports[0].Latitude__c,
      airports[0].Longitude__c
    );
    Location loc2 = Location.newInstance(
      airports[1].Latitude__c,
      airports[1].Longitude__c
    );
    return Location.getDistance(loc1, loc2, 'km');
  }

  /**
   * @param airport1Id String of the IATA airport code.
   * @param airport2Id String of the IATA airport code.
   * @return a Boolean which asserts if both airports are within EU261-applicable territory
   */
  public static Boolean isIntraCommunity(String airport1Id, String airport2Id) {
    List<Airport__c> airports = getAirports(airport1Id, airport2Id);
    if (
      airports[0].Is_EU261_Applicable__c && airports[1].Is_EU261_Applicable__c
    ) {
      return true;
    }
    return false;
  }

  /**
   * @param airport1Id String of the IATA airport code.
   * @param airport2Id String of the IATA airport code.
   * @return a Boolean which asserts if one of the airports is within EU261-applicable territory
   */
  public static Boolean oneIsInEU261Territory(
    String airport1Id,
    String airport2Id
  ) {
    List<Airport__c> airports = getAirports(airport1Id, airport2Id);
    if (
      airports[0].Is_EU261_Applicable__c || airports[1].Is_EU261_Applicable__c
    ) {
      return true;
    }
    return false;
  }

  private static List<Airport__c> getAirports(
    String airportId1,
    String airportId2
  ) {
    List<Airport__c> airportsFound = AirportsSelector.newInstance()
      .selectAndOrFetchByTEDSId(new Set<String>{ airportId1, airportId2 });
    Airport__c originAirport;
    Airport__c destinationAirport;

    for (Airport__c a : airportsFound) {
      if (a.TEDS_Identifier__c == airportId1) {
        originAirport = a;
      }
      if (a.TEDS_Identifier__c == airportId2) {
        destinationAirport = a;
      }
    }
    if (originAirport == null || destinationAirport == null) {
      throw new AirportNotFoundException('Could not find both airports.');
    }
    return new List<Airport__c>{ originAirport, destinationAirport };
  }

  public class AirportNotFoundException extends Exception {
  }
}
