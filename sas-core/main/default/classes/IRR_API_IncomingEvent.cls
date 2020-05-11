/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event API endpoint class for incoming events.
*/

@RestResource(UrlMapping='/EventAPI/*')
global class IRR_API_IncomingEvent {

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Handle incoming Event POST and call EventService to process event.
     *      - Event type is parsed from the request URI
     *      - Request body is used as event payload
     */
    @HttpPost
    global static void handleIncomingEvent() {
        try {
            RestRequest req = RestContext.request;
            String eventType = req.requestURI.substringAfterLast('/');
            String eventPayload = req.requestBody.toString();
            IRR_SVC_CommunicationService.processEvent(eventType, eventPayload);
        }
        catch (Exception e) {
            C_Log.logException(e, 'IRR', C_Log.generateLogHttpData(RestContext.request));
            RestContext.response = new RestResponse();
            RestContext.response.responseBody = Blob.valueOf(e.getMessage());
            RestContext.response.statusCode = 500;
        }
    }
}