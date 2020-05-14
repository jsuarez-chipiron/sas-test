/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public class IRR_MOD_TripInfo {

    @AuraEnabled
    public String tripType { get; set; }

    @AuraEnabled
    public List<IRR_MOD_SegmentInfo> segments { get; set; }

}