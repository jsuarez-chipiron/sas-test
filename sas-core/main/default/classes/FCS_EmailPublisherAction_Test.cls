/**
 * @author Philip Ossler
 * @date 2020-04-14
 * @description Test class for FCS_EmailPublisherAction class
 */
@isTest
private class FCS_EmailPublisherAction_Test {
    @isTest
    static void defaultFromAddressSalesInformation() {
        List<C_GeneralSetting__mdt> gs = new List<C_GeneralSetting__mdt> {
            new C_GeneralSetting__mdt(MasterLabel = 'Sales Information', Value__c = 'salesinformation@test.com', Group__c = 'EMAIL ADDRESS')
        };

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

        System.assertEquals(C_Settings.getSettings('EMAIL ADDRESS').get('Sales Information'), ((EmailMessage)defaultsSettings[0].getTargetSObject()).ValidatedFromAddress);
    }

    @isTest
    static void defaultFromAddressSASSIInternal() {
        List<C_GeneralSetting__mdt> gs = new List<C_GeneralSetting__mdt> {
            new C_GeneralSetting__mdt(MasterLabel = 'SASSI Internal', Value__c = 'sassiinternal@test.com', Group__c = 'EMAIL ADDRESS')
        };

        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        cases[0].Type = 'SASSI Internal';
        insert cases;
        System.debug(cases);

        EmailMessage email = new EmailMessage();
        email.ToAddress = 'sassiinternal@test.com';
        email.ParentId = cases[0].Id; 
        insert email;
        System.debug(email);

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
        System.debug(defaultSettingAsObject);

        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
        Test.startTest();
            (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
        Test.stopTest();

        System.assertEquals(C_Settings.getSettings('EMAIL ADDRESS').get('SASSI Internal'), ((EmailMessage)defaultsSettings[0].getTargetSObject()).ValidatedFromAddress);
    }

    @isTest
    static void defaultFromAddressSystemTariff() {
        List<C_GeneralSetting__mdt> gs = new List<C_GeneralSetting__mdt> {
            new C_GeneralSetting__mdt(MasterLabel = 'System & Tariff', Value__c = 'systemtariff@test.com', Group__c = 'EMAIL ADDRESS')
        };

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

        System.assertEquals(C_Settings.getSettings('EMAIL ADDRESS').get('System & Tariff'), ((EmailMessage)defaultsSettings[0].getTargetSObject()).ValidatedFromAddress);
    }
}
