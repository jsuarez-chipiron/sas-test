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
                CSharkIntegrationService.SearchType.EuroBonus,
                '700001423');
        Test.stopTest();

        System.assertEquals(1, response.size(), 'Operation did not return the expected number of rows');
        Map<String,Object> dataRow = response[0];
        System.assertEquals('1988-10-13T00:00:00', dataRow.get('BirthDate'));
        System.assertEquals('Marcus', dataRow.get('FirstName'));
        System.assertEquals('M', dataRow.get('Gender'));
        System.assertEquals('10401209', dataRow.get('ExternalId'));
        System.assertEquals('CLMTestSix', dataRow.get('LastName'));
        System.assertEquals('Mr', dataRow.get('Title'));
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
                    CSharkIntegrationService.SearchType.EuroBonus,
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
                    CSharkIntegrationService.SearchType.EuroBonus,
                    '700001423');
        } catch (Exception e){
            returnedException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, returnedException);
    }

    @IsTest
    static void shouldReturnMockDataWhenCallingMethodDirectly(){
        CSharkIntegrationService.SearchType searchType = CSharkIntegrationService.SearchType.EuroBonus;
        String searchValue = '544108996';

        List<Map<String, Object>> customerRows = CSharkIntegrationService.getMockRows(searchType, searchValue);

        System.assertNotEquals(0, customerRows.size(), 'Service for mock data returned no rows.');
        System.assertEquals(1, customerRows.size(), 'Service for mock data returned too many customer rows.');
    }

    @IsTest
    static void shouldNotReturnMockDataWhenCallingMethodDirectly(){
        CSharkIntegrationService.SearchType searchType = CSharkIntegrationService.SearchType.EuroBonus;
        String searchValue = 'Invalid Search Value';

        List<Map<String, Object>> customerRows = CSharkIntegrationService.getMockRows(searchType, searchValue);

        System.assertEquals(0, customerRows.size(), 'Service for mock data returned customer data even though search value was invalid.');
    }
}