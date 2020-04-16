/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Delay Event Flow and Message Templates.
*/

public class IRR_MOD_DelayInfo {

    @AuraEnabled
    public String flightId { get; set; }

    @AuraEnabled
    public String flightRef { get; set; }

    @AuraEnabled
    public String stationDeparture { get; set; }

    @AuraEnabled
    public String stationArrival { get; set; }

    @AuraEnabled
    public Integer delayedMinutes { get; set; }

    @AuraEnabled
    public Datetime estimatedTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public String estimatedFormattedLocalTime { get; set; }

    @AuraEnabled
    public Datetime estimatedTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public String delayReasonCode { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureLocal { get; set; }

    @AuraEnabled
    public String scheduledFormattedLocalMonth { get; set; }

    @AuraEnabled
    public String scheduledFormattedLocalDate { get; set; }

    @AuraEnabled
    public String scheduledFormattedLocalTime { get; set; }

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureUTC { get; set; }

    @AuraEnabled
    public Integer previousDelayedMinutes { get; set; }

    @AuraEnabled
    public Integer minutesToScheduledTime { get; set; }

    @AuraEnabled
    public Boolean firstDelay { get; set; }

    @AuraEnabled
    public Integer delayDifference { get; set; }
}