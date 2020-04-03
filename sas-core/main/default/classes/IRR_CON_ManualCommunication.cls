/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Controller class for the Manual Communication Lightning Web Component.
*/

public class IRR_CON_ManualCommunication {

    private static final String EVENT_TYPE = 'manualCommunication';

    public static List<IRR_MOD_PassengerInfo> getBookingPassengerInfos(String bookingId) {
        return IRR_SVC_TedsService.getPassengerInfosForBooking(bookingId);
    }

    public static List<IRR_MOD_PassengerInfo> getFlightPassengerInfos(String flightId) {
        return IRR_SVC_TedsService.getPassengerInfosForFlight(flightId);
    }

    public static void sendMessages(IRR_MOD_ManualInfo manualCommunication) {
        IRR_SVC_EventService.processEvent(EVENT_TYPE, manualCommunication);
    }
}