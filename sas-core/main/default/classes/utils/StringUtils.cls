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
}