/**
 * @author Philip Ossler
 * @date 2020-04-14
 * @description Test class for FCS_EmailPublisherAction class
 */
@isTest
private class FCS_EmailPublisherAction_Test {
  // default address for redirected Cases
  @isTest
  static void defaultFromAddressforRedirctedCase() {
    List<From_email_based_on_Dept_and_Teams__c> CSFromEmail = new List<From_email_based_on_Dept_and_Teams__c>{
      new From_email_based_on_Dept_and_Teams__c(
        Name = 'Group Sales ACE',
        Case_Department__c = 'Group Sales',
        Case_Team__c = 'ACE',
        From_Email__c = 'groupsalestest@sas.se'
      )
    };

    insert CSFromEmail;

    List<Case> Cases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      C_RecordTypeHelper.CASE_CHANNEL,
      null
    );
    cases[0].origin = 'Email - EuroBonus Name Change';
    insert Cases;

    // redirect the cases
    cases[0].IsRedirected__c = true;
    cases[0].Department__c = 'Group Sales';
    cases[0].Team__c = 'ACE';
    update cases;

    EmailMessage email = new EmailMessage();
    email.ToAddress = 'groupsalestest@sas.se';
    email.ParentId = cases[0].Id;
    insert email;

    //create QuickActionDefaults
    List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
      new Map<String, Object>{
        'targetSObject' => new EmailMessage(),
        'contextId' => cases[0].Id,
        'actionType' => 'Email',
        'actionName' => 'Case.Email',
        'fromAddressList' => new List<String>{ email.ToAddress }
      }
    };

    List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
      JSON.serialize(defaultSettingAsObject),
      List<QuickAction.SendEmailQuickActionDefaults>.class
    );
    Test.startTest();
    (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
    Test.stopTest();

    System.assertEquals(
      CSFromEmail[0].From_Email__c,
      ((EmailMessage) defaultsSettings[0].getTargetSObject())
        .ValidatedFromAddress
    );
  }
  // user to default the from address if more than email-to-case present for escalated cases
  @isTest
  static void defaultFromAddressEscalatedCase() {
    List<From_email_based_on_Dept_and_Teams__c> CSFromEmail = new List<From_email_based_on_Dept_and_Teams__c>();

    CSFromEmail.add(
      new From_email_based_on_Dept_and_Teams__c(
        Name = 'Corporate Support International',
        Case_Department__c = 'Corporate',
        From_Email__c = 'coporateinternationtest@sas.se',
        Priority__c = 1
      )
    );
    CSFromEmail.add(
      new From_email_based_on_Dept_and_Teams__c(
        Name = 'Corporate Support Scandinavia',
        Case_Department__c = 'Corporate',
        From_Email__c = 'coporateScandinavia@sas.se',
        Priority__c = 2
      )
    );

    insert CSFromEmail;

    List<Case> Cases = FCS_TestDataFactory.createCases(
      1,
      null,
      null,
      C_RecordTypeHelper.CASE_CHANNEL,
      null
    );
    cases[0].origin = 'Email - Pandion DK';
    insert Cases;

    // Escalate the cases
    cases[0].IsEscalated__c = true;
    cases[0].status = 'Escalated';
    cases[0].Department__c = 'Corporate';
    cases[0].Team__c = '';
    update cases;

    EmailMessage email = new EmailMessage();
    email.ToAddress = 'coporateinternationtest@sas.se';
    email.ParentId = cases[0].Id;
    insert email;

    //create QuickActionDefaults
    List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
      new Map<String, Object>{
        'targetSObject' => new EmailMessage(),
        'contextId' => cases[0].Id,
        'actionType' => 'Email',
        'actionName' => 'Case.Email',
        'fromAddressList' => new List<String>{ email.ToAddress }
      }
    };

    List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
      JSON.serialize(defaultSettingAsObject),
      List<QuickAction.SendEmailQuickActionDefaults>.class
    );
    Test.startTest();
    (new FCS_EmailPublisherAction()).onInitDefaults(defaultsSettings);
    Test.stopTest();

    System.assertEquals(
      CSFromEmail[0].From_Email__c,
      ((EmailMessage) defaultsSettings[0].getTargetSObject())
        .ValidatedFromAddress
    );
  }
}
