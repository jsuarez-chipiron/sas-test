/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SVC_ITedsService {
    IRR_MOD_TedsBooking getBookingDetails(String bookingId);
    List<IRR_MOD_TedsBooking> getBookingDetailsForFlight(String flightId);
    List<IRR_MOD_PassengerInfo> getPassengerInfosForFlight(String flightId);
}