/**
 * Class used to act as a Data Source provider for SAS External Systmes using Salesforce Connect
 * Capabilities such as Authentication methods and operations support are set in this class
 */
global class SASExternalDataSourceProvider extends DataSource.Provider{

    override global List<DataSource.AuthenticationCapability> getAuthenticationCapabilities() {
        List<DataSource.AuthenticationCapability> capabilities = new List<DataSource.AuthenticationCapability>();
        
        //Data Source should not have authentication built in, that is handled by class making a callout
        capabilities.add(DataSource.AuthenticationCapability.ANONYMOUS);
        return capabilities;
    }

    //Currently, the Data Source only supports read operations
    override global List<DataSource.Capability> getCapabilities(){
        List<DataSource.Capability> capabilities = new List<DataSource.Capability>();
        capabilities.add(DataSource.Capability.ROW_QUERY);
        //capabilities.add(DataSource.Capability.SEARCH);
        //capabilities.add(DataSource.Capability.ROW_CREATE);
        //capabilities.add(DataSource.Capability.ROW_UPDATE);
        //capabilities.add(DataSource.Capability.ROW_DELETE);
        return capabilities;
    }

    override global DataSource.Connection getConnection(DataSource.ConnectionParams connectionParams) {
        return new SASExternalDataSourceConnection(connectionParams);
    }
}