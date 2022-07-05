/**
 * Utility class which handles case/claim automation
 */
public without sharing class AutomationUtils {
  public class invalidPNRTypeException extends Exception {
  }

  /**
   * @param claims
   *
   * Todo: rethink, make batchable
   *
   * @return A map from claim id to whether that claim has been automated.
   */
  public static Map<Id, Boolean> automateEU261(Set<Id> claimIds) {
    Map<Id, Boolean> claimToWasAutomated = new Map<Id, Boolean>{};

    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectById(claimIds);
    Map<LIA_Claim__c, BookingJSON> claimToBooking = new Map<LIA_Claim__c, BookingJSON>{};

    // Get information, TODO: Make batchable, use Set<Id>, don't overfetch, handle duplication
    for (LIA_Claim__c c : claims) {
      claimToWasAutomated.put(c.Id, false);
      List<BookingJSON> bookings = CustomerCardController.getBookingsForCase(
        String.valueOf(c.Case__c)
      );
      for (BookingJSON b : bookings) {
        if (b.bookingReference == c.Liability_PNR__c) {
          claimToBooking.put(c, b);
          break;
        }
      }
    }

    // TODO: Determine if current automation implementation is able to automate this case
    List<LIA_Claim__c> automatableClaims = areSupportedForAutomation(
      claimToBooking
    );

    for (LIA_Claim__c c : automatableClaims) {
      BookingJSON b = claimToBooking.get(c);
      // TODO: Determine if EU261 is applicable
      // Was the flight from/to the right place
      if (!isCoveredByEU261(c, b)) {
        System.debug('This claim is not covered by EU261');
        continue;
      }

      // TEST: Determine if the claim is filed on time
      if (!isFiledOnTime(c, b)) {
        System.debug('This claim was not filed on time');
        continue;
      }

      // TODO: Determine if a claim is a duplicate
      if (isDuplicate(c, b)) {
        System.debug('This claim is a duplicate');
        continue;
      }
      // TODO: ~Check proactivities and similar cases

      // TODO: Determine if it is a delay or a case and handle differently
      if (true) {
        claimToWasAutomated.put(c.Id, automateEU261Delay(c, b));
      } else {
        claimToWasAutomated.put(c.Id, automateEU261Cancellation(c, b));
      }
      // TODO: Remove silvertape
    }

    return claimToWasAutomated;
  }

  // DELAY
  private static Boolean automateEU261Delay(LIA_Claim__c c, BookingJSON b) {
    // TODO: D: Check delay time
    Integer minutesDelayed = getMinutesDelayed(c, b);

    if (minutesDelayed < 120) {
      // Reject
    } else {
      // TODO: ~Calculate revenue
      // TODO: ~Check if SAS is responsible
      // TODO: ~Check if within SAS control
      // TODO: ~Check if case is handled on behalf of another
      // TODO: ~Check if care compensation + calculate care compensation
      // TODO: Check flight distance
      // TODO: (c)Send compensation
      // TODO: (c)Check reason and main rule
    }
    return true;
  }

  // CANCELLATION
  private static Boolean automateEU261Cancellation(
    LIA_Claim__c c,
    BookingJSON b
  ) {
    // TODO: Understand
    return null;
  }

  private static Boolean isCoveredByEU261(LIA_Claim__c c, BookingJSON b) {
    return true;
  }

  public class NoMatchingFlightException extends Exception {
  }

  private static BookingJSON.Flight getRelevantFlight(
    LIA_Claim__c claim,
    BookingJSON booking
  ) {
    BookingJSON.Flight flight;
    for (BookingJSON.Flight f : booking.flights) {
      // TODO: Make this more robust.
      if (f.flightNumber == claim.Flight_Number__c.substringBefore('-')) {
        flight = f;
      }
    }
    if (flight == null) {
      throw new NoMatchingFlightException(
        'The flight number in the claim does not match any flight in the booking.'
      );
    }
    return flight;
  }

  public static Boolean isFiledOnTime(LIA_Claim__c claim, BookingJSON booking) {
    BookingJSON.Flight flight = getRelevantFlight(claim, booking);
    Datetime claimCreation = claim.CreatedDate; // TODO: Should this be the case creation date?
    Datetime flightDate = flight.scheduledArrivalTime;
    return DateUtils.isEligableForCompensation(claimCreation, flightDate);
  }

  public class NoDelayException extends Exception {
  }

  private static Integer getMinutesDelayed(
    LIA_Claim__c claim,
    BookingJSON booking
  ) {
    BookingJSON.Flight flight = getRelevantFlight(claim, booking);
    if (
      flight.arrivalDelayedMinutes == null ||
      flight.arrivalDelayedMinutes <= 0
    ) {
      throw new NoDelayException(
        'The delay is null or less than or equal to 0 minutes'
      );
    }
    return flight.arrivalDelayedMinutes.intValue();
  }

  private static Integer getFlightDistanceKm(
    LIA_Claim__c claim,
    BookingJSON booking
  ) {
    BookingJSON.Flight flight = getRelevantFlight(claim, booking);

    // Get locations

    // Get haversine distance

    return 1;
  }

  private static Boolean isDuplicate(LIA_Claim__c claim, BookingJSON booking) {
    return false;
  }

  private static List<LIA_Claim__c> areSupportedForAutomation(
    Map<LIA_Claim__c, BookingJSON> claimToBooking
  ) {
    List<LIA_Claim__c> automatableClaims = new List<LIA_Claim__c>{};

    for (LIA_Claim__c claim : claimToBooking.keySet()) {
      BookingJSON booking = claimToBooking.get(claim);

      switch on booking.type {
        when 'DayReturn' {
          notSupported(booking.type);
        }
        when 'MultiCity' {
          notSupported(booking.type);
        }
        when 'OneWay' {
          if (booking.flights.size() == 1) {
            automatableClaims.add(claim);
          } else {
            notSupported(booking.type + ' (multiple flights) ');
          }
        }
        when 'RoundTrip' {
          notSupported(booking.type);
        }
        when 'Unknown' {
          notSupported(booking.type);
        }
        when else {
          // Erronous data from TEDS
          throw new invalidPNRTypeException();
        }
      }
    }
    return automatableClaims;
  }

  private static void notSupported(String type) {
    System.debug(
      'Claims with: ' +
      type +
      ' bookings are not currently supported for EU261 automation.'
    );
  }
}
