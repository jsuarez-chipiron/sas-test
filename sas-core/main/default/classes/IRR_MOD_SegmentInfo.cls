/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_SegmentInfo {

    @AuraEnabled
    public Boolean isSASTicket { get; set; }
    @AuraEnabled
    public Boolean isWideroeTicket { get; set; }

    @AuraEnabled
    public String ticketNumber { get; set; }

    @AuraEnabled
    public String stationArrival { get; set; }
    @AuraEnabled
    public String stationDeparture { get; set; }

    @AuraEnabled
    public Boolean isConfirmed { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String statusCode { get; set; }

    @AuraEnabled
    public String bookingClass { get; set; }

    @AuraEnabled
    public String serviceClass { get; set; }

    @AuraEnabled
    public String flightId { get; set; }
}