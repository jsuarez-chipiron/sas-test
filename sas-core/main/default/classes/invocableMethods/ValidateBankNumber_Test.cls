@IsTest
private class ValidateBankNumber_Test {
  @IsTest
  static void shouldReturnInvalidIBAN() {
    // Given
    // Note: Last entry especially important, incorrect country but accidentally correct code (mod 97 means 1/97 of random codeswill be correct)
    List<List<String>> invalidIBANList = new List<List<String>>{
      new List<String>{ 'AL35202111090000000004234567', 'Albania' },
      new List<String>{ 'AD1400080001001234267890', 'Andorra' },
      new List<String>{ 'AT483200000016345864', 'Austria' },
      new List<String>{ 'AZ96AZEJ00000000004234567890', 'Azerbaijan' },
      new List<String>{ 'BH02GITI00001077181611', 'Bahrain' },
      new List<String>{ 'BG63BUKB20201555555555', 'United Kingdom' }
    };
    // When
    List<Boolean> results = new List<Boolean>();
    for (List<String> bankDetails : invalidIBANList) {
      ValidateBankNumber.BankDetails details = new ValidateBankNumber.BankDetails();
      details.accountNumber = bankDetails[0];
      details.bankCountry = bankDetails[1];
      results.add(
        ValidateBankNumber.validate(
          new List<ValidateBankNumber.BankDetails>{ details }
        )[0]
      );
    }

    // Then
    for (Boolean res : results) {
      System.assertEquals(false, res, 'Invalid IBAN validated');
    }
  }

  @IsTest
  static void shouldReturnValidIBAN() {
    // Should we validate "partial IBAN countries"? https://www.iban.com/structure
    // Given
    List<List<String>> validIBANList = new List<List<String>>{
      new List<String>{ 'AL35202111090000000001234567', 'Albania' },
      new List<String>{ 'AD1400080001001234567890', 'Andorra' },
      new List<String>{ 'AT483200000012345864', 'Austria' },
      new List<String>{ 'AZ96AZEJ00000000001234567890', 'Azerbaijan' },
      new List<String>{ 'BH02CITI00001077181611', 'Bahrain' },
      new List<String>{ 'BY86AKBB10100000002966000000', 'Belarus' },
      new List<String>{ 'BE71096123456769', 'Belgium' },
      new List<String>{ 'BA393385804800211234', 'Bosnia and Herzegovina' },
      new List<String>{ 'BR1500000000000010932840814P2', 'Brazil' },
      new List<String>{ 'BG18RZBB91550123456789', 'Bulgaria' },
      new List<String>{ 'CR23015108410026012345', 'Costa Rica' },
      new List<String>{ 'HR1723600001101234565', 'Croatia' },
      new List<String>{ 'CY21002001950000357001234567', 'Cyprus' },
      new List<String>{ 'CZ5508000000001234567899', 'Czech Republic' },
      new List<String>{ 'DK9520000123456789', 'Denmark' },
      new List<String>{ 'DO22ACAU00000000000123456789', 'Dominican Republic' },
      new List<String>{ 'EG800002000156789012345180002', 'Egypt' },
      new List<String>{ 'SV43ACAT00000000000000123123', 'El Salvador' },
      new List<String>{ 'EE471000001020145685', 'Estonia' },
      new List<String>{ 'FO9264600123456789', 'Faroe Islands' },
      new List<String>{ 'FI1410093000123458', 'Finland' },
      new List<String>{ 'FR7630006000011234567890189', 'France' },
      new List<String>{ 'GE60NB0000000123456789', 'Georgia' },
      new List<String>{ 'DE75512108001245126199', 'Germany' },
      new List<String>{ 'GI04BARC000001234567890', 'Gibraltar' },
      new List<String>{ 'GR9608100010000001234567890', 'Greece' },
      new List<String>{ 'GL8964710123456789', 'Greenland' },
      new List<String>{ 'GT20AGRO00000000001234567890', 'Guatemala' },
      new List<String>{ 'VA59001123000012345678', 'Vatican City' },
      new List<String>{ 'HU93116000060000000012345676', 'Hungary' },
      new List<String>{ 'IS750001121234563108962099', 'Iceland' },
      new List<String>{ 'IQ20CBIQ861800101010500', 'Iraq' },
      new List<String>{ 'IE64IRCE92050112345678', 'Ireland' },
      new List<String>{ 'IL170108000000012612345', 'Israel' },
      new List<String>{ 'IT60X0542811101000000123456', 'Italy' },
      new List<String>{ 'JO71CBJO0000000000001234567890', 'Jordan' },
      new List<String>{ 'KZ563190000012344567', 'Kazakhstan' },
      new List<String>{ 'XK051212012345678906', 'Kosovo' },
      new List<String>{ 'KW81CBKU0000000000001234560101', 'Kuwait' },
      new List<String>{ 'LV97HABA0012345678910', 'Latvia' },
      new List<String>{ 'LB92000700000000123123456123', 'Lebanon' },
      new List<String>{ 'LY38021001000000123456789', 'Libya' },
      new List<String>{ 'LI7408806123456789012', 'Liechtenstein' },
      new List<String>{ 'LT601010012345678901', 'Lithuania' },
      new List<String>{ 'LU120010001234567891', 'Luxembourg' },
      new List<String>{ 'MT31MALT01100000000000000000123', 'Malta' },
      new List<String>{ 'MR1300020001010000123456753', 'Mauritania' },
      new List<String>{ 'MU43BOMM0101123456789101000MUR', 'Mauritius' },
      new List<String>{ 'MD21EX000000000001234567', 'Moldova' },
      new List<String>{ 'MC5810096180790123456789085', 'Monaco' },
      new List<String>{ 'ME25505000012345678951', 'Montenegro' },
      new List<String>{ 'NL02ABNA0123456789', 'Netherlands' },
      new List<String>{ 'MK07200002785123453', 'North Macedonia' },
      new List<String>{ 'NO8330001234567', 'Norway' },
      new List<String>{ 'PK36SCBL0000001123456702', 'Pakistan' },
      new List<String>{ 'PS92PALS000000000400123456702', 'Palestine' },
      new List<String>{ 'PL10105000997603123456789123', 'Poland' },
      new List<String>{ 'PT50002700000001234567833', 'Portugal' },
      new List<String>{ 'QA54QNBA000000000000693123456', 'Qatar' },
      new List<String>{ 'RO09BCYP0000001234567890', 'Romania' },
      new List<String>{ 'LC14BOSL123456789012345678901234', 'Saint Lucia' },
      new List<String>{ 'SM76P0854009812123456789123', 'San Marino' },
      new List<String>{ 'ST23000200000289355710148', 'Sao Tome and Principe' },
      new List<String>{ 'SA4420000001234567891234', 'Saudi Arabia' },
      new List<String>{ 'RS35105008123123123173', 'Serbia' },
      new List<String>{ 'SC52BAHL01031234567890123456USD', 'Seychelles' },
      new List<String>{ 'SK8975000000000012345671', 'Slovakia' },
      new List<String>{ 'SI56192001234567892', 'Slovenia' },
      new List<String>{ 'ES7921000813610123456789', 'Spain' },
      new List<String>{ 'SD8811123456789012', 'Sudan' },
      new List<String>{ 'SE7280000810340009783242', 'Sweden' },
      new List<String>{ 'CH5604835012345678009', 'Switzerland' },
      new List<String>{ 'TL380010012345678910106', 'East Timor' },
      new List<String>{ 'TN5904018104004942712345', 'Tunisia' },
      new List<String>{ 'TR320010009999901234567890', 'Turkey' },
      new List<String>{ 'UA903052992990004149123456789', 'Ukraine' },
      new List<String>{ 'AE460090000000123456789', 'United Arab Emirates' },
      new List<String>{ 'GB33BUKB20201555555555', 'United Kingdom' },
      new List<String>{ 'VG21PACG0000000123456789', 'Virgin Islands (British)' }
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (List<String> bankDetails : validIBANList) {
      ValidateBankNumber.BankDetails details = new ValidateBankNumber.BankDetails();
      details.accountNumber = bankDetails[0];
      details.bankCountry = bankDetails[1];
      results.add(
        ValidateBankNumber.validate(
          new List<ValidateBankNumber.BankDetails>{ details }
        )[0]
      );
    }

    // Then
    for (Boolean res : results) {
      System.assertEquals(true, res, 'Valid IBAN invalidated');
    }
  }
  @isTest
  static void shouldReturnInvalidAmerican() {
    // Given
    List<String> invalidABAList = new List<String>{
      '123ABA011103033',
      '123ABA067014832',
      '123ABA211274460',
      '123ABA211370555',
      '123ABA054001735',
      '123ABA211370555',
      '123ABA011400081',
      '123ABA031201370',
      '123ABA026013683',
      '123ABA021302577',
      '123ABA036001818',
      '123ABA011600043',
      '123ABA011103093ABA2',
      '011103093',
      '123ABA123ABA011103093'
    };
    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : invalidABAList) {
      ValidateBankNumber.BankDetails details = new ValidateBankNumber.BankDetails();
      details.accountNumber = num;
      details.bankCountry = 'United States';
      results.add(
        ValidateBankNumber.validate(
          new List<ValidateBankNumber.BankDetails>{ details }
        )[0]
      );
    }

    // Then
    for (Boolean res : results) {
      System.assertEquals(false, res, 'Invalid ABA validated');
    }
  }
  @isTest
  static void shouldReturnValidAmerican() {
    // Given
    List<String> validABAList = new List<String>{
      '123ABA011103093',
      '123ABA067014822',
      '123ABA211274450',
      '123ABA211370545',
      '123ABA054001725',
      '123ABA211370545',
      '123ABA011400071',
      '123ABA031201360',
      '123ABA026013673',
      '123ABA021302567',
      '123ABA053902197',
      '123ABA036001808',
      '123ABA011600033'
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : validABAList) {
      ValidateBankNumber.BankDetails details = new ValidateBankNumber.BankDetails();
      details.accountNumber = num;
      details.bankCountry = 'United States';
      results.add(
        ValidateBankNumber.validate(
          new List<ValidateBankNumber.BankDetails>{ details }
        )[0]
      );
    }

    // Then
    for (Boolean res : results) {
      System.assertEquals(true, res, 'Valid ABA invalidated');
    }
  }

  @isTest
  static void shouldReturnValidOther() {
    // Given
    List<String> randomNumbers = new List<String>{
      'SSDJKA',
      '123',
      'ASDÖ123BBBKKKKS',
      '12341234123412341',
      'ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDF',
      'ASASD123123ASDFASDF213ASDF213',
      'jjSS',
      'XX35202111090000000004234567'
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : randomNumbers) {
      ValidateBankNumber.BankDetails details = new ValidateBankNumber.BankDetails();
      details.accountNumber = num;
      details.bankCountry = 'Xland';
      results.add(
        ValidateBankNumber.validate(
          new List<ValidateBankNumber.BankDetails>{ details }
        )[0]
      );
    }

    // Then
    for (Boolean res : results) {
      System.assertEquals(true, res, 'Random input invalidated');
    }
  }
}
