@IsTest
private class CountryUtils_Test {
  @IsTest
  static void shouldReplaceCountryCode() {
    // Given
    List<String> countryFormCountryCodes = new List<String>{
      'GF',
      'GP',
      'MQ',
      'RE',
      'PF',
      'TF',
      'YT',
      'NC',
      'BL',
      'MF',
      'PM',
      'WF',
      'IM',
      'GG',
      'JE',
      'AX',
      'SE',
      'FI',
      'AL'
    };
    List<String> countryIBANCountryCodes = new List<String>{
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'FR',
      'GB',
      'GB',
      'GB',
      'FI',
      'SE',
      'FI',
      'AL'
    };
    List<String> convertedCountryCodes = new List<String>{};

    // When
    for (String code : countryFormCountryCodes) {
      convertedCountryCodes.add(
        CountryUtils.countryCodeToIBANCountryCode(code)
      );
    }

    // Then
    for (Integer i = 0; i < convertedCountryCodes.size(); i++) {
      System.assertEquals(
        countryIBANCountryCodes[i],
        convertedCountryCodes[i],
        'Country code should be converted correctly'
      );
    }
  }

  @IsTest
  static void shouldGetCountryFromCountryCode() {
    // Given
    List<String> countryFormCountryCodes = new List<String>{
      'GF',
      'JE',
      'AX',
      'SE',
      'NOTACODE'
    };
    List<String> IBANCountries = new List<String>{
      'France',
      'United Kingdom',
      'Finland',
      'Sweden',
      null
    };
    List<String> countries = new List<String>{};

    // When
    for (String code : countryFormCountryCodes) {
      countries.add(CountryUtils.getCountryNameByShortCode(code));
    }

    // Then
    for (Integer i = 0; i < countries.size(); i++) {
      System.assertEquals(
        IBANCountries[i],
        countries[i],
        'Country name not gotten correctly'
      );
    }
  }

  @IsTest
  static void shouldAssertIfInEUOrNorwaySwitzerlandIceland() {
    // Given
    List<String> countryCodes = new List<String>{
      'GF',
      'SE',
      'MQ',
      'JE',
      'US',
      'NOTACODE'
    };
    List<Boolean> isInEuCorrect = new List<Boolean>{
      true,
      true,
      true,
      false,
      false,
      false
    };
    List<Boolean> isInEu = new List<Boolean>{};

    // When
    for (String code : countryCodes) {
      isInEu.add(CountryUtils.isInEUOrNorwaySwitzerlandIceland(code));
    }

    // Then
    for (Integer i = 0; i < isInEu.size(); i++) {
      System.assertEquals(
        isInEuCorrect[i],
        isInEu[i],
        'Should determine if country is in the EU or not.'
      );
    }
  }
}
