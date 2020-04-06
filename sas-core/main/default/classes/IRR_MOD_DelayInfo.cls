/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Apex Defined Data Structure for IRR Delay Event Flow and Message Templates.
*/

public class IRR_MOD_DelayInfo {

    @AuraEnabled
    public String flightId;

    @AuraEnabled
    public String flightRef;

    @AuraEnabled
    public String stationDeparture;

    @AuraEnabled
    public String stationArrival;

    @AuraEnabled
    public Integer delayedMinutes;

    @AuraEnabled
    public Datetime estimatedTimeOfDepartureLocal;

    @AuraEnabled
    public String estimatedFormattedLocalTime;

    @AuraEnabled
    public Datetime estimatedTimeOfDepartureUTC;

    @AuraEnabled
    public String delayReasonCode;

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureLocal;

    @AuraEnabled
    public String scheduledFormattedLocalMonth;

    @AuraEnabled
    public String scheduledFormattedLocalDate;

    @AuraEnabled
    public String scheduledFormattedLocalTime;

    @AuraEnabled
    public Datetime scheduledTimeOfDepartureUTC;

    @AuraEnabled
    public Integer previousDelayedMinutes;

    @AuraEnabled
    public Integer minutesToScheduledTime;

    @AuraEnabled
    public Boolean firstDelay;

    @AuraEnabled
    public Integer delayDifference;
}