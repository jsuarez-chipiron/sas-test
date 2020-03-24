/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_PassengerInfo {

    @AuraEnabled
    public String bookingReference;

    @AuraEnabled
    public String codsId;

    @AuraEnabled
    public Boolean hasPhoneNumber;
    @AuraEnabled
    public Boolean hasEmailAddress;

    @AuraEnabled
    public String phoneNumber;
    @AuraEnabled
    public String emailAddress;

    @AuraEnabled
    public IRR_MOD_SegmentInfo thisSegment;

    @AuraEnabled
    public Boolean hasNextSegment;
    @AuraEnabled
    public IRR_MOD_SegmentInfo nextSegment;

}