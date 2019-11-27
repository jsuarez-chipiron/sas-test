/**
 * @author Anton Norell
 * @date 2019-11-25
 * @description Service class for integrations calling external system C-Shark. Exposes available operations through
 *              public methods corresponding to the operation name.
 */
public with sharing class CSharkIntegrationService {
    /**
     * Supported operation names for C-Shark services
     */
    public enum OperationName {CustomerGet, CustomersGet}

    /**
     * Supported parameters to base search for customer on
     */
    public enum SearchType {EuroBonus, Identifier, UserName, TPAccount, Email, PhoneNumber, LastName}

    //TODO Extend class with method for C-Shark service CustomersGet. Wrap CustomerGet and CustomersGet in method
    // and determine which method to call based on provided SearchType

    /**
     * Entry point to use CustomerGet operation in C-Shark. Customer data is returned based on the search parameters.
     * @param searchEngagementType Type of identifier for customer. Selected from enums in class
     * @param engagementSearchKey Value to search for, based on search type, e.g. a EuroBonus number
     * @return Custom class containing an error message or the customer data result
     */
    public static CSharkResponse getCustomer(SearchType searchEngagementType, String engagementSearchKey){
        C_Log.HttpData httpDataLog = new C_Log.HttpData();
        CSharkResponse cSharkResponse = new CSharkResponse();
        try{
            Http http = new Http();
            HttpRequest request = createAPIMRequest(OperationName.CustomerGet);
            request.setBody(generateCustomerGetBody(searchEngagementType, engagementSearchKey));

            httpDataLog = createHttpDataLog(request);

            HttpResponse response = http.send(request);

            if(response.getStatusCode() == 200){
                CSharkResponseParser parser = new CSharkResponseParser(response.getBody());
                parser.parseCustomerGetResponse();
                if(parser.errorMessage == null){
                    cSharkResponse.dataRows = parser.dataRows;
                } else{
                    cSharkResponse.errorMessage = parser.errorMessage;
                    C_Log.log(C_Log.Severity.Error, cSharkResponse.errorMessage, null, 'APIM', httpDataLog);
                }
            } else {
                cSharkResponse.errorMessage = 'An error occurred during callout: ' + response.getStatusCode() + ', ' + response.getStatus();
                C_Log.log(C_Log.Severity.Error, cSharkResponse.errorMessage, null, 'APIM', httpDataLog);
            }
        } catch(Exception e){
            C_Log.logException(e, 'APIM', httpDataLog);
            cSharkResponse.errorMessage = 'An exception occurred. See log for details. ' + e.getMessage();
        }
        return cSharkResponse;
    }

    /**
     * Used to create a HttpData object to attach to C_Log class. The parameters are specific to the APIM/CShark service.
     * @param request Http request to base log data on
     * @return HttpData record that can be attached to C_Log class
     */
    private static C_Log.HttpData createHttpDataLog(HttpRequest request){
        C_Log.HttpData httpDataLog = new C_Log.HttpData();
        httpDataLog.resource = request.getEndpoint();
        httpDataLog.remoteAddress = request.getEndpoint();
        httpDataLog.headers = request.getHeader('Content-Type') +
                                                ', ' +
                                                request.getHeader('Ocp-Apim-Subscription-Key');
        httpDataLog.method = request.getMethod();
        httpDataLog.body = request.getBody();
        return httpDataLog;
    }

    private static HttpRequest createAPIMRequest(OperationName operationName){
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SAS_APIM/csharkcustmgmtticketless');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml');
        request.setHeader('SOAPAction',
                        '"http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1/ICSharkCustomerManagementTicketless/' +
                                String.valueOf(operationName) + '"');
        request.setHeader('Ocp-Apim-Subscription-Key', '09f8570b366b4c1392c170ff77356140');
        request.setHeader('sas-system-name', 'Salesforce');
        request.setHeader('sas-tracking-id', C_Util.getUUID());
        return request;
    }

/*
    private static String generateCustomersGetBody(SearchType searchEngagementType, String engagementSearchKey){
        String requestBody = '<?xml version="1.0" encoding="utf-8"?>' +
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<Body>' +
                '<CustomerGet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
                '<SearchType>' + searchEngagementType +'</SearchType>' +
                '<SearchKey>' + engagementSearchKey +'</SearchKey>' +
                '<FirstName>' + '' +'</FirstName>' +
                '</CustomerGet>' +
                '</Body>' +
                '</Envelope>';
        return requestBody;
    }
*/
    private static String generateCustomerGetBody(SearchType searchEngagementType, String engagementSearchKey){
        String requestBody = '<?xml version="1.0" encoding="utf-8"?>' +
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<Body>' +
                '<CustomerGet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
                '<searchEngagementType>' + searchEngagementType +'</searchEngagementType>' +
                '<engagementSearchKey>' + engagementSearchKey +'</engagementSearchKey>' +
                '</CustomerGet>' +
                '</Body>' +
                '</Envelope>';
        return requestBody;
    }

    /**
     * Class used by this service to transmit a result from C-Shark together with a potential error message.
     * If operation is successful, this object is returns with data. If not, it returns with an error message and
     * an empty result.
     */
    public class CSharkResponse{
        public List<Map<String,Object>> dataRows;
        public String errorMessage;

        public CSharkResponse(){
            dataRows = new List<Map<String, Object>>();
        }
    }

    /**
     * Customer exception class for C-Shark integration
     */
    public with sharing class CSharkIntegrationException extends Exception{}
}