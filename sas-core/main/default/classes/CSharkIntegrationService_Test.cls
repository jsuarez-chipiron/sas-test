/**
 * @author Anton Norell
 * @date 2019-11-25
 * @description Test class for the integration service handling requests to CShark. The CSharkResponseParser is also
 *              tested through this class.
 */
@IsTest
public with sharing class CSharkIntegrationService_Test {

    @IsTest
    static void shouldReturnEuroBonusCustomer(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CustomerGetResponseWithCustomer');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'text/xml');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CSharkIntegrationService.CSharkResponse response = CSharkIntegrationService.getCustomer(
                CSharkIntegrationService.SearchType.EuroBonus,
                '700001423');
        Test.stopTest();
        System.assertEquals(null, response.errorMessage, 'Operation returned an error message - should be null');

        System.assertEquals(1, response.dataRows.size(), 'Operation did not return the expected number of rows');

        //Test mapping to table
        Map<String,Object> dataRow = response.dataRows[0];
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
    }

    @IsTest
    static void shouldReturn401Error(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CustomerGetResponseWithCustomer');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'text/xml');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CSharkIntegrationService.CSharkResponse response = CSharkIntegrationService.getCustomer(
                CSharkIntegrationService.SearchType.EuroBonus,
                '700001423');
        Test.stopTest();

        System.assertNotEquals(null, response.errorMessage);
        System.assertEquals(0, response.dataRows.size());
    }

    @IsTest
    static void shouldReturnParseError(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CustomerGetResponseParseError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'text/xml');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CSharkIntegrationService.CSharkResponse response = CSharkIntegrationService.getCustomer(
                CSharkIntegrationService.SearchType.EuroBonus,
                '700001423');
        Test.stopTest();

        System.assertNotEquals(null, response.errorMessage);
        System.assertEquals('An error occurred during parsing of C-Shark response. See log for more details.', response.errorMessage);
    }
}