@IsTest
private class CountryUtils_Test {
  public static Set<String> airportIdsFromTEDS = new Set<String>{
    'ARN',
    'HEL',
    'ITM',
    'RUN',
    'SYD'
  };

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

  @isTest
  static void shouldCalculateDistanceBetweenAirports() {
    // Given
    Test.setMock(HttpCalloutMock.class, new APIMMock()); // Needed for TEDSbooking-fetches caused by trigger

    // When
    Test.startTest();
    AirportService.newInstance()
      .fetchAirportsByReference(airportIdsFromTEDS, true);
    Test.stopTest();

    // Then
    List<Airport__c> airportsFromDB = AirportsSelector.newInstance()
      .selectByTEDSId(airportIdsFromTEDS);

    Airport__c ARN;
    for (Airport__c a : airportsFromDB) {
      if (a.TEDS_Identifier__c == 'ARN') {
        ARN = a;
        break;
      }
    }

    for (Airport__c a : airportsFromDB) {
      switch on a.TEDS_Identifier__c {
        when 'HEL' {
          System.assertEquals(
            398569,
            CountryUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between ARN and HEL correctly.'
          );
        }
        when 'ITM' {
          System.assertEquals(
            8062362,
            CountryUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between ARN and ITM correctly.'
          );
        }
        when 'RUN' {
          System.assertEquals(
            9584413,
            CountryUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between RUN and ARN correctly.'
          );
        }
        when 'SYD' {
          System.assertEquals(
            15597941,
            CountryUtils.distanceBetweenAirportsInMeters(
              ARN.TEDS_Identifier__c,
              a.TEDS_Identifier__c
            ),
            'Should calculate the distance between SYD and ARN correctly.'
          );
        }
      }
    }
  }
}
