public with sharing class APIMGetCustomerRequest {
    
    //public enum SearchEngagementType {S_EuroBonus, S_TP, S_SiteMember, S_Subscription, S_Default}
    
    public static CSharkCustomer getCustomer(String searchEngagementType, String engagementSearchKey){
        C_Log.HttpData httpDataLog = new C_Log.HttpData();

        CSharkCustomer customerResponse;
        try{
            List<AccessToken__c> accessToken = [SELECT Id, Token__c, Name FROM AccessToken__c WHERE Name = 'APIM'];
            if(accessToken.isEmpty()) throw new APIMException('Cannot find Access Token for APIM');

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:SAS_APIM/custmgmt/CustomerGet-clone');
            request.setMethod('POST');
            request.setBody('{ "customerGet": {"searchEngagementType": "' + searchEngagementType + '", "engagementSearchKey": "' + engagementSearchKey + '"}}');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Ocp-Apim-Subscription-Key', '09f8570b366b4c1392c170ff77356140');
            request.setHeader('Authorization', 'Bearer ' + accessToken[0].Token__c);
            
            httpDataLog.resource = 'APIMGetCustomerRequest.getCustomer';
            httpDataLog.remoteAddress = request.getEndpoint();
            httpDataLog.headers = request.getHeader('Content-Type') + ', ' + request.getHeader('Ocp-Apim-Subscription-Key');
            httpDataLog.method = request.getMethod();
            httpDataLog.body = request.getBody();

            System.debug('Body: ' + request.getBody());

            HttpResponse response = http.send(request);

            if(response.getStatusCode() == 200){
                System.debug('Response: ' + response.getBody());     
                customerResponse = (CSharkCustomer) JSON.deserialize(response.getBody(), CSharkCustomer.class); 
            } 
            else{
                throw new APIMException('Recieved unsuccessfull response from APIM: ' + response.getStatusCode() + ': ' + response.getStatus() + ', ' + response.getBody());
            }
        } catch(Exception e){
            C_Log.logException(e, 'APIM', httpDataLog);
            throw new ApimException(e);
        }
        return customerResponse;
    }

        public static void updateAccessToken(){
        C_Log.HttpData httpDataLog = new C_Log.HttpData();
        try{
            String resource = 'https://flysas.com/a1a39693-e99f-469b-bb7b-5bb45b8b346f';

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:SAS_APIM/oauth/token');
            request.setMethod('POST');
            request.setBody('Client_Id={!$Credential.Username}' + '&Client_Secret={!$Credential.Password}' + '&resource=' + resource + '&grant_type=client_credentials');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setHeader('Ocp-Apim-Subscription-Key', '09f8570b366b4c1392c170ff77356140');

            httpDataLog.resource = 'APIMGetCustomerRequest.updateAccessToken';
            httpDataLog.remoteAddress = request.getEndpoint();
            httpDataLog.headers = request.getHeader('Content-Type') + ', ' + request.getHeader('Ocp-Apim-Subscription-Key');
            httpDataLog.method = request.getMethod();
            httpDataLog.body = '*Hidden*';

            HttpResponse response = http.send(request);

            if(response.getStatusCode() == 200){
                Map<String, Object> responsebodyMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String tokenString = responsebodyMap.get('access_token').toString();

                List<AccessToken__c> token = [SELECT Id, Token__c, Name FROM AccessToken__c WHERE Name = 'APIM'];
                if(!token.isEmpty()){
                    token[0].Token__c = tokenString;
                    update token[0];
                } 
                else{
                    insert new AccessToken__c(Name = 'APIM', Token__c = tokenString);
                }
                    
            }
            else{
                throw new APIMException('Error when trying to update access token for APIM: ' + response.getStatusCode() + ': ' + response.getStatus());
            }
        } catch(Exception e){
            C_Log.logException(e, 'APIM', httpDataLog);
            throw new ApimException(e);
        }
    }

     public with sharing class APIMException extends Exception{}
}