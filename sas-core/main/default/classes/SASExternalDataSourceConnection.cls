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
            if(c.tableSelection.filter == null){
                throw new APIMGetCustomerRequest.APIMException('The query must be filtered by one of the following values: EBNumber__c, ExternalId');
            }
            else{
                //Check that only one parameter is included in filter
                if(filter.columnName != null){
                    //Throw exception if filter contains unsupporter operators
                    if(filter.type != DataSource.FilterType.EQUALS) throw new APIMGetCustomerRequest.APIMException('Only filter of typ EQUALS (=) is supported for this object');

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
                        CSharkCustomer customer = APIMGetCustomerRequest.getCustomer(searchEngagementType, (String) filter.columnValue);
                        List<Map<String,Object>> rows = new List<Map<String,Object>>();
                        //Check is request returned a customer. If not, an empty table is returned. 
                        if(customer != null){
                            CSharkCustomer.CustomerGetResult customerData = customer.customerGetResponse.customerGetResult;
                            Map<String,Object> row = new Map<String,Object>();
                            row.put('ExternalId', customerData.identifier);
                            row.put('DisplayUrl', 'url123');
                            row.put('firstName', customerData.firstName);
                            row.put('lastName', customerData.lastName);
                            row.put('fullName', customerData.firstName + customerData.lastName);
                            //row.put('email', customer.getEngagement('DefaultProfileEngagement').profile.VirtualAddresses[0].virtualAddressLine);
                            row.put('birthDate', customerData.birthDate);
                            row.put('euroBonusNumber', customerData.euroBonusNumber);
                            row.put('mobile', '+46700802145');
                            row.put('phone', '');
                            rows.add(row);
                            returnTable = Datasource.TableResult.get(c.tableSelection, rows);
                        }
                    } 
                    else{
                        System.debug('Else for returning mock');
                        returnTable = Datasource.TableResult.get(c.tableSelection, getMockRows((String) filter.columnValue));
                    }


                }
                else{
                    throw new APIMGetCustomerRequest.APIMException('Please provide only one value to filter by. Filter: ' + filter);
                }
            }
        }
            System.debug('Return table: ' + returnTable);
            return returnTable;
    }
    

    // Helper method to get record values from the external system for the Sample table.
    private List<Map<String, Object>> getMockRows (String searchValue) {
        List<Map<String,Object>> rows = new List<Map<String,Object>>();
        
        if(searchValue == '544108996'){    
            Map<String,Object> row = new Map<String,Object>();
            row.put('ExternalId', '10787700');
            row.put('DisplayUrl', '10787700');
            row.put('firstName', 'December');
            row.put('lastName', 'Lady');
            row.put('fullName', 'December Lady');
            row.put('emailPersonal', 'cvvdfffree@der.dd');
            row.put('birthDate', '1988-12-12T00:00:00');
            row.put('euroBonusNumber', '544108996');
            row.put('euroBonusLevel', 'G');
            row.put('mobile', '+4676565432');
            row.put('phone', '');
            row.put('addressLine1', '');
            row.put('addressLine2', '');
            row.put('addressLine3', '');
            row.put('city', '');
            row.put('countryCode', '');
            row.put('countyState', '');
            row.put('zipCode', '');
            row.put('concentEB', 'true');
            row.put('concentEmail', 'false');
            row.put('concentSMS', 'false');
            row.put('concentTelemarketing', 'false');
            row.put('mbrshipLvlStatusEndPeriod', '');
            row.put('mbrshipLvlStatusStartPeriod', '');
            row.put('basicPointsRequiredForHigerLevel', '');
            row.put('travelPassAccountNumber', '');
            row.put('subscriptionID', '544108996');
            row.put('gender', 'F');
            rows.add(row);
        }

        System.debug('Returning rows: ' + rows);
        return rows;
    }
}