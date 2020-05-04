/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Concrete implementation of Teds Service functionality.
*/

public class IRR_SVC_TedsServiceImpl implements IRR_SVC_ITedsService {

    private static final String NAMED_CREDENTIAL = 'callout:SAS_APIM_TEDS';

    private static String APIM_SUBSCRIPTION_KEY {
        get {
            if (APIM_SUBSCRIPTION_KEY == null) {
                Organization org = IRR_SEL_OrganizationSelector.newInstance().selectOrganization();
                APIM_SUBSCRIPTION_KEY = org.IsSandbox || Test.isRunningTest() ? 'b8568217401c49acb3931605cea78835' :
                    '992845b5bd6144b0980ade19ac8902f5';
            }
            return APIM_SUBSCRIPTION_KEY;
        }
        private set;
    }

    private static final String API_VERSION = 'v2';

    private static final String BOOKING_ENDPOINT_TEMPLATE = '/teds-booking/bookings/{0}';
    private static final String BOOKINGS_FILTER_ENDPOINT = '/teds-booking/bookings';

    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .setAPIVersion(API_VERSION)
                                .setAPIMSubscriptionKey(APIM_SUBSCRIPTION_KEY)
                                .build();
            }
            return integrationExecutor;
        }
        private set;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves Booking Details by booking reference.
     *
     * @param bookingId Booking Reference to retrieve details for
     *
     * @return Retrieved Booking Details
     */
    private IRR_MOD_TedsBooking getBookingDetails(String bookingId) {
        String endpointURL = String.format(BOOKING_ENDPOINT_TEMPLATE, new List<String>{bookingId});
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(endpointURL, C_IntegrationExecutor.Method.GET, null, null);
        if (responseObject.statusCode >= 300 || responseObject.statusCode<200) {
            throwTedsException(responseObject.responseBody);
        }
        IRR_MOD_TedsBooking parsedResponse = IRR_MOD_TedsBooking.parse(responseObject.responseBody);
        return parsedResponse;
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves booking details and creates Passenger Infos for all passengers in a booking.
     *
     * @param bookingId Flight Id to retrieve bookings for
     *
     * @return List of Retrieved Booking Details
     */
    public List<IRR_MOD_PassengerInfo> getPassengerInfosForBooking(String bookingId) {
        IRR_MOD_TedsBooking bookings = getBookingDetails(bookingId);
        return initiatePassengerInfos(new List<IRR_MOD_TedsBooking>{bookings}, null);
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves a list of booking details by flight id.
     *
     * @param flightId Flight Id to retrieve bookings for
     *
     * @return List of retrieved Booking Details
     */
    private List<IRR_MOD_TedsBooking> getBookingDetailsForFlight(String flightId) {
        Map<String, String> queryParams = new Map<String, String>{
                'flightId' => flightId
        };
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(BOOKINGS_FILTER_ENDPOINT, C_IntegrationExecutor.Method.GET, null, queryParams);
        if (responseObject.statusCode >= 300 || responseObject.statusCode < 200) {
            throwTedsException(responseObject.responseBody);
        }
        List<IRR_MOD_TedsBooking> tedsBookings = IRR_MOD_TedsBooking.parseArray(responseObject.responseBody);
        return tedsBookings;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Retrieves booking details and creates Passenger Infos for all passengers of a flight.
     *
     * @param flightId Flight Id to retrieve bookings for
     *
     * @return List of Retrieved Booking Details
     */
    public List<IRR_MOD_PassengerInfo> getPassengerInfosForFlight(String flightId) {
        List<IRR_MOD_TedsBooking> tedsBookings = getBookingDetailsForFlight(flightId);
        return initiatePassengerInfos(tedsBookings, flightId);
    }

    private void throwTedsException(String message) {
        throw new IRR_SVC_TedsService.TedsException(message);
    }


    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Initiates Passenger Infos from list of TedsBookings.
     *      - Processes trips in the booking to find the current and next segments (if possible)
     *      - Instantiates a Passenger Info object for each passenger in the booking
     *
     * @param tedsBookings List of bookings to create Passenger Infos for
     * @param flightId Current flight id to find segments for (optional)
     *
     * @return List of Passenger Infos
     */
    private List<IRR_MOD_PassengerInfo> initiatePassengerInfos(List<IRR_MOD_TedsBooking> tedsBookings, String flightId){
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
        for (IRR_MOD_TedsBooking booking : tedsBookings) {
            IRR_MOD_TedsBooking.Segments_Z thisSegment;
            IRR_MOD_TedsBooking.Segments_Z nextSegment;
            for (IRR_MOD_TedsBooking.Trips trip : booking.trips) {
                if (String.isBlank(flightId)) break; //Don't look for segments if there is no current flightId
                for (IRR_MOD_TedsBooking.Segments_Z segment : trip.segments) {
                    if (segment.flight.id == flightId) {
                        thisSegment = segment;
                        continue;
                    }
                    //Discard unconfirmed segments when looking for next segment
                    if (segment.status != IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED) continue;
                    if (thisSegment!=null) {
                        nextSegment = segment;
                        break;
                    }
                }
                if (thisSegment!=null) break;
            }

            for (IRR_MOD_TedsBooking.Passengers passenger : booking.passengers) {
                IRR_MOD_PassengerInfo passengerInfo = createPassengerInfo(booking, passenger, thisSegment,
                        nextSegment);
                passengerInfos.add(passengerInfo);
            }
        }
        return passengerInfos;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates a Segment Info object from TedsBooking segments.
     *
     * @param tripSegment Detailed trip segment booking details
     * @param passengerSegment Passenger specific segment booking details
     *
     * @return Segment Info object
     */
    private IRR_MOD_SegmentInfo createSegmentInfo(IRR_MOD_TedsBooking.Segments_Z tripSegment,
            IRR_MOD_TedsBooking.Segments passengerSegment) {
        IRR_MOD_SegmentInfo segmentInfo = new IRR_MOD_SegmentInfo();
        if (passengerSegment != null && passengerSegment.ticket != null) {
            segmentInfo.ticketNumber = passengerSegment.ticket.number_Z;
        }
        segmentInfo.stationArrival = tripSegment.flight.arrival.station;
        segmentInfo.stationDeparture = tripSegment.flight.departure.station;
        segmentInfo.status = tripSegment.status;
        segmentInfo.statusCode = tripSegment.statusCode;
        segmentInfo.flightId = tripSegment.flight.id;
        segmentInfo.bookingClass = tripSegment.bookingClass;
        segmentInfo.serviceClass = tripSegment.serviceClass;

        segmentInfo.isConfirmed = segmentInfo.status == IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED;
        if (String.isNotBlank(segmentInfo.ticketNumber)) {
            segmentInfo.isSASTicket = segmentInfo.ticketNumber.startsWith(IRR_SVC_TedsService.TICKET_IDENTIFIER_SAS);
            segmentInfo.isWideroeTicket = segmentInfo.ticketNumber.startsWith(
                    IRR_SVC_TedsService.TICKET_IDENTIFIER_WIDEROE);
        }
        else {
            segmentInfo.isSASTicket = false;
            segmentInfo.isWideroeTicket = false;
        }
        return segmentInfo;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates a single Passenger Info object.
     *
     * @param booking Teds Booking details
     * @param passenger Passenger specific booking details
     * @param tripThisSegment Current trip segment details
     * @param tripNextSegment Next trip segment details (optional)
     *
     * @return Passenger Info object
     */
    private IRR_MOD_PassengerInfo createPassengerInfo(IRR_MOD_TedsBooking booking, IRR_MOD_TedsBooking.Passengers passenger,
            IRR_MOD_TedsBooking.Segments_Z tripThisSegment, IRR_MOD_TedsBooking.Segments_Z tripNextSegment) {

        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.passengerId = booking.id + passenger.id;
        passengerInfo.bookingReference = booking.reference;
        passengerInfo.codsId = booking.codsId;
        passengerInfo.firstName = passenger.firstName;
        passengerInfo.lastName  = passenger.lastName;
        passengerInfo.lastNameSlashFirstName = (passengerInfo.lastName + '/' + passengerInfo.firstName).toUpperCase();

        if (passenger.frequentTraveler != null && passenger.frequentTraveler.euroBonus != null &&
                !passenger.frequentTraveler.euroBonus.isEmpty()) {
            passengerInfo.ebLevel = passenger.frequentTraveler.euroBonus[0].tier;
        }

        if (passenger.frequentTraveler != null && passenger.frequentTraveler.other != null) {
            passengerInfo.otherFQTVCarrier = '';
            for (IRR_MOD_TedsBooking.Other otherFQTV : passenger.frequentTraveler.other) {
                if (String.isNotBlank(passengerInfo.otherFQTVCarrier)) passengerInfo.otherFQTVCarrier += '; ';
                passengerInfo.otherFQTVCarrier += otherFQTV.carrier;
            }
        }


        if (passenger.specialServiceRequests != null) {
            passengerInfo.SSR = '';
            for (IRR_MOD_TedsBooking.SpecialServiceRequests request : passenger.specialServiceRequests) {
                if (String.isNotBlank(passengerInfo.SSR)) passengerInfo.SSR += '; ';
                passengerInfo.SSR += request.code;
            }
        }

        String phoneAP;
        String phoneCTC;
        for (IRR_MOD_TedsBooking.Phone phone  : passenger.contact.phone) {
            if (String.isBlank(phone.type_Z)) continue;
            if (phone.type_Z.startsWith('CTC')) {
                phoneCTC = phone.number_Z;
            }
            else if (phone.type_Z.startsWith('AP')) {
                phoneAP = phone.number_Z;
            }
        }
        passengerInfo.phoneNumber = String.isNotBlank(phoneCTC) ? phoneCTC : phoneAP;

        String emailAP;
        String emailCTC;
        for (IRR_MOD_TedsBooking.Email email : passenger.contact.email) {
            if (String.isBlank(email.type_Z)) continue;
            if (email.type_Z.startsWith('CTC')) {
                emailCTC = email.address;
            }
            else if (email.type_Z.startsWith('AP')) {
                emailAP = email.address;
            }
        }
        passengerInfo.emailAddress = String.isNotBlank(emailCTC) ? emailCTC : emailAP;

        if (tripThisSegment != null) {
            IRR_MOD_TedsBooking.Segments passengerThisSegment;
            IRR_MOD_TedsBooking.Segments passengerNextSegment;

            for (IRR_MOD_TedsBooking.Segments segment : passenger.segments) {
                if (segment.segmentId == tripThisSegment.id) passengerThisSegment = segment;
                if (tripNextSegment != null && segment.segmentId == tripNextSegment.id) passengerNextSegment = segment;
            }

            passengerInfo.thisSegment = createSegmentInfo(tripThisSegment, passengerThisSegment);

            if (tripNextSegment!=null && passengerNextSegment!=null) {
                passengerInfo.nextSegment = createSegmentInfo(tripNextSegment, passengerNextSegment);
            }
        }

        passengerInfo.hasThisSegment = passengerInfo.thisSegment != null;
        passengerInfo.hasPhoneNumber = String.isNotBlank(passengerInfo.phoneNumber);
        passengerInfo.hasEmailAddress = String.isNotBlank(passengerInfo.emailAddress);
        passengerInfo.hasNextSegment = passengerInfo.nextSegment != null;
        return passengerInfo;
    }
}