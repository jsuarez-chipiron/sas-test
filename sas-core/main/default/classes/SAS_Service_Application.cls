/**
 * fflib factory configuration for SAS Service. See also IRR_Application.
 */

public class SAS_Service_Application {
  public static final fflib_Application.SelectorFactory Selector = new fflib_Application.SelectorFactory(
    new Map<SObjectType, Type>{
      Account.SObjectType => AccountsSelector.class,
      Booking__c.SObjectType => BookingsSelector.class,
      Case.SObjectType => CasesSelector.class,
      CaseToBooking__c.SObjectType => CaseToBookingsSelector.class,
      Flight__c.SObjectType => FlightsSelector.class,
      Passenger__c.SObjectType => PassengersSelector.class,
      Segment__c.SObjectType => SegmentsSelector.class
    }
  );

  public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
    SAS_Service_Application.Selector,
    new Map<SObjectType, Type>{
      Account.SObjectType => Accounts.Constructor.class,
      Passenger__c.SObjectType => Passengers.Constructor.class
    }
  );

  public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
    new Map<Type, Type>{
      BookingService.class => BookingService.class,
      TEDSIntegrationService.class => TEDSIntegrationService.class
    }
  );

  public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
    new List<SObjectType>{
      Account.SObjectType,
      Booking__c.SObjectType,
      CaseToBooking__c.SObjectType,
      Flight__c.SObjectType,
      Passenger__c.SObjectType,
      Segment__c.SObjectType
    }
  );
}
