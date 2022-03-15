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
      ContentVersion.SObjectType => ContentVersionsSelector.class,
      Customer__c.SObjectType => CustomersSelector.class,
      Exchange_Rate__c.SObjectType => ExchangeRatesSelector.class,
      Flight__c.SObjectType => FlightsSelector.class,
      LIA_Claim__c.SObjectType => ClaimsSelector.class,
      LiveChatTranscript.SObjectType => ChatTranscriptsSelector.class,
      MessagingSession.SObjectType => MessagingSessionsSelector.class,
      Passenger__c.SObjectType => PassengersSelector.class,
      Proactivity__c.SObjectType => ProactivitiesSelector.class,
      Racer_Integration_Counter__c.SObjectType => RacerIntegrationCountersSelector.class,
      Refund_Request__c.SObjectType => Refund_RequestsSelector.class,
      Segment__c.SObjectType => SegmentsSelector.class,
      Settlement__c.SObjectType => SettlementsSelector.class,
      Settlement_Item__c.SObjectType => SettlementItemsSelector.class,
      SocialPost.SObjectType => SocialPostsSelector.class,
      Travel_Pass_Product__c.SObjectType => TravelPassProductsSelector.class
    }
  );

  public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
    SAS_Service_Application.Selector,
    new Map<SObjectType, Type>{
      Account.SObjectType => Accounts.Constructor.class,
      ContentVersion.SObjectType => ContentVersions.Constructor.class,
      Case.SObjectType => Cases.Constructor.class,
      Customer__c.SObjectType => Customers.Constructor.class,
      EmailMessage.SObjectType => EmailMessages.Constructor.class,
      Exchange_Rate__c.SObjectType => ExchangeRates.Constructor.class,
      LIA_Claim__c.SObjectType => Claims.Constructor.class,
      LiveChatTranscript.SObjectType => LiveChatTranscripts.Constructor.class,
      MessagingSession.SObjectType => MessagingSessions.Constructor.class,
      Passenger__c.SObjectType => Passengers.Constructor.class,
      Refund_Request__c.SObjectType => Refund_Requests.Constructor.class,
      Settlement__c.SObjectType => Settlements.Constructor.class,
      Settlement_Item__c.SObjectType => SettlementItems.Constructor.class,
      SocialPost.SObjectType => SocialPosts.Constructor.class
    }
  );

  public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
    new Map<Type, Type>{
      BookingService.class => BookingService.class,
      ClaimsIntegrationService.class => ClaimsIntegrationService.class,
      CLMIntegrationService.class => CLMIntegrationService.class,
      SettlementService.class => SettlementService.class,
      TEDSIntegrationService.class => TEDSIntegrationService.class,
      VoucherIntegrationService.class => VoucherIntegrationService.class
    }
  );

  public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
    new List<SObjectType>{
      Account.SObjectType,
      Booking__c.SObjectType,
      CaseToBooking__c.SObjectType,
      ContentDocumentLink.SObjectType,
      ContentVersion.SObjectType,
      Exchange_Rate__c.SObjectType,
      Flight__c.SObjectType,
      LIA_Claim__c.SObjectType,
      Passenger__c.SObjectType,
      Segment__c.SObjectType,
      Case.SobjectType,
      Refund_Request__c.SobjectType,
      Group_Travel_Request__c.SobjectType,
      Racer_Integration_Counter__c.SObjectType,
      Settlement__c.SObjectType,
      Settlement_Item__c.SObjectType
    }
  );
}
