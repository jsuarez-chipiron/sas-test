/**
 * @author Anton Norell
 * @date 2019-11-25
 * @description Service class for integrations calling external system C-Shark. Exposes available operations through
 *              public methods corresponding to the operation name.
 */
public with sharing class   CSharkIntegrationService {
    /**
     * Supported operation names for C-Shark services
     */
    public enum OperationName {CustomerGet, CustomersGet}

    /**
     * Sets the name of the system that it saved in logs in APIM and CShark for callouts from this service
     */
    private static final String API_SYSTEM_NAME = 'Salesforce';

    /**
     * Supported parameters to base search for customer on. The format of these search types
     * correspond with valid search terms in the C-Shark service.
     */
    public enum SearchType {
        EB_NUMBER, CODS_ID, TP_ACCOUNT, EMAIL, SITE_MEMBER, SUBSCRIPTION_ID}

    /**
     * Contains the valid fields to search for in the C-Shark API. The values correspond with the field
     * named returned in the service and are used as database named on external objects using the service,
     * e.g. Frequent Flyer. The values are used when translating a query to valid Search Terms for the API.
     */
    public static Set<String> validApiSearchFieldNames = new Set<String>{
            'EuroBonusNumber',
            'TravelPassAccountNumber',
            'ExternalId',
            'HomeEMail'
    };

    /**
     * Used to retrieve a list of customers from C-Shark. Customer data is returned based on the search parameters.
     * Depending on what is search fore, this method might call different underlying method to retrieve data from
     * the C-Shark service.
     * @param searchEngagementType Type of identifier for customer. Selected from enums in class
     * @param engagementSearchKey Value to search for, based on search type, e.g. a EuroBonus number
     * @return Custom class containing an error message or the customer data result
     */
    //TODO Gör om argument från object till string
    public static List<Map<String, Object>> getCustomer(SearchType searchEngagementType, Object engagementSearchKey){
        //TODO Extend class with method for C-Shark service CustomersGet. Wrap CustomerGet and CustomersGet in method
        // and determine which method to call based on provided SearchType

        List<Map<String, Object>> customerRows = new List<Map<String, Object>>();

        Http http = new Http();
        HttpRequest request = createAPIMRequest(OperationName.CustomerGet);
        request.setBody(generateCustomerGetBody(searchEngagementType, engagementSearchKey));

        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200){
            customerRows = CSharkResponseParser.parseCustomerGetResponse(response.getBody());
        } else {
            C_Log.HttpData httpDataLog = C_Log.generateLogHttpData(request);
            httpDataLog.headers = request.getHeader('Content-Type');
            C_Log.log(
                    C_Log.Severity.Error,
                    response.getStatusCode() + response.getStatus() + response.getBody(),
                    null,
                    'APIM',
                    httpDataLog
            );
            throw new CSharkIntegrationException(
                    'C-Shark service responded with an error ' + response.getStatusCode() +'. See log for details.'
            );
        }
        return customerRows;
    }

    /**
     * Creates and returns a Http request with correct values for APIM and CShark
     * @param operationName
     * @return
     */
    private static HttpRequest createAPIMRequest(OperationName operationName){
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SAS_APIM/csharkcustmgmtticketless');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml');
        request.setHeader('SOAPAction',
                '"' + 'http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1/ICSharkCustomerManagementTicketless/' +
                        String.valueOf(operationName) + '"');
        C_GeneralSetting__mdt[] subscriptionKey = [SELECT Id, Value__c FROM C_GeneralSetting__mdt WHERE DeveloperName = 'APIM_Subscription_Key'];
        if(subscriptionKey == null) throw new CSharkIntegrationException('General setting for APIM subscription key missing');
        request.setHeader('Ocp-Apim-Subscription-Key', subscriptionKey[0].Value__c);
        request.setHeader('sas-system-name', API_SYSTEM_NAME);
        request.setHeader('sas-tracking-id', C_Util.getUUID());
        return request;
    }

    /**
     * Generates a request body for operation CustomersGet in C-Shark.
     * @param searchType The type of values to search for, e.g. EuroBonus
     * @param SearchKey The value to search for, e.g. '554422441'
     * @return Request body string in XML-format.
     */
    private static String generateCustomersGetBody(SearchType searchType, Object SearchKey){
        //TODO Create switch statement like in CustomerGet request with valid search terms for this operation
        String requestBody = '<?xml version="1.0" encoding="utf-8"?>' +
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<Body>' +
                '<CustomerGet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
                '<SearchType>' + searchType +'</SearchType>' +
                '<SearchKey>' + SearchKey +'</SearchKey>' +
                '<FirstName>' + '' +'</FirstName>' +
                '</CustomerGet>' +
                '</Body>' +
                '</Envelope>';
        return requestBody;
    }

    /**
     * Generates a request body for operation CustomerGet in C-Shark. The search type is translated
     * to the matching search term for this request.
     * @param searchEngagementType The type of values to search for, e.g. EuroBonus
     * @param engagementSearchKey The value to search for, e.g. '554422441'
     * @return Request body string in XML-format.
     */
    @TestVisible
    private static String generateCustomerGetBody(SearchType searchEngagementType, Object engagementSearchKey){
        String searchTerm;
        switch on searchEngagementType{
            when EB_NUMBER {
                searchTerm = 'EuroBonus';
            }
            when TP_ACCOUNT {
                searchTerm = 'TP';
            }
            when CODS_ID {
                searchTerm = 'Default';
            }
            when EMAIL {
                searchTerm = 'Email';
            }
            when SUBSCRIPTION_ID {
                searchTerm = 'Subscription';
            }
            when SITE_MEMBER {
                searchTerm = 'SiteMember';
            }
        }

        String requestBody =
                '<?xml version="1.0" encoding="utf-8"?>' +
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<Body>' +
                '<CustomerGet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
                '<searchEngagementType>' + searchTerm +'</searchEngagementType>' +
                '<engagementSearchKey>' + engagementSearchKey +'</engagementSearchKey>' +
                '</CustomerGet>' +
                '</Body>' +
                '</Envelope>';
        return requestBody;
    }

    //TODO Remove mock functionality
    /**
     * Customer exception class for C-Shark integration
     */
    public class CSharkIntegrationException extends Exception{}

    /**
     * Helper method used to generate mock data based on a preconfigured response with a certain search criteria
     * @param providedSearchValue EuroBonus number to search for. Only one value will return a result.
     * @return If searchValue matches, a customer data row is returned. If not, the return is empty.
     */
    public static List<Map<String, Object>> getMockRows(SearchType providedSearchType, Object providedSearchValue) {
        List<Map<String, Object>> dataRows = new List<Map<String, Object>>();
        if ((providedSearchType == SearchType.EB_NUMBER && providedSearchValue == '544108996') ||
                providedSearchType == SearchType.CODS_ID && providedSearchValue == '10787700') {
            StaticResource mockResponse = [SELECT Id, Body FROM StaticResource WHERE Name = 'FrequentFlyerMock_544108996'];
            dataRows = CSharkResponseParser.parseCustomerGetResponse(mockResponse.Body.toString());
        }
        return dataRows;
    }

    //TODO FLytta till rätt klass där den kan vara private
    /**
     * Helper method used to get a valid search type from this service
     * based on a provided string, e.g. a field name from a table
     * @param searchField String value to match search type by
     * @return If search type is found, it is returned. Otherwise the return value is null.
     */
    public static SearchType getSearchTypeByFieldName(String searchField){
        SearchType matchedSearchType;
        switch on searchField{
            when 'EuroBonusNumber'{
                matchedSearchType = SearchType.EB_NUMBER;
            }
            when 'TravelPassAccountNumber'{
                matchedSearchType = SearchType.TP_ACCOUNT;
            }
            when 'ExternalId'{
                matchedSearchType = SearchType.CODS_ID;
            }
            when 'HomeEMail'{
                matchedSearchType = SearchType.EMAIL;
            }
            when 'SubscriptionID'{
                matchedSearchType = SearchType.SUBSCRIPTION_ID;
            }
            when 'UserName'{
                matchedSearchType = SearchType.SITE_MEMBER;
            }
        }
        return matchedSearchType;
    }
}