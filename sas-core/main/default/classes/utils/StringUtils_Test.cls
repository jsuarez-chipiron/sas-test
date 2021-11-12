@IsTest
private class StringUtils_Test {
  @IsTest
  static void isEmailAddressShouldReturnFalseForEmptyString() {
    Boolean res = StringUtils.isEmailAddress(
      ''
    );
    System.assertEquals(
      false,
      res,
      'Empty input should return false'
    );
  }

  @IsTest
  static void isEmailAddressShouldReturnFalseForNull() {
    Boolean res = StringUtils.isEmailAddress(
      null
    );
    System.assertEquals(
      false,
      res,
      'Null input should return false'
    );
  }

  @IsTest
  static void isEmailAddressShouldReturnTrueForValidEmail() {
    // Just sanity checking a simple example.
    Boolean res = StringUtils.isEmailAddress(
      'test@example.com'
    );
    System.assertEquals(
      true,
      res,
      'test@example.com should be a valid email address.'
    );
  }

}
