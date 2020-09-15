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
    private static final String AIRPORTCODE_ENDPOINT_TEMPLATE = '/teds-airport/airports?ids=';

    private static final String INTEGRATION_ERROR_TEMPLATE = 'Integration Response: {0} - {1}';

    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .setAPIVersion(API_VERSION)
                                .setAPIMSubscriptionKey(APIM_SUBSCRIPTION_KEY)
                                .enableSASTracking()
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
            throwTedsException(responseObject);
        }
        IRR_MOD_TedsBooking parsedResponse = IRR_MOD_TedsBooking.parse(responseObject.responseBody);
        return parsedResponse;
    }
    /**
     * @author Chetan Singh, Coforgetech
     * @date 2020
     *
     * @description Retrieves Airport Information from Teds.
     *
     * @param iataCodes airport codes received in the event info
     *
     * @return Retrieved Airport Details
     */
    public Map<String,String> getAirportCityNames(String [] iataCodes) {
        String endpointURL = AIRPORTCODE_ENDPOINT_TEMPLATE + String.join(iataCodes,',');
        C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor
                .executeRequest(endpointURL, C_IntegrationExecutor.Method.GET, null, null);
                if (responseObject.statusCode >= 300 || responseObject.statusCode<200) {
            throwTedsException(responseObject);
        }
        List<IRR_MOD_AirportInfo> airportNames = IRR_MOD_AirportInfo.parseArray(responseObject.responseBody);
        Map<String,String> airportInfoMap = new Map<String, String>();
        for(IRR_MOD_AirportInfo apInfo : airportNames){
            airportInfoMap.put(apInfo.id,apInfo.city);
        }
        return airportInfoMap;
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
            throwTedsException(responseObject);
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

    private void throwTedsException(C_IntegrationExecutor.IntegrationResponse response) {
        throw new IRR_SVC_TedsService.TedsException(String.format(INTEGRATION_ERROR_TEMPLATE, new List<String>{
                String.valueOf(response.statusCode), response.responseBody}));
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
            IRR_MOD_TedsBooking.SegmentTrip thisSegment;
            IRR_MOD_TedsBooking.SegmentTrip nextSegment;
            List<IRR_MOD_TripInfo> itinerary = new List<IRR_MOD_TripInfo>();
            for (IRR_MOD_TedsBooking.Trip trip : booking.trips) {
                //Only process current and next segments when they have not been found and flightId is available
                if (String.isNotBlank(flightId) && thisSegment == null) {
                    for (IRR_MOD_TedsBooking.SegmentTrip segment : trip.segments) {
                        if (segment.flight.operatingId == flightId || segment.flight.id == flightId) {
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
                }
                //Process Itinerary
                List<IRR_MOD_SegmentInfo> tripSegments = new List<IRR_MOD_SegmentInfo>();
                for (IRR_MOD_TedsBooking.SegmentTrip segment : trip.segments) {
                    //Discard unconfirmed segments when constructing itinerary
                    if (segment.status != IRR_SVC_TedsService.BOOKING_STATUS_CONFIRMED) continue;
                    tripSegments.add(createSegmentInfo(segment, null));
                }
                if (!tripSegments.isEmpty()) itinerary.add(createTripInfo(trip, tripSegments));
            }

            for (IRR_MOD_TedsBooking.Passenger passenger : booking.passengers) {
                IRR_MOD_PassengerInfo passengerInfo = createPassengerInfo(booking, passenger, thisSegment,
                        nextSegment, itinerary);
                passengerInfos.add(passengerInfo);
            }
        }
        return passengerInfos;
    }

    private IRR_MOD_TripInfo createTripInfo(IRR_MOD_TedsBooking.Trip trip, List<IRR_MOD_SegmentInfo> segments) {
        IRR_MOD_TripInfo tripInfo = new IRR_MOD_TripInfo();
        tripInfo.segments = segments;
        tripInfo.tripType = trip.type;
        return tripInfo;
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
    private IRR_MOD_SegmentInfo createSegmentInfo(IRR_MOD_TedsBooking.SegmentTrip tripSegment,
            IRR_MOD_TedsBooking.Segment passengerSegment) {
        IRR_MOD_SegmentInfo segmentInfo = new IRR_MOD_SegmentInfo();
        if (passengerSegment != null && passengerSegment.ticket != null) {
            segmentInfo.ticketNumber = passengerSegment.ticket.number_x;
        }
        segmentInfo.segmentId = tripSegment.id;
        segmentInfo.flightId = String.isNotBlank(tripSegment.flight.operatingId) ? tripSegment.flight.operatingId :
                tripSegment.flight.id;
        segmentInfo.flightNumber = segmentInfo.flightId.split('-')[0];
        segmentInfo.arrivalTimeLocal = tripSegment.flight.arrival.scheduledTime.local;
        segmentInfo.departureTimeLocal = tripSegment.flight.departure.scheduledTime.local;
        segmentInfo.stationArrival = tripSegment.flight.arrival.station;
        segmentInfo.stationDeparture = tripSegment.flight.departure.station;
        segmentInfo.status = tripSegment.status;
        segmentInfo.statusCode = tripSegment.statusCode;
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
     * @param tripThisSegment Current trip segment details (optional)
     * @param tripNextSegment Next trip segment details (optional)
     * @param itinerary Booking Itinerary (optional)
     *
     * @return Passenger Info object
     */
    private IRR_MOD_PassengerInfo createPassengerInfo(IRR_MOD_TedsBooking booking,
            IRR_MOD_TedsBooking.Passenger passenger, IRR_MOD_TedsBooking.SegmentTrip tripThisSegment,
            IRR_MOD_TedsBooking.SegmentTrip tripNextSegment, List<IRR_MOD_TripInfo> itinerary) {

        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.passengerId = booking.id + passenger.id;
        passengerInfo.bookingReference = booking.reference;
        passengerInfo.codsId = booking.codsId;
        passengerInfo.title = passenger.title;
        passengerInfo.firstName = passenger.firstName;
        passengerInfo.lastName  = passenger.lastName;
        passengerInfo.lastNameSlashFirstName = (passengerInfo.lastName + '/' + passengerInfo.firstName).toUpperCase();
        passengerInfo.itinerary = itinerary;

        if (passenger.frequentTraveler != null && passenger.frequentTraveler.euroBonus != null &&
                !passenger.frequentTraveler.euroBonus.isEmpty()) {
            passengerInfo.ebLevel = passenger.frequentTraveler.euroBonus[0].tier;
        }

        if (passenger.frequentTraveler != null && passenger.frequentTraveler.other != null) {
            passengerInfo.otherFQTVCarrier = '';
            for (IRR_MOD_TedsBooking.OtherFQTV otherFQTV : passenger.frequentTraveler.other) {
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
            if (String.isBlank(phone.type)) continue;
            if (phone.type.startsWith('CTC')) {
                phoneCTC = phone.number_x;
            }
            else if (phone.type.startsWith('AP')) {
                phoneAP = phone.number_x;
            }
        }
        passengerInfo.phoneNumber = String.isNotBlank(phoneCTC) ? phoneCTC : phoneAP;

        String emailAP;
        String emailCTC;
        for (IRR_MOD_TedsBooking.Email email : passenger.contact.email) {
            if (String.isBlank(email.type)) continue;
            if (email.type.startsWith('CTC')) {
                emailCTC = email.address;
            }
            else if (email.type.startsWith('AP')) {
                emailAP = email.address;
            }
        }
        passengerInfo.emailAddress = String.isNotBlank(emailCTC) ? emailCTC : emailAP;

        if (tripThisSegment != null) {
            IRR_MOD_TedsBooking.Segment passengerThisSegment;
            IRR_MOD_TedsBooking.Segment passengerNextSegment;

            for (IRR_MOD_TedsBooking.Segment segment : passenger.segments) {
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