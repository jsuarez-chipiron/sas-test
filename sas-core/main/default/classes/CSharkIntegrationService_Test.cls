/**
 * @author Anton Norell
 * @date 2019-11-25
 * @description Test class for the integration service handling requests to CShark. The CSharkResponseParser is also
 *              tested through this class.
 */
@IsTest
public with sharing class CSharkIntegrationService_Test {
    /**
     * Asserts that a search for a certain EuroBonus customer returns the correct information for that customer.
     * All expected fields should be validated against the content of the mock file in static resources.
     */
    @IsTest
    static void shouldReturnEuroBonusCustomer(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CustomerGetResponseWithCustomer');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'text/xml');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
                CSharkIntegrationService.SearchType.EB_NUMBER,
                '700001423');
        Test.stopTest();

        System.assertEquals(1, response.size(), 'Operation did not return the expected number of rows');
        Map<String,Object> dataRow = response[0];
        System.assertEquals(Date.valueOf('1988-10-13T00:00:00'), dataRow.get('BirthDate'));
        System.assertEquals('Marcus', dataRow.get('FirstName'));
        System.assertEquals('M', dataRow.get('Gender'));
        System.assertEquals('10401209', dataRow.get('ExternalId'));
        System.assertEquals('CLMTestSix', dataRow.get('LastName'));
        System.assertEquals('Senior Title', dataRow.get('Title'));
        System.assertEquals('Middle', dataRow.get('MiddleName'));
        System.assertEquals('Mr', dataRow.get('Salutation'));
        System.assertEquals('Teststreet 11', dataRow.get('HomeAddressLine1'));
        System.assertEquals('', dataRow.get('HomeAddressLine2'));
        System.assertEquals('', dataRow.get('HomeAddressLine2'));
        System.assertEquals('Stockholm', dataRow.get('HomeCityName'));
        System.assertEquals('SE', dataRow.get('HomeCountryCode'));
        System.assertEquals('', dataRow.get('HomeCountyState'));
        System.assertEquals('117 30', dataRow.get('HomeZipCode'));
        System.assertEquals('false', dataRow.get('ConsentEMail'));
        System.assertEquals('true', dataRow.get('ConsentSMS'));
        System.assertEquals('false', dataRow.get('ConsentTelemarketing'));
        System.assertEquals('true', dataRow.get('ConsentEB'));
        System.assertEquals(null, dataRow.get('ConsentEB0'));
        System.assertEquals('testskapp@gmail.comm', dataRow.get('HomeE-mail'));
        System.assertEquals('+46725465098', dataRow.get('HomeMobile'));
        System.assertEquals('testskapp@gmail.com', dataRow.get('AltE-mail'));
        System.assertEquals('B', dataRow.get('IncentiveLevel'));
        System.assertEquals('11866721', dataRow.get('CompanyIdentifier'));
        System.assertEquals('RockFish', dataRow.get('CompanyName'));
        System.assertEquals('11866633', dataRow.get('ParentIdentifier'));
        System.assertEquals('928004605', dataRow.get('TravelPassAccountNumber'));
        System.assertEquals(Date.valueOf('2016-09-28T00:00:00'), dataRow.get('EnrollmentDate'));
    }

    /**
     * Asserts that a negative response from the C-Shark service is handled correctly.
     */
    @IsTest
    static void shouldReturn500Error(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CustomerGetResponseWithCustomer');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'text/xml');
        Test.setMock(HttpCalloutMock.class, mock);

        Exception returnedException;
        Test.startTest();
        try{
            List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
                    CSharkIntegrationService.SearchType.EB_NUMBER,
                    '700001423');
        } catch (CSharkIntegrationService.CSharkIntegrationException e){
            returnedException = e;
        }
        Test.stopTest();

        System.assertNotEquals(
                null,
                returnedException,
                'The integration service should have thrown an exception due to a 500 error, but that did not happen.'
        );
        System.assertEquals('C-Shark service responded with an error 500. See log for details.',
                returnedException.getMessage(),
                'The message in the exception did not match the expected message. Check if message has been changed.'
        );
    }

    /**
     * Asserts that when the parser for the C-Shark response fails, an exception is thrown.
     */
    @IsTest
    static void shouldReturnParseError(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CustomerGetResponseParseError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'text/xml');

        Test.setMock(HttpCalloutMock.class, mock);

        Exception returnedException;
        Test.startTest();
        try{
            List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
                    CSharkIntegrationService.SearchType.EB_NUMBER,
                    '700001423');
        } catch (Exception e){
            returnedException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, returnedException);
    }

    @IsTest
    static void shouldReturnMockDataWhenCallingMethodDirectly(){
        CSharkIntegrationService.SearchType searchType = CSharkIntegrationService.SearchType.EB_NUMBER;
        String searchValue = '544108996';

        List<Map<String, Object>> customerRows = CSharkIntegrationService.getMockRows(searchType, searchValue);

        System.assertNotEquals(0, customerRows.size(), 'Service for mock data returned no rows.');
        System.assertEquals(1, customerRows.size(), 'Service for mock data returned too many customer rows.');
    }

    @IsTest
    static void shouldNotReturnMockDataWhenCallingMethodDirectly(){
        CSharkIntegrationService.SearchType searchType = CSharkIntegrationService.SearchType.EB_NUMBER;
        String searchValue = 'Invalid Search Value';

        List<Map<String, Object>> customerRows = CSharkIntegrationService.getMockRows(searchType, searchValue);

        System.assertEquals(0, customerRows.size(), 'Service for mock data returned customer data even though search value was invalid.');
    }

    @IsTest
    static void shouldReturnCorrectSearchTypeBasedOnString(){
        List<String> searchStrings = new List<String>{
                'EuroBonusNumber',
                'TravelPassAccountNumber',
                'ExternalId',
                'HomeEMail',
                'SubscriptionID',
                'UserName'
        };

        List<CSharkIntegrationService.SearchType> searchTypes = new List<CSharkIntegrationService.SearchType>();
        for(String searchString : searchStrings){
            searchTypes.add(CSharkIntegrationService.getSearchTypeByFieldName(searchString));
        }

        System.assertEquals(CSharkIntegrationService.SearchType.EB_NUMBER, searchTypes[0]);
        System.assertEquals(CSharkIntegrationService.SearchType.TP_ACCOUNT, searchTypes[1]);
        System.assertEquals(CSharkIntegrationService.SearchType.CODS_ID, searchTypes[2]);
        System.assertEquals(CSharkIntegrationService.SearchType.EMAIL, searchTypes[3]);
        System.assertEquals(CSharkIntegrationService.SearchType.SUBSCRIPTION_ID, searchTypes[4]);
        System.assertEquals(CSharkIntegrationService.SearchType.SITE_MEMBER, searchTypes[5]);
    }

    /**
     * Asserts that the the CustomerGet body generation method uses the correct search engagement type value
     * bases on tha classes' search type enum list. If this method fails, check the order of the enums
     * for SearchType in CSharkIntegrationService.
     */
    @IsTest
    static void shouldGenerateCustomerGetBodyBasedInSearchType(){
        List<String> bodyList = new List<String>();
        for(CSharkIntegrationService.SearchType searchType:CSharkIntegrationService.SearchType.values()){
            bodyList.add(CSharkIntegrationService.generateCustomerGetBody(searchType, ''));
        }
        System.debug(bodyList);
        System.assert(bodyList[0].contains('<searchEngagementType>EuroBonus</searchEngagementType>'));
        System.assert(bodyList[1].contains('<searchEngagementType>Default</searchEngagementType>'));
        System.assert(bodyList[2].contains('<searchEngagementType>TP</searchEngagementType>'));
        System.assert(bodyList[3].contains('<searchEngagementType>Email</searchEngagementType>'));
        System.assert(bodyList[4].contains('<searchEngagementType>SiteMember</searchEngagementType>'));
        System.assert(bodyList[5].contains('<searchEngagementType>Subscription</searchEngagementType>'));
    }
}