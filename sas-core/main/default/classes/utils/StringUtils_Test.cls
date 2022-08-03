@IsTest
private class StringUtils_Test {
  @IsTest
  static void isEmailAddressShouldReturnFalseForEmptyString() {
    Boolean res = StringUtils.isEmailAddress('');
    System.assertEquals(false, res, 'Empty input should return false');
  }

  @IsTest
  static void isEmailAddressShouldReturnFalseForNull() {
    Boolean res = StringUtils.isEmailAddress(null);
    System.assertEquals(false, res, 'Null input should return false');
  }

  @IsTest
  static void isEmailAddressShouldReturnTrueForValidEmail() {
    // Just sanity checking a simple example.
    Boolean res = StringUtils.isEmailAddress('test@example.com');
    System.assertEquals(
      true,
      res,
      'test@example.com should be a valid email address.'
    );
  }

  @IsTest
  static void itShouldBePossibleToRemoveWhiteSpace() {
    String nullString = null;
    String emptyString = '';
    String withDifferentTypesOfSpaces = 'a  b\u00A0c';
    String withZeroWidthSpace = 'a\u200Bb\uFEFFc';

    System.assertEquals(
      null,
      StringUtils.removeWhitespace(nullString),
      'Null string should return null.'
    );
    System.assertEquals(
      '',
      StringUtils.removeWhitespace(emptyString),
      'Empty string should return itself'
    );
    System.assertEquals(
      'abc',
      StringUtils.removeWhitespace(withDifferentTypesOfSpaces),
      'Visible spaces should be removed'
    );
    System.assertEquals(
      'abc',
      StringUtils.removeWhitespace(withZeroWidthSpace),
      'Zero-width spaces should be removed'
    );
  }
}
