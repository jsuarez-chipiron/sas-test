global with sharing class SASExternalDataSourceConnection extends DataSource.Connection{ 
    global SASExternalDataSourceConnection(DataSource.ConnectionParams connectionParams) {
        
    }  
    
    /**
     * This method sets up a default table that can be synced and validated to automatically create an external object
     * The method is not used as external objects for this connection are created manually
     * @return List of tables that can be synced to create external objects
     */
    override global List<DataSource.Table> sync() {
        List<DataSource.Column> columns = new List<DataSource.Column>();
        columns.add(DataSource.Column.text('ExternalId', 255));
        columns.add(DataSource.Column.url('DisplayUrl'));
        List<DataSource.Table> tables = new List<DataSource.Table>();        
        tables.add(DataSource.Table.get('FrequentFlyers', 'Title', columns));
        return tables;
    }
    
    /**
     * This method is used to handle queries for external objects using this connection. 
     * If new external objects are added, the method should be extended to support those objects as well.
     * @return A table containing data requested in query, or an empty table if no match was found. 
     */
    override global DataSource.TableResult query(DataSource.QueryContext c) {
        System.debug('Table: ' + c.tableSelection.tableSelected);
        System.debug('Columns: ' + c.tableSelection.columnsSelected);
        System.debug('Filter: ' + c.tableSelection.filter);
        System.debug('Order: ' + c.tableSelection.order);


        Boolean mockData = false;

        DataSource.TableResult returnTable;

        //If feature switch for mock data is enabled, return mock data. Otherwise, evaluate request. 
        if([SELECT Id, Active__c FROM Feature_Switch__mdt WHERE DeveloperName = 'Mock_Frequent_Flyer_Data'].Active__c){
            mockData = true;
            System.debug('Running with mock data');
        } 
        
        //Check table for query
        if(c.tableSelection.tableSelected == 'FrequentFlyers'){
            //Get filters for query
            DataSource.Filter filter = c.tableSelection.filter;
            //Throw exception if filter is missing (must supply filter fot API)
            if(c.tableSelection.filter == null && !mockData){
                throw new CSharkIntegrationService.CSharkIntegrationException('The query must be filtered by one of the following values: EBNumber__c, ExternalId');
            }
            else{
                //Check that only one parameter is included in filter
                if(filter.columnName != null){
                    //Throw exception if filter contains unsupporter operators
                    if(filter.type != DataSource.FilterType.EQUALS)
                        throw new CSharkIntegrationService.CSharkIntegrationException('Only filter of typ EQUALS (=) is supported for this object');

                    //Translate fields in filter to fields used as keys in API
                    String searchEngagementType;
                    switch on filter.columnName {
                        when 'euroBonusNumber' {
                            searchEngagementType = 'EuroBonus';
                        }
                        when 'travelPassAccountNumber' {
                            searchEngagementType = 'TP';
                        }
                        when 'ExternalId' {
                            searchEngagementType = 'Default';
                        }
                    }
                    System.debug('Mock data? ' + mockData);
                    if(!mockData){
                        List<Map<String,Object>> rows = CSharkIntegrationService.getCustomer(
                                CSharkIntegrationService.SearchType.EuroBonus,
                                (String) filter.columnValue).dataRows;
                        System.debug('Returntable = ' + rows);
                        returnTable = Datasource.TableResult.get(c.tableSelection, rows);
                    } 
                    else{
                        System.debug('Else for returning mock');
                        returnTable = Datasource.TableResult.get(c.tableSelection, getMockRows((String) filter.columnValue));
                    }


                }
                else{
                    throw new CSharkIntegrationService.CSharkIntegrationException('Please provide only one value to filter by. Filter: ' + filter);
                }
            }
        }
            System.debug('Return table: ' + returnTable);
            return returnTable;
    }

    private static String evaluateFilter(){
        return '';
    }

    /**
     * Helper method used to generate mock data based on a preconfigured response with a certain search criteria
     * @param searchValue EuroBonus number to search for. Only one value will return a result.
     * @return If searchValue matches, a customer data row is returned. If not, the return is empty.
     */
    private List<Map<String, Object>> getMockRows (String searchValue) {
        List<Map<String, Object>> dataRows = new List<Map<String, Object>>();
        if(searchValue == '544108996'){
            StaticResource mockResponse = [SELECT Id, Body FROM StaticResource WHERE Name = 'FrequentFlyerMock_544108996'];
            CSharkResponseParser parser = new CSharkResponseParser(mockResponse.Body.toString());
            parser.parseCustomerGetResponse();
            dataRows = parser.dataRows;
        }
        return dataRows;
    }
}