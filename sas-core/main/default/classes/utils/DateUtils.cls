/**
 * Utility class which handles dates
 */
public without sharing class DateUtils {
  public class DurationTooLongException extends Exception {
  }

  /**
   * Converts a TEDS duration into an Apex Integer which represents the duration in minutes.
   * ISO 8601 duration has the form: P(n)Y(n)M(n)DT(n)H(n)M(n)S.
   * Source: https://www.digi.com/resources/documentation/digidocs/90001437-13/reference/r_iso_8601_duration_format.htm
   *
   * @param duration A String which holds the duration received from TEDS
   *
   * @throws DurationTooLongException When the duration contains years or months.
   *
   * @return An Apex Integer containing the the time in minutes converted from the duration.
   */
  public static Integer convertISO8601DurationToMinutes(String duration) {
    if (duration == null) {
      return 0;
    }
    List<Integer> characters = duration.getChars();
    Integer count = 0;
    Integer minutes = 0;
    Boolean isDate = true;
    for (Integer character : characters) {
      if (47 < character && character < 58) {
        count = 10 * count + character - 48;
      }
      if (character == 89) {
        // Year
        throw new DurationTooLongException('Duration contains years.'); // Because of time ambiguity
      }
      if (character == 77 && isDate) {
        // Month
        throw new DurationTooLongException('Duration contains months.'); // Because of time ambiguity
      }
      if (character == 68) {
        // Day
        minutes += count * 24 * 60; // Convert days to hours
        count = 0;
      }
      if (character == 84) {
        // T (the next m stands for "minutes" not "months")
        isDate = false;
      }
      if (character == 72) {
        // Hour
        minutes += count * 60;
        count = 0;
      }
      if (character == 77 && !isDate) {
        // Minute
        minutes += count;
        count = 0;
      }
    }

    return minutes;
  }
}
