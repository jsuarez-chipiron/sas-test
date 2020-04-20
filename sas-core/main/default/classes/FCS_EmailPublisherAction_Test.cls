/**
 * @author Philip Ossler
 * @date 2020-04-14
 * @description Test class for FCS_EmailPublisherAction class
 */
@isTest
private class FCS_EmailPublisherAction_Test {
    @isTest
    static void defaultFromAddressSalesInformation() {
        C_Settings.getSettings('EMAIL ADDRESS').set('Sales Information', 'salesinformation@test.com');

        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        cases[0].Type = 'Sales Information';
        insert cases;

        EmailMessage email = new EmailMessage();
        email.ToAddress = 'salesinformation@test.com';
        email.ParentId = cases[0].Id; 
        insert email;

        //create QuickActionDefaults
        List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
        {
            new Map<String, Object>
            {
                'targetSObject' => new EmailMessage(),
                'contextId' => cases[0].Id,
                'actionType' => 'Email',
                'actionName' => 'Case.Email',
                'fromAddressList' => new List<String> {email.ToAddress}
            }
        };

        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
        Test.startTest();
        (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
        Test.stopTest();
        System.assertEquals(C_Settings.getSettings('EMAIL ADDRESS').get('Sales Information'), ((EmailMessage)defaultsSettings[0].getTargetSObject()).FromAddress);
    }

    @isTest
    static void defaultFromAddressSASSIInternal() {
        C_Settings.getSettings('EMAIL ADDRESS').set('SASSI Internal', 'sassiinternal@test.com');

        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        cases[0].Type = 'SASSI Internal';
        insert cases;

        EmailMessage email = new EmailMessage();
        email.ToAddress = 'sassiinternal@test.com';
        email.ParentId = cases[0].Id; 
        insert email;

        //create QuickActionDefaults
        List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
        {
            new Map<String, Object>
            {
                'targetSObject' => new EmailMessage(),
                'contextId' => cases[0].Id,
                'actionType' => 'Email',
                'actionName' => 'Case.Email',
                'fromAddressList' => new List<String> {email.ToAddress}
            }
        };

        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
        Test.startTest();
        (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
        Test.stopTest();
        System.assertEquals(C_Settings.getSettings('EMAIL ADDRESS').get('SASSI Internal'), ((EmailMessage)defaultsSettings[0].getTargetSObject()).FromAddress);
    }

    @isTest
    static void defaultFromAddressSystemTariff() {
        C_Settings.getSettings('EMAIL ADDRESS').set('System & Tariff', 'systemtariff@test.com');

        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        insert cases;

        EmailMessage email = new EmailMessage();
        email.ToAddress = 'systemtariff@test.com';
        email.ParentId = cases[0].Id; 
        insert email;

        //create QuickActionDefaults
        List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
        {
            new Map<String, Object>
            {
                'targetSObject' => new EmailMessage(),
                'contextId' => cases[0].Id,
                'ToAddress' => email.ToAddress,
                'actionType' => 'Email',
                'actionName' => 'Case.Email',
                'fromAddressList' => new List<String> {email.ToAddress}
            }
        };

        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
        Test.startTest();
        (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
        Test.stopTest();
        System.assertEquals(C_Settings.getSettings('EMAIL ADDRESS').get('System & Tariff'), ((EmailMessage)defaultsSettings[0].getTargetSObject()).FromAddress);
    }
}