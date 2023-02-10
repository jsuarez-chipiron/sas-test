/**
 * Utility class which contains various small tools for working within the HTTP
 * layer.
 */
public without sharing class StringUtils {
  /**
   * Constructs a query parameter string from a list of (name, value) parameter tuples.
   * Does not url encode the string.
   *
   * @param params A list of (name, value) tuples of query params. Can be repeated.
   * @return Input parameters as a string of query parameters which can be appended to a url.
   */
  public static Boolean isEmailAddress(String s) {
    if (s == null) {
      return false;
    }

    Pattern emailPattern = Pattern.compile(
      '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})'
    );
    Matcher emailMatcher = emailPattern.matcher(s);

    return emailMatcher.matches();
  }

  /**
   * Removes all whitespace from the given string and returns the result.
   */
  public static String removeWhitespace(String s) {
    if (s == null) {
      return null;
    }

    return s.replaceAll('[\\s\u00A0\u200B-\u200D\uFEFF]+', '');
  }

  /**
   * Converts scandics to two-letter forms.
   *
   * @param s String to sanitize
   */
  public static String scandicsToASCII(String s) {
    return s.replaceAll('ä', 'ae')
      .replaceAll('Ä', 'AE')
      .replaceAll('ö', 'oe')
      .replaceAll('Ö', 'OE')
      .replaceAll('ø', 'oe')
      .replaceAll('Ø', 'OE')
      .replaceAll('æ', 'ae')
      .replaceAll('Æ', 'AE')
      .replaceAll('å', 'o')
      .replaceAll('Å', 'o');
  }

  /**
   * Returns a date with the form XXXXYYZZ
   */
  public static String dateToTEDSString(Date d) {
    String year = String.valueOf(d.year());
    String month = String.valueOf(d.month()).leftPad(2, '0');
    String day = String.valueOf(d.day()).leftPad(2, '0');
    return year + month + day;
  }

  public static String dateToReadable(Date theDate) {
    if (theDate == null) {
      return '-';
    }
    String toReturn =
      String.valueOf(theDate.year()) +
      '-' +
      String.valueOf(theDate.month()) +
      '-' +
      String.valueOf(theDate.day());
    return toReturn;
  }

  public static String dateTimeToReadable(Datetime theDateTime) {
    if (theDateTime == null) {
      return '-';
    }
    String theDate = theDateTime.format('yyyy-MM-dd');
    String theTime = theDateTime.format('HH:mm');
    return theDate + ' at ' + theTime;
  }
}
