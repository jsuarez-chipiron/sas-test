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
        } else if(c.tableSelection.tableSelected == 'PrivacySettings'){
            returnTable = Datasource.TableResult.get(c.tableSelection, getMockPrivacySettings());

        }
            System.debug('Return table: ' + returnTable);
            return returnTable;
    }

    private static String evaluateFilter(){
        return '';
    }

    private List<Map<String, Object>> getMockPrivacySettings(){
         List<Map<String,Object>> rows = new List<Map<String,Object>>();
          
            Map<String,Object> row1 = new Map<String,Object>();
            row1.put('ExternalId', '10787700_0');
            row1.put('DisplayUrl', '123');
            row1.put('Account', '10787700');
            row1.put('ActivationDate', Datetime.now().addYears(-1));
            row1.put('Active', false);
            row1.put('FrequentFlyer', '10787700');
            row1.put('PrivacyArea', 'Profiling');
            row1.put('Type', null);
            row1.put('Version', null);
            rows.add(row1);

            Map<String,Object> row2 = new Map<String,Object>();
            row2.put('ExternalId', '10787700_1');
            row2.put('DisplayUrl', '123');
            row2.put('Account', '10787700');
            row2.put('ActivationDate', null);
            row2.put('Active', true);
            row2.put('FrequentFlyer', '10787700');
            row2.put('PrivacyArea', 'DirectMarketing');
            row2.put('Type', 'EMail');
            row2.put('Version', null);
            rows.add(row2);

            Map<String,Object> row3 = new Map<String,Object>();
            row3.put('ExternalId', '10787700_2');
            row3.put('DisplayUrl', '123');
            row3.put('Account', '10787700');
            row3.put('ActivationDate', Datetime.now().addMonths(-8));
            row3.put('Active', true);
            row3.put('FrequentFlyer', '10787700');
            row3.put('PrivacyArea', 'DirectMarketing');
            row3.put('Type', 'SMS');
            row3.put('Version', 15);
            rows.add(row3);

            Map<String,Object> row4 = new Map<String,Object>();
            row4.put('ExternalId', '10787700_3');
            row4.put('DisplayUrl', '123');
            row4.put('Account', '10787700');
            row4.put('ActivationDate', Datetime.now());
            row4.put('Active', true);
            row4.put('FrequentFlyer', '10787700');
            row4.put('PrivacyArea', 'DirectMarketing');
            row4.put('Type', 'Telemarketing');
            row4.put('Version', null);
            rows.add(row4);

            Map<String,Object> row5 = new Map<String,Object>();
            row5.put('ExternalId', '10787700_4');
            row5.put('DisplayUrl', '123');
            row5.put('Account', '10787700');
            row5.put('ActivationDate', Datetime.now());
            row5.put('Active', true);
            row5.put('FrequentFlyer', '10787700');
            row5.put('PrivacyArea', 'TOC');
            row5.put('Type', 'EB0');
            row5.put('Version', 2);
            rows.add(row5);

            Map<String,Object> row6 = new Map<String,Object>();
            row6.put('ExternalId', '10787700_5');
            row6.put('DisplayUrl', '123');
            row6.put('Account', '10787700');
            row6.put('ActivationDate', Datetime.now());
            row6.put('Active', true);
            row6.put('FrequentFlyer', '10787700');
            row6.put('PrivacyArea', 'TOC');
            row6.put('Type', 'EB');
            row6.put('Version', 15);
            rows.add(row6);

        System.debug('Returning rows: ' + rows);
        return rows;
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
            row.put('consentEB', 'true');
            row.put('consentEmail', 'false');
            row.put('consentSMS', 'false');
            row.put('consentTelemarketing', 'false');
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