/**
 * @author Anton Norell
 * @date 2019-11-30
 * @description This class contains tools for parsing a query for an external object and performing operations
 * connected to the query, e.g. retrieving filter values or applying filters in query on a list of data rows
 * from an external system.
 * The class needs to be instantiated and can be used for any external object.
 */
public with sharing class ExternalObjectQueryHandler {
    /**
     * TableSelection variable for QueryContext supplied in constructor. Filter and Order variables
     * used in this class are references through the this variable.
     */
    private DataSource.TableSelection tableSelection;

    /**
    * Holds extracted, valid API search terms from a query when is is iterated. Only used within the class.
    */
    private Map<String, Set<Object>> validApiSearchTermsAndValues;

    /**
     * Constructor for class. Extracts values from the QueryContext needed by methods in the class to class variables.
     * @param queryContext QueryContext object for the query for an external object.
     */
    public ExternalObjectQueryHandler(DataSource.QueryContext queryContext) {
        tableSelection = queryContext.tableSelection;
    }

    /**
     * Used to filter supplied rows based on the query supplied for class instance.
     * @param rows List of rows to be filtered.
     * @return List of filtered rows.
     */
    public List<Map<String, Object>> filterRows(List<Map<String, Object>> rows){
        List<Map<String, Object>> validRows = new List<Map<String, Object>>();
        for (Map<String, Object> row : rows) {
            QueryRowHandler queryIterator = new QueryRowHandler(row);
            Boolean filterResult = queryIterator.filterRow(tableSelection.filter);
            if(filterResult) validRows.add(row);
        }
        return validRows;
    }

    /**
     * Used to order supplied rows based on the query supplied for class instance.
     * @param rows List of rows to be ordered.
     * @return Ordered list with rows.
     */
    public List<Map<String, Object>> orderRows(List<Map<String, Object>> rows){
        //TODO Implement order functionality for rows
        return rows;
    }

    /**
     * Used to retrieve terms and values to use in API call from query based on a supplied set of valid terms.
     * This method is exposed externally and calls an internal method to iterate over query filter.
     * @param validApiSearchTerms Set of valid search terms for the integration used to retrieve data.
     * @return Map with valid search terms as key and set of values to search for as value
     */
    public Map<String, Set<Object>> getApiSearchTermsAndValues(Set<String> validApiSearchTerms){
        validApiSearchTermsAndValues = new Map<String, Set<Object>>();
        extractValidApiSearchTermsAndValues(tableSelection.filter, validApiSearchTerms);
        return this.validApiSearchTermsAndValues;
    }

    /**
     * Internal method used to iterate over a query filter and extract terms and values that can be used to search
     * for data in an external system. The method runs recursively for each sub filter in the query.
     * The extracted terms and values are stored in a class variable during execution.
     * @param filter Filter to iterate over and extract terms
     * @param validApiSearchTerms Set of valid search terms to
     */
    @TestVisible
    private void extractValidApiSearchTermsAndValues(DataSource.Filter filter, Set<String> validApiSearchTerms){
        if(filter.subfilters != null){
            for(DataSource.Filter subFilter:filter.subfilters){
                extractValidApiSearchTermsAndValues(subFilter, validApiSearchTerms);
            }
        } else {
            if(validApiSearchTerms.contains(filter.columnName)){
                if(validApiSearchTermsAndValues.get(filter.columnName) == null){
                    validApiSearchTermsAndValues.put(filter.columnName, new Set<Object>{filter.columnValue});
                } else{
                    validApiSearchTermsAndValues.get(filter.columnName).add(filter.columnValue);
                }
            }
        }
    }

    /**
     * @author Anton Norell
     * @date 2019-11-30
     * @description Internal class used to handle operations connected to an individual row
     * returned after an outbound call to an external system
     */
    @TestVisible
    private class QueryRowHandler {
        /**
         * Individual row to iterate. Supplied in constructor.
         */
        private Map<String, Object> row;

        /**
         * Constructor for class
         * @param row Individual row to iterate
         */
        public QueryRowHandler(Map<String, Object> row) {
            this.row = row;
        }

        /**
         * Used to apply a filter from a query on an individual data row returned from an external system.
         * The method runs recursively for all sub filters in query
         * @param filter
         * @return
         */
        @TestVisible
        private Boolean filterRow(DataSource.Filter filter) {
            Boolean rowValid = false;
            Integer filtersTrue = 0;
            Integer numberOfSubFilters = filter.subfilters != null ? filter.subfilters.size() : 0;
            if (filter.subfilters != null) {
                for (DataSource.Filter subFilter : filter.subfilters) {
                    if (filterRow(subFilter) == true) filtersTrue++;
                }
            } else {
                if (evaluateFilter(filter)) filtersTrue++;
            }
            if (filter.type == DataSource.FilterType.AND_) {
                if (filtersTrue == numberOfSubFilters) {
                    rowValid = true;
                }
            } else if (filtersTrue >= 1) {
                rowValid = true;
            }
            return rowValid;
        }

        /**
         * Helper method used to evaluate an individual filter for a row during execution.
         * The method contains comparisons for expression supported in a query for external objects.
         * @param filter
         * @return
         */
        private Boolean evaluateFilter(DataSource.Filter filter) {
            Boolean filterResult = false;
            Object filterValue = filter.columnValue;
            Object actualValue = row.get(filter.columnName);

            if (filter.type == DataSource.FilterType.EQUALS) {
                if (filterValue == actualValue) filterResult = true;
            } else if (filter.type == DataSource.FilterType.NOT_EQUALS) {
                if (filterValue != actualValue) filterResult = true;
            } else if (filter.type == DataSource.FilterType.LIKE_) {
                throw new CSharkIntegrationService.CSharkIntegrationException('LIKE is not a valid expression for this object');
            } else if (filter.type == DataSource.FilterType.GREATER_THAN) {
                if (Integer.valueOf(filterValue) < Integer.valueOf(actualValue)) filterResult = true;
            } else if (filter.type == DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO) {
                if (Integer.valueOf(filterValue) <= Integer.valueOf(actualValue)) filterResult = true;
            } else if (filter.type == DataSource.FilterType.LESS_THAN) {
                if (Integer.valueOf(filterValue) > Integer.valueOf(actualValue)) filterResult = true;
            } else if (filter.type == DataSource.FilterType.LESS_THAN_OR_EQUAL_TO) {
                if (Integer.valueOf(filterValue) >= Integer.valueOf(actualValue)) filterResult = true;
            }
            return filterResult;
        }
    }
}