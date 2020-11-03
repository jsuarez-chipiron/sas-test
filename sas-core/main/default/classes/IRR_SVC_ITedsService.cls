/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_ITedsService {
    List<IRR_MOD_PassengerInfo> getPassengerInfosForBooking(String bookingId);
    List<IRR_MOD_PassengerInfo> getPassengerInfosForFlight(String flightId);
}