/**
 * @author Anton Norell
 * @date 2019-12-01
 * @description Test class for ExternalObjectQueryHandler. Functionality in class is tested separately
 * from any service using the handler.
 */
@IsTest
public with sharing class ExternalObjectQueryHandler_Test {
    /**
     * Asserts that a query with a simple EQUALS condition filters correctly
     */
    @IsTest
    static void shouldFilterSimpleQueryEqualsConditionCorrectly(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Column1';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.EQUALS;

        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 100};
        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(true, iterationResult, 'The query filter did not handle EQUALS condition correctly');
    }

    /**
     * Asserts that a query with a simple NOT_EQUALS condition filters correctly
     */
    @IsTest
    static void shouldFilterSimpleQueryNotEqualsConditionCorrectly(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Column1';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.NOT_EQUALS;
        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 50};

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(true, iterationResult, 'The query filter did not handle NOT_EQUALS condition correctly');
    }

    /**
     * Asserts that a query with a simple GREATER_THAN condition filters correctly
     */
    @IsTest
    static void shouldFilterSimpleQueryGreaterThanConditionCorrectly(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Column1';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.GREATER_THAN;
        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 200};

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(true, iterationResult, 'The query filter did not handle GREATER_THAN condition correctly');
    }

    /**
     * Asserts that a query with a simple GREATER_THAN_OR_EQUAL_TO condition filters correctly
     */
    @IsTest
    static void shouldFilterSimpleQueryGreaterThanOrEqualsConditionCorrectly(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Column1';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.GREATER_THAN_OR_EQUAL_TO;
        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 100};

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);
        System.assertEquals(true, iterationResult, 'The query filter did not handle GREATER_THAN_OR_EQUAL_TO condition correctly');
    }

    /**
     * Asserts that a query with a simple LESS_THAN condition filters correctly
     */
    @IsTest
    static void shouldFilterSimpleQueryLessThanConditionCorrectly(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Column1';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.LESS_THAN;
        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 50};

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(true, iterationResult, 'The query filter did not handle LESS_THAN condition correctly');
    }

    /**
     * Asserts that a query with a simple LESS_THAN_OR_EQUAL_TO condition filters correctly
     */
    @IsTest
    static void shouldFilterSimpleQueryLessThanOrEqualsConditionCorrectly(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Column1';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.LESS_THAN_OR_EQUAL_TO;
        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 50};

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(true, iterationResult, 'The query filter did not handle LESS_THAN_OR_EQUAL_TO condition correctly');
    }

    /**
     * Asserts that a query with a simple LIKE_ condition throws an exception,
     * as the condition is not supported in the query handler
     */
    @IsTest
    static void shouldThrowExceptionOnLikeCondition(){
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnValue = 'stringValue';
        filter.columnValue = 100;
        filter.type = DataSource.FilterType.LIKE_;
        Map<String, Object> dataRow = new Map<String, Object>{'Column1' => 'stringValue'};

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        CSharkIntegrationService.CSharkIntegrationException returnedException;
        try{
            Boolean iterationResult = queryIterator.filterRow(filter);
        } catch(CSharkIntegrationService.CSharkIntegrationException e){
            returnedException = e;
        }

        System.assertNotEquals(null,
                returnedException,
                'The query filter did not handle LIKE_ condition correctly - should throw an exception');
        System.assertEquals('LIKE is not a valid expression for this object',
                returnedException.getMessage(),
                'The query filter did not handle LIKE_ condition correctly - the error message is not correct'
        );
    }

    /**
     * Asserts that a complex query with multiple filters and sub filters returns 
     * false when the conditions does not match the values in the data row
     */
    @IsTest
    static void shouldReturnFalseForComplexFilter(){
        DataSource.Filter filter = C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null);
        filter.subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub1_1', 'value1_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.NOT_EQUALS, 'sub1_2', 'value1_2'),
                C_TestUtil.generateFilter(DataSource.FilterType.GREATER_THAN, 'sub1_3', 3),
                C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
        };
        filter.subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub2_1', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub2_2', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub2_2', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
        };
        filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub3_1', 'value3_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub3_2', 'value3_1')
        };
        Map<String, Object> dataRow = new Map<String, Object>{
                'sub1_1' => 'value1_1',
                'sub1_2' => 'value1_2',
                'sub1_3' => 5,
                'sub2_1' => 'value2_1',
                'sub2_2' => 'value2_1',
                'sub3_1' => 'value3_1',
                'sub3_2' => 'value3_1'
        };

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(false, iterationResult, 'Result from query was incorrect. The values in data row should not match filter.');
    }

    /**
     * Asserts that a complex query with multiple filters and sub filters returns
     * true when the conditions matches the values in the data row
     */
    @IsTest
    static void shouldReturnTrueForComplexFilter(){
        DataSource.Filter filter = C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null);
        filter.subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub1_1', 'value1_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.NOT_EQUALS, 'sub1_2', 'value1_2'),
                C_TestUtil.generateFilter(DataSource.FilterType.GREATER_THAN, 'sub1_3', 3),
                C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
        };
        filter.subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub2_1', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub2_2', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub2_2', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
        };
        filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub3_1', 'value3_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'sub3_2', 'value3_1')
        };
        Map<String, Object> dataRow = new Map<String, Object>{
                'sub1_1' => 'value1_1',
                'sub1_2' => 'value1_2_deviating_value',
                'sub1_3' => 5,
                'sub2_1' => 'value2_1',
                'sub2_2' => 'value2_1',
                'sub3_1' => 'value3_1',
                'sub3_2' => 'value3_1'
        };

        ExternalObjectQueryHandler.QueryRowHandler queryIterator = new ExternalObjectQueryHandler.QueryRowHandler(dataRow);
        Boolean iterationResult = queryIterator.filterRow(filter);

        System.assertEquals(true, iterationResult, 'Result from query was incorrect. The values in data row should match filter.');
    }

    /**
     * Asserts that the correct terms available for searching an api is returned when method for extracting api search
      * terms run. This test focuses on the extracted search terms in relation to supplied valid search terms.
     */
    @IsTest
    static void shouldReturnCorrectValidSearchTermsFromQueryFilter(){
        DataSource.QueryContext queryContext = new DataSource.QueryContext();
        queryContext.tableSelection = new DataSource.TableSelection();
        Set<String> validApiSearchTerms = new Set<String>{
                'Term1',
                'Term2',
                'Term3',
                'Term4'
        };
        DataSource.Filter filter = C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null);
        filter.subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term3', 'value1_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.NOT_EQUALS, 'OtherTerm', 'value1_2'),
                C_TestUtil.generateFilter(DataSource.FilterType.GREATER_THAN, 'OtherTerm', 3),
                C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
        };
        filter.subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term1', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'OtherTerm', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term1', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
        };
        filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term4', 'value3_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term2', 'value3_1')
        };
        queryContext.tableSelection.filter = filter;

        ExternalObjectQueryHandler queryParser = new ExternalObjectQueryHandler(queryContext);
        Map<String, Object> filterSearchTerms = queryParser.getApiSearchTermsAndValues(validApiSearchTerms);

        System.assertEquals(
                4,
                filterSearchTerms.keySet().size(),
                'Search terms found was not the expected number'
        );
        System.assertEquals(
                true,
                validApiSearchTerms.containsAll(filterSearchTerms.keySet()),
                'Found search terms in filter that are not listed as valid search terms. Check filtering of search terms.'
        );
        System.assertEquals(
                validApiSearchTerms,
                filterSearchTerms.keySet(),
                'The search terms found did not match the order of terms in set with valid search terms');
    }

    /**
     * Asserts that the correct terms and search values for searching an api are returned when method for extracting
     * api search terms run. This test focuses on the extracted search values for each search term.
     */
    @IsTest
    static void shouldReturnCorrectValidSearchTermsAndValuesFromQueryFilter(){
        Set<String> validApiSearchTerms = new Set<String>{
                'Term1',
                'Term2',
                'Term3',
                'Term4'
        };

        DataSource.Filter filter = C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null);
        filter.subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term3', 'value1_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.NOT_EQUALS, 'OtherTerm', 'value1_2'),
                C_TestUtil.generateFilter(DataSource.FilterType.GREATER_THAN, 'Term4', 'value1_3'),
                C_TestUtil.generateFilter(DataSource.FilterType.OR_, null, null)
        };
        filter.subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term1', 'value2_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term3', 'value2_2'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term1', 'value2_3'),
                C_TestUtil.generateFilter(DataSource.FilterType.AND_, null, null)
        };
        filter.subfilters[3].subfilters[3].subfilters = new List<DataSource.Filter>{
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term4', 'value3_1'),
                C_TestUtil.generateFilter(DataSource.FilterType.EQUALS, 'Term2', 'value3_2')
        };
        DataSource.QueryContext queryContext = new DataSource.QueryContext();
        queryContext.tableSelection = new DataSource.TableSelection();
        queryContext.tableSelection.filter = filter;

        ExternalObjectQueryHandler queryParser = new ExternalObjectQueryHandler(queryContext);
        Map<String, Set<Object>> filterSearchTerms = queryParser.getApiSearchTermsAndValues(validApiSearchTerms);

        System.assertEquals(
                4,
                filterSearchTerms.keySet().size(),
                'Search terms found was not the expected number'
        );
        System.assertEquals(2, filterSearchTerms.get('Term1').size());
        System.assertEquals(1, filterSearchTerms.get('Term2').size());
        System.assertEquals(2, filterSearchTerms.get('Term3').size());
        System.assertEquals(2, filterSearchTerms.get('Term4').size());
    }

    /**
     * Asserts that if the filter is supplied with multiple rows and only a subset matches the filter,
     * only that subset of rows is returned
     */
    @IsTest
    static void shouldReturnSubsetOfRowsThatMatchedFilter(){
        DataSource.QueryContext queryContext= new DataSource.QueryContext();
        queryContext.tableSelection = new DataSource.TableSelection();
        queryContext.tableSelection.filter = new DataSource.Filter();
        queryContext.tableSelection.filter.columnName = 'Column1';
        queryContext.tableSelection.filter.columnValue = 100;
        queryContext.tableSelection.filter.type = DataSource.FilterType.EQUALS;
        Map<String, Object> rowMatchingFilter = new Map<String, Object>{'Column1' => 100};
        Map<String, Object> rowNotMatchingFilter = new Map<String, Object>{'Column1' => 0};
        List<Map<String, Object>> dataRows = new List<Map<String, Object>>{rowMatchingFilter, rowNotMatchingFilter};

        ExternalObjectQueryHandler queryHandler = new ExternalObjectQueryHandler(queryContext);
        List<Map<String, Object>> validRows = queryHandler.filterRows(dataRows);

        System.assertEquals(1, validRows.size(), 'The filter returned an unexpected number of rows.');
        System.assertEquals(rowMatchingFilter, validRows[0], 'The returned row was not the correct one.');
    }

    @IsTest
    static void shouldReturnOrderRowsBasedOnQuery(){
        //TODO Implement test method
    }
}