/**
 * @author Anton Norell
 * @date 2019-11-28
 * @description Service class for logic related to external object Frequent Flyer.
 */
public with sharing class FrequentFlyerService {
    /**
     * Used to handle a query for Frequent Flyer object. Extracts terms to search for in external system,
     * filters result based on additional filters, orders rows and returns a table with the result.
     * Returns mock data if feature is turned on.
     * @param queryContext QueryContext object for query
     * @return Result table for query
     */
    public static DataSource.TableResult handleQuery(DataSource.QueryContext queryContext){
        validateQueryFilter(queryContext);
        ExternalObjectQueryHandler queryHandler = new ExternalObjectQueryHandler(queryContext);
        Map<String, Set<Object>> validApiSearchTermsAndValues = queryHandler.getApiSearchTermsAndValues(
                CSharkIntegrationService.validApiSearchFieldNames
        );
        String selectedSearchTerm = getSelectedSearchTerm(validApiSearchTermsAndValues);
        Object selectedSearchValue = getSelectedSearchValue(selectedSearchTerm, validApiSearchTermsAndValues);

        List<Map<String, Object>> customerRows = getCustomerRows(getSelectedSearchType(selectedSearchTerm), selectedSearchValue);
        List<Map<String, Object>> processedRows = queryHandler.orderRows(queryHandler.filterRows(customerRows));
        DataSource.TableResult tableResult = Datasource.TableResult.get(queryContext.tableSelection, processedRows);
        return tableResult;
    }

    /**
     * Used to create an account based on a Frequent Flyer record.
     * @param frequentFlyers List of Frequent Flyer record to generate accounts for
     * @return List of account generated
     */
    public static List<Account> syncFrequentFlyersToAccounts(List<FrequentFlyer__x> frequentFlyers){
        List<Account> accounts = new List<Account>();
        //TODO Implement creation of Account record based on table result
        return accounts;
    }

    /**
     * Used to retrieve customer rows based on supplied search variables. Checks if mock
     * data should be returned or if callout to external system should be performed.
     * @param selectedSearchType The selected type of search
     * @param selectedSearchValue The selected value to search for
     * @return Customer rows retrieved either from mock data generator or external system
     */
    private static List<Map<String, Object>> getCustomerRows(CSharkIntegrationService.SearchType selectedSearchType, Object selectedSearchValue) {
        List<Map<String, Object>> customerRows;
        if (!checkIfMockData()) {
            customerRows = CSharkIntegrationService.getCustomer(selectedSearchType, selectedSearchValue);
        } else {
            customerRows = CSharkIntegrationService.getMockRows(selectedSearchType, selectedSearchValue);
        }
        return customerRows;
    }

    /**
     * Used to extract an calculate the search type that should be used for the query, based on the provided search term.
     * @param selectedSearchTerm Search term in string format from query.
     * @return Search type from C-Shark service
     */
    private static CSharkIntegrationService.SearchType getSelectedSearchType(String selectedSearchTerm) {
        CSharkIntegrationService.SearchType selectedSearchType = CSharkIntegrationService.getSearchTypeByFieldName(selectedSearchTerm);
        if (selectedSearchType == null) {
            throw new CSharkIntegrationService.CSharkIntegrationException(
                    'The provided API search type does not match enum of valid search types.'
            );
        }
        return selectedSearchType;
    }

    /**
     * Used to extract and calculate the search value to use, e.g. a EuroBonus number, from the query.
     * If multiple search values are provided for a single search term, e.g. multiple EuroBonus numbers,
     * an exception is thrown.
     * @param searchTerm Search term, i.e. the type of value to search for
     * @param validApiSearchTermsAndValues Set of valid search terms
     * @return A single search value, e.g. a EuroBonus number or an email address
     */
    private static Object getSelectedSearchValue(String searchTerm, Map<String, Set<Object>> validApiSearchTermsAndValues) {
        List<Object> searchValues = new List<Object>();
        searchValues.addAll(validApiSearchTermsAndValues.get(searchTerm));
        if (searchValues.size() > 1) {
            throw new CSharkIntegrationService.CSharkIntegrationException(
                    'Only one search value per field ' + searchTerm + ' can be included in the query for this service'
            );
        }
        return searchValues[0];
    }

    /**
     * Used to validate that the incoming query has a valid filter.
     * @param queryContext QueryContext object from query
     */
    private static void validateQueryFilter(DataSource.QueryContext queryContext) {
        if (queryContext.tableSelection.filter == null) {
            throw new CSharkIntegrationService.CSharkIntegrationException('The query must include a valid search term for the C-Shark API');
        }
    }

    /**
     * Used to extract and calculate the search term to use. As search terms should
     * be ordered by priority, the first term in the set is selected.
     * @param searchTerms List of search terms from query
     * @return The selected search term to use
     */
    private static String getSelectedSearchTerm(Map<String, Set<Object>> validApiSearchTermsAndValues){
        if (validApiSearchTermsAndValues.size() == 0) {
            throw new CSharkIntegrationService.CSharkIntegrationException(
                    'The query must include a valid search term for the C-Shark API'
            );
        }
        List<String> searchTermsList = new List<String>();
        searchTermsList.addAll(validApiSearchTermsAndValues.keySet());
        return searchTermsList[0];
    }

    /**
     * Checks if Feature Switch for using mock data is active in org
     * @return True or false for if switch for mock data is active or not
     */
    private static Boolean checkIfMockData() {
        Boolean mockData = false;
        //If feature switch for mock data is enabled, return mock data. Otherwise, evaluate request.
        if ([SELECT Id, Active__c FROM Feature_Switch__mdt WHERE DeveloperName = 'Mock_Frequent_Flyer_Data'].Active__c) {
            mockData = true;
        }
        return mockData;
    }
}