/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
*/

public interface IRR_SEL_IEventLogsSelector extends fflib_ISObjectSelector {
    
    Database.QueryLocator getQueuedCheckinQueryLocator(String eventLogsStatus);

}

