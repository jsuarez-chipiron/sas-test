/**
* @author Ludvig Wäilmaa, Deloitte
* @date 2020
*
*/

public interface IRR_SEL_ISMSResponsesSelector extends fflib_ISObjectSelector {
    List<IRR_SMSResponse__C> selectSMSResponsesWithCommunicationLogs(Set<Id> comIds);
}