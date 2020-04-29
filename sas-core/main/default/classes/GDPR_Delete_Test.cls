/**
    Unit tests for GDPR delete batches to ensure that the correct entities are deleted
    @author Peter Södergren
*/
@isTest 
private class GDPR_Delete_Test {
    /**
        Creates the records used to tests data deletion
    */
    @testSetup static void setup(){
        Account[] accs = FCS_TestDataFactory.createFrequentFlyers(2);
        accs[0].LastName = 'TESTACC1';
        accs[1].LastName = 'TESTACC2';
        insert accs;
        Case[] cList = FCS_TestDataFactory.createCases(5, accs[0].Id, accs[0].PersonContactId, C_RecordTypeHelper.CASE_SUPPORT, 'Baggage');
        cList.addAll(FCS_TestDataFactory.createCases(1, accs[1].Id, accs[1].PersonContactId, C_RecordTypeHelper.CASE_SUPPORT, 'Baggage'));
        cList[0].Status = 'Closed';
        cList[1].Status = 'Closed';
        cList[2].Status = 'Closed';
        cList[3].Status = 'Closed';
        cList[4].Status = 'Closed';
        cList[5].Status = 'Open';
        insert cList;
		insert new EmailMessage(FromAddress='test@example.com.invalid',FromName='Test',Incoming=true,Subject='TestSubject',TextBody='TestBody',ToAddress='test@sas.se',ParentId=cList[0].Id);
		cList[0].Status = 'Closed';
		update cList;
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        insert new LiveChatTranscript(AccountId=accs[0].Id,Body='Test',CaseId=cList[1].Id,Status='Completed',LiveChatVisitorId=lcv.Id);
        MessagingChannel mc = new MessagingChannel(DeveloperName='TESTFB123',IsActive=false,MasterLabel='TESTFB123',MessageType='Facebook',MessagingPlatformKey='TESTFB1244567');
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u){
            insert mc;
        }
        MessagingEndUser meu = new MessagingEndUser(AccountId=accs[0].Id,ContactId=accs[0].PersonContactId,MessageType='Facebook',Name='Test',MessagingPlatformKey='TESTXYZ',MessagingChannelId=mc.Id);
        insert meu;
        insert new MessagingSession(CaseId=cList[2].Id,MessagingEndUserId=meu.Id,Status='Ended',MessagingChannelId=mc.Id);
        SocialPost[] spList = FCS_TestDataFactory.createSocialPosts(1);
        insert spList;
        spList[0].ParentId = cList[3].Id;
        update spList;

        IRR_CommunicationLog__c comlog = new IRR_CommunicationLog__c();
        comlog.IRR_ContactKey__c = 'test@email.com';
        insert comlog;
    }
    /**
        Sets up mock retention fields for tests due to a Salesforce bug which occurs when running all tests and fetching field definitions
    */
    static void setupMockRetentionFields(){
        GDPR_WipeCaseService.RETAIN_ADD = new Set<String>{'Type','Origin','Status','ClosedDate'};
    }
    /**
        Tests that account data is wiped after the retention period but left for account with open cases
    */
    @isTest static void deleteAccountData(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('WipePeriodAccount','-1');
        sg.set('AccountDataWipeName','TestDelete');
        Database.executeBatch(new GDPR_DeleteAccountData_Batch());
        Test.stopTest();

        Account[] accsWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=true];
        System.assertEquals(1,accsWiped.size());
        System.assertEquals('TestDelete',accsWiped[0].Name);
        System.assertEquals(true,accsWiped[0].GDPR_WipedSoft__c);
        System.assertEquals(false,accsWiped[0].GDPR_Wiped__c);
        System.assertEquals(null,accsWiped[0].FCS_EBLevel__c);

        Account[] accsNotWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=false];
        System.assertEquals(1,accsNotWiped.size());
        System.assertNotEquals('TestDelete',accsNotWiped[0].Name);
        System.assertEquals(false,accsNotWiped[0].GDPR_WipedSoft__c);
        System.assertEquals(false,accsWiped[0].GDPR_Wiped__c);
        System.assertNotEquals(null,accsNotWiped[0].FCS_EBLevel__c);
    }

    /**
        Tests that accounts can be wiped completely from the system
    */
    @isTest static void wipeAccount(){
        setupMockRetentionFields();
        Account acc = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE LastName='TESTACC1'];
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('WipePeriodAccount','1');
        sg.set('AccountDataWipeName','TestDelete');
        GDPR_DeleteComponentController.deleteRecordData(acc.Id);
        Test.stopTest();

        acc = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE Id=:acc.Id];
        System.assertEquals('TestDelete',acc.Name);
        System.assertEquals(true,acc.GDPR_Wiped__c);
        System.assertEquals(true,acc.GDPR_WipedSoft__c);
        System.assertEquals(null,acc.FCS_EBLevel__c);

        Account[] accsNotWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE GDPR_Wiped__c=false];
        System.assertEquals(1,accsNotWiped.size());
        System.assertNotEquals('TestDelete',accsNotWiped[0].Name);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_Wiped__c);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_WipedSoft__c);
        System.assertNotEquals(null,accsNotWiped[0].FCS_EBLevel__c);

        Case[] cClosed = [SELECT Id,GDPR_Wiped__c FROM Case WHERE IsClosed=true];
        System.assertEquals(5,cClosed.size());
        System.assertEquals(true,cClosed[0].GDPR_Wiped__c);
        System.assertEquals(true,cClosed[1].GDPR_Wiped__c);
        System.assertEquals(true,cClosed[2].GDPR_Wiped__c);
        System.assertEquals(true,cClosed[3].GDPR_Wiped__c);
        System.assertEquals(true,cClosed[4].GDPR_Wiped__c);

        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(0,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(0,[SELECT Id FROM LiveChatVisitor].size());
        System.assertEquals(0,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(0,[SELECT Id FROM MessagingEndUser].size());
        System.assertEquals(0,[SELECT Id FROM SocialPost].size());


    }


    /**
        Tests that account data is not wiped if cases are open or within the close period
    */
    @isTest static void retainAccountData(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('WipePeriodAccount','1');
        sg.set('AccountDataWipeName','TestDelete');
        Database.executeBatch(new GDPR_DeleteAccountData_Batch());
        Test.stopTest();

        Account[] accsWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=true];
        System.assertEquals(0,accsWiped.size());

        Account[] accsNotWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,FCS_EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=false];
        System.assertEquals(2,accsNotWiped.size());
        System.assertNotEquals('TestDelete',accsNotWiped[0].Name);
        System.assertNotEquals('TestDelete',accsNotWiped[1].Name);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_Wiped__c);
        System.assertNotEquals(true,accsNotWiped[1].GDPR_Wiped__c);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_WipedSoft__c);
        System.assertNotEquals(true,accsNotWiped[1].GDPR_WipedSoft__c);
        System.assertNotEquals(null,accsNotWiped[0].FCS_EBLevel__c);
        System.assertNotEquals(null,accsNotWiped[1].FCS_EBLevel__c);
    }

    /**
        Tests deletion of accounts (Should only occur when the account has no cases or interactions)
    */
    @isTest static void deleteAccount(){
        delete [SELECT Id FROM Case];
        Test.startTest();
        Database.executeBatch(new GDPR_DeleteAccount_Batch());
        Test.stopTest();
        Account[] accList = [SELECT Id,LastName FROM Account];
        System.assertEquals(1, accList.size());
        System.assertNotEquals('TESTACC2', accList[0].LastName);
    }

    /**
        Tests case deletion
    */
    @isTest static void deleteCase(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('DeletePeriodCase','-1');
        Database.executeBatch(new GDPR_DeleteCase_Batch());
        Test.stopTest();

        Case[] cOpen = [SELECT Id FROM Case WHERE IsClosed=false];
        System.assertEquals(1,cOpen.size());

        Case[] cClosed = [SELECT Id FROM Case WHERE IsClosed=true];
        System.assertEquals(0,cClosed.size());
        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(0,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(0,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(0,[SELECT Id FROM SocialPost].size());
    }
    
    /**
        Tests that cases within the retention period are kept
    */
    @isTest static void retainCase(){
        setupMockRetentionFields();
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('DeletePeriodCase','1');
        Database.executeBatch(new GDPR_DeleteCase_Batch());
        Test.stopTest();

        Case[] cOpen = [SELECT Id FROM Case WHERE IsClosed=false];
        System.assertEquals(1,cOpen.size());

        Case[] cClosed = [SELECT Id FROM Case WHERE IsClosed=true];
        System.assertEquals(5,cClosed.size());
        System.assertEquals(1,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(1,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());
    }

    /**
        Tests case wipe
    */
    @isTest static void wipeCase(){
        setupMockRetentionFields();
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('WipePeriodCase','-1');
        Database.executeBatch(new GDPR_WipeCase_Batch());
        Test.stopTest();

        Case[] cOpen = [SELECT Id FROM Case WHERE IsClosed=false];
        System.assertEquals(1,cOpen.size());

        Case[] cClosed = [SELECT Id FROM Case WHERE IsClosed=true];
        System.assertEquals(5,cClosed.size());
        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(0,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(0,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(0,[SELECT Id FROM SocialPost].size());
    }

    /**
        Tests case wipe using the case id as input to wipe specific case ids
    */
    @isTest static void wipeCaseManual(){
        setupMockRetentionFields();
        Test.startTest();
        MessagingSession ms = [SELECT Id,CaseId FROM MessagingSession];
        GDPR_DeleteComponentController.deleteRecordData(ms.CaseId);
        Test.stopTest();

        Case[] cOpen = [SELECT Id FROM Case WHERE IsClosed=false];
        System.assertEquals(1,cOpen.size());

        Case[] cClosed = [SELECT Id FROM Case WHERE IsClosed=true];
        System.assertEquals(5,cClosed.size());
        System.assertEquals(1,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(0,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());
    }

    /**
        Tests that case wipe retains cases within the retention period
    */
    @isTest static void wipeCaseRetain(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('WipePeriodCase','1');
        Database.executeBatch(new GDPR_WipeCase_Batch());
        Test.stopTest();

        Case[] cOpen = [SELECT Id FROM Case WHERE IsClosed=false];
        System.assertEquals(1,cOpen.size());

        Case[] cClosed = [SELECT Id FROM Case WHERE IsClosed=true];
        System.assertEquals(5,cClosed.size());
        System.assertEquals(1,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(1,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());
    }

    /**
        Tests that batches which deletes interactions deletes the interactions when outside the retention period
    */
    @isTest static void deleteInteraction(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('DeletePeriodEmail','-2');
        sg.set('DeletePeriodChat','-2');
        sg.set('DeletePeriodMessaging','-2');
        sg.set('DeletePeriodSocialPost','-2');
        sg.set('DeletePeriodEmailConsent','-1');
        sg.set('DeletePeriodChatConsent','-1');
        sg.set('DeletePeriodMessagingConsent','-1');
        sg.set('DeletePeriodSocialPostConsent','-1');
        Database.executeBatch(new GDPR_DeleteEmail_Batch());
        Database.executeBatch(new GDPR_DeleteChat_Batch());
        Database.executeBatch(new GDPR_DeleteMessaging_Batch());
        Database.executeBatch(new GDPR_DeleteSocialPost_Batch());
        Test.stopTest();

        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(0,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(0,[SELECT Id FROM LiveChatVisitor].size());
        System.assertEquals(0,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(0,[SELECT Id FROM MessagingEndUser].size());
        System.assertEquals(0,[SELECT Id FROM SocialPost].size());
    }

    /**
        Tests that deletion of interactions does not run for interactions within the retention period
    */
    @isTest static void retainInteraction(){

        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('DeletePeriodEmail','1');
        sg.set('DeletePeriodChat','1');
        sg.set('DeletePeriodMessaging','1');
        sg.set('DeletePeriodSocialPost','1');
        sg.set('DeletePeriodEmailConsent','1');
        sg.set('DeletePeriodChatConsent','1');
        sg.set('DeletePeriodMessagingConsent','1');
        sg.set('DeletePeriodSocialPostConsent','1');
        Database.executeBatch(new GDPR_DeleteEmail_Batch());
        Database.executeBatch(new GDPR_DeleteChat_Batch());
        Database.executeBatch(new GDPR_DeleteMessaging_Batch());
        Database.executeBatch(new GDPR_DeleteSocialPost_Batch());
        Test.stopTest();

        System.assertEquals(1,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatVisitor].size());
        System.assertEquals(1,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM MessagingEndUser].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());
    }

    

    /**
        Tests deletion of Communication Logs 
    */
    @isTest static void deleteCommunicationLogs(){
        IRR_CommunicationLog__c c = new IRR_CommunicationLog__c(IRR_ContactKey__c='test@email.com');
        insert c;
        DateTime dtTomorrow = DateTime.now();
        dtTomorrow = dtTomorrow.addDays(1);
        Test.setCreatedDate(c.Id, dtTomorrow);
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('DeletePeriodCommunucationLog','-1');
        Database.executeBatch(new GDPR_DeleteCommunicationLog_Batch());
        Test.stopTest();
        IRR_CommunicationLog__c[] comlogList = [SELECT Id, IRR_ContactKey__c FROM IRR_CommunicationLog__c];
        System.assertEquals(1, comlogList.size());
    }




    
}


