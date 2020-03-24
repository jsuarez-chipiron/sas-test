/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Event Flows and Message Templates.
*/

public class IRR_MOD_SegmentInfo {

    @AuraEnabled
    public Boolean isSASTicket;
    @AuraEnabled
    public Boolean isWideroeTicket;

    @AuraEnabled
    public String ticketNumber;

    @AuraEnabled
    public String stationArrival;
    @AuraEnabled
    public String stationDeparture;

    @AuraEnabled
    public Boolean isConfirmed;
    @AuraEnabled
    public String status;

    @AuraEnabled
    public String flightId;
}