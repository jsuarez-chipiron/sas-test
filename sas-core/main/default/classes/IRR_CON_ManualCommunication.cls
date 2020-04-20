/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Controller class for the Manual Communication LWC page.
*/

public class IRR_CON_ManualCommunication {

    private static final String EVENT_TYPE = 'manualCommunication';

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getBookingPassengerInfos(String bookingId) {
        try {
            return IRR_SVC_TedsService.getPassengerInfosForBooking(bookingId);
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static List<IRR_MOD_PassengerInfo> getFlightPassengerInfos(String flightId) {
        try {
            return IRR_SVC_TedsService.getPassengerInfosForFlight(flightId);
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static void sendManualCommunication(IRR_MOD_ManualRequest manualRequest) {
        try {
            IRR_SVC_CommunicationService.processEvent(EVENT_TYPE, manualRequest);
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    @AuraEnabled
    public static Map<String, List<IRR_ManualCommunicationTemplate__mdt>> getManualTemplatesBySendMode() {
        try {
            List<IRR_ManualCommunicationTemplate__mdt> templates = IRR_SEL_ManualTemplatesSelector.newInstance()
                    .selectAllManualCommunicationTemplates();
            Map<String, List<IRR_ManualCommunicationTemplate__mdt>> manualTemplatesBySendMode =
                    new Map<String, List<IRR_ManualCommunicationTemplate__mdt>>();
            for (IRR_ManualCommunicationTemplate__mdt template : templates) {
                if (!manualTemplatesBySendMode.containsKey(template.IRR_SendMode__c)) {
                    manualTemplatesBySendMode.put(
                            template.IRR_SendMode__c, new List<IRR_ManualCommunicationTemplate__mdt>());
                }
                manualTemplatesBySendMode.get(template.IRR_SendMode__c).add(template);
            }
            return manualTemplatesBySendMode;
        }
        catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }
}