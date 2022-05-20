@IsTest
private class ValidateBIC_Test {
  @IsTest
  static void shouldInvalidateBICNumberAndReturnFalse() {
    // Given
    String invalidBIC = 'MIDLGB2';

    // When
    Boolean res = ValidateBIC.validate(new List<String>{ invalidBIC })[0];

    // Then
    System.assert(
      !res,
      'The function validated (returned true) an invalid BIC number'
    );
  }

  @IsTest
  static void shouldValidateBICNumberAndReturnTrue() {
    // Given
    String validBIC = 'MIDLGB22';

    // When
    Boolean res = ValidateBIC.validate(new List<String>{ validBIC })[0];

    // Then
    System.assert(
      res,
      'The function invalidated (returned false) a valid BIC number'
    );
  }
}
