/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_PassengerInfo {

    @AuraEnabled
    public String bookingReference { get; set; }

    @AuraEnabled
    public String SSR { get; set; }

    @AuraEnabled
    public String passengerId { get; set; }

    @AuraEnabled
    public String lastName { get; set; }

    @AuraEnabled
    public String lastNameSlashFirstName { get; set; }

    @AuraEnabled
    public String firstName { get; set; }

    @AuraEnabled
    public String ebLevel { get; set; }

    @AuraEnabled
    public String otherFQTVCarrier { get; set; }

    @AuraEnabled
    public String codsId { get; set; }

    @AuraEnabled
    public Boolean hasPhoneNumber { get; set; }
    @AuraEnabled
    public Boolean hasEmailAddress { get; set; }

    @AuraEnabled
    public String phoneNumber { get; set; }
    @AuraEnabled
    public String emailAddress { get; set; }

    @AuraEnabled
    public Boolean hasThisSegment { get; set; }
    @AuraEnabled
    public IRR_MOD_SegmentInfo thisSegment { get; set; }

    @AuraEnabled
    public Boolean hasNextSegment { get; set; }
    @AuraEnabled
    public IRR_MOD_SegmentInfo nextSegment { get; set; }

}