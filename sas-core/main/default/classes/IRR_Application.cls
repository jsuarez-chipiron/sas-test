/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Application specific configuration for various factories.
*/

public class IRR_Application {

    public enum MessageType { SMS, Email }

    public enum IntegrationType { REST, SOAP }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the IntegrationExecutorBuilder for this Application.
     */
    public static final C_Application.IntegrationExecutorBuilderFactory IntegrationExecutorBuilder =
            new C_Application.IntegrationExecutorBuilderFactory(
                    new Map<Object, Type> {
                            IntegrationType.REST => C_IntegrationExecutorRest.Constructor.class
                    }
            );

    public static final C_Application.MessageRendererFactory MessageRenderer =
            new C_Application.MessageRendererFactory();

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the SelectorFactory for this Application.
     */
    public static final fflib_Application.SelectorFactory Selector =
            new fflib_Application.SelectorFactory(
                    new Map<SObjectType, Type> {
                            IRR_DelayLog__c.SObjectType => IRR_SEL_DelayLogsSelector.class,
                            IRR_RecipientWhitelist__mdt.SObjectType => IRR_SEL_RecipientWhitelistSelector.class,
                            Organization.SObjectType => IRR_SEL_OrganizationSelector.class,
                            SFMC_SMSDefinition__mdt.SObjectType => IRR_SEL_SMSDefinitionsSelector.class
                    }
            );

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Configure and create the ServiceFactory for this Application.
     */
    public static final fflib_Application.ServiceFactory Service =
            new fflib_Application.ServiceFactory(
                    new Map<Type, Type>{
                            IRR_SVC_IEventService.class => IRR_SVC_EventServiceImpl.class,
                            IRR_SVC_ISFMCService.class => IRR_SVC_SFMCServiceImpl.class,
                            IRR_SVC_ITedsService.class => IRR_SVC_TedsServiceImpl.class
                    }
            );

    public static final C_Application.EventProcessorFactory EventProcessor =
            new C_Application.EventProcessorFactory(
                    new Map<String, C_Application.EventDefinition> {
                            'flightDepartureDelay' => new C_Application.EventDefinition(
                                    IRR_MOD_DelayInfo.class, IRR_EVT_DelayProcessor.Constructor.class),
                            'manualCommunication' => new C_Application.EventDefinition(
                                    IRR_MOD_ManualInfo.class, IRR_EVT_ManualProcessor.Constructor.class)
                    }
            );


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2019
     *
     * @description Configure and create the UnitOfWorkFactory for this Application
     */
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
            new fflib_Application.UnitOfWorkFactory(
                    new List<SObjectType> {
                            IRR_DelayLog__c.SObjectType,
                            IRR_CommunicationLog__c.SObjectType
                    });
}