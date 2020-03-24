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
    public Integer delayMinutes;

    @AuraEnabled
    public String delayedTime;

    @AuraEnabled
    public String delayCode;

    @AuraEnabled
    public String scheduledTime;

    @AuraEnabled
    public Integer previousDelayMinutes;

    @AuraEnabled
    public Integer minutesToScheduledTime;

    @AuraEnabled
    public Boolean firstDelay;

    @AuraEnabled
    public Integer delayDifference;
}