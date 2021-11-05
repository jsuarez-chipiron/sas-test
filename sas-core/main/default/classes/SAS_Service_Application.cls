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
      FCS_CaseTag__c.SObjectType => CaseTagsSelector.class,
      ContentVersion.SObjectType => ContentVersionsSelector.class,
      Flight__c.SObjectType => FlightsSelector.class,
      LiveChatTranscript.SObjectType => ChatTranscriptsSelector.class,
      MessagingSession.SObjectType => MessagingSessionsSelector.class,
      Passenger__c.SObjectType => PassengersSelector.class,
      Refund_Request__c.SObjectType => Refund_RequestsSelector.class,
      Segment__c.SObjectType => SegmentsSelector.class,
      SocialPost.SObjectType => SocialPostsSelector.class
    }
  );

  public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
    SAS_Service_Application.Selector,
    new Map<SObjectType, Type>{
      Account.SObjectType => Accounts.Constructor.class,
      Case.SObjectType => Cases.Constructor.class,
      EmailMessage.SObjectType => EmailMessages.Constructor.class,
      LiveChatTranscript.SObjectType => LiveChatTranscripts.Constructor.class,
      Passenger__c.SObjectType => Passengers.Constructor.class,
      Refund_Request__c.SObjectType => Refund_Requests.Constructor.class
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
      ContentDocumentLink.SObjectType,
      ContentVersion.SObjectType,
      Flight__c.SObjectType,
      Passenger__c.SObjectType,
      Segment__c.SObjectType,
      Case.SobjectType,
      Refund_Request__c.SobjectType,
      Group_Travel_Request__c.SobjectType
    }
  );
}
