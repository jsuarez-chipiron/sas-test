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
        insert accs;
        Case[] cList = FCS_TestDataFactory.createCases(5, accs[0].Id, accs[0].PersonContactId, RecordTypeHelper.CASE_SUPPORT, 'Baggage');
        cList.addAll(FCS_TestDataFactory.createCases(1, accs[1].Id, accs[1].PersonContactId, RecordTypeHelper.CASE_SUPPORT, 'Baggage'));
        cList[0].Status = 'Closed';
        cList[1].Status = 'Closed';
        cList[2].Status = 'Closed';
        cList[3].Status = 'Closed';
        cList[4].Status = 'Closed';
        cList[5].Status = 'Open';
        insert cList;
        insert new EmailMessage(FromAddress='test@example.com.invalid',FromName='Test',Incoming=true,Subject='TestSubject',TextBody='TestBody',ToAddress='test@sas.se',ParentId=cList[0].Id);
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
        spList[0].ParentId = cList[3].Id;
        insert spList;
    }
    /**
        Tests that account data is wiped after the retention period but left for account with open cases
    */
    @isTest static void deleteAccountData(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('AccountDataWipePeriod','-1');
        sg.set('AccountDataWipeName','TestDelete');
        Database.executeBatch(new GDPR_DeleteAccountData_Batch());
        Test.stopTest();

        Account[] accsWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=true];
        System.assertEquals(1,accsWiped.size());
        System.assertEquals('TestDelete',accsWiped[0].Name);
        System.assertEquals(true,accsWiped[0].GDPR_WipedSoft__c);
        System.assertEquals(false,accsWiped[0].GDPR_Wiped__c);
        System.assertEquals(null,accsWiped[0].EBLevel__c);

        Account[] accsNotWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=false];
        System.assertEquals(1,accsNotWiped.size());
        System.assertNotEquals('TestDelete',accsNotWiped[0].Name);
        System.assertEquals(false,accsNotWiped[0].GDPR_WipedSoft__c);
        System.assertEquals(false,accsWiped[0].GDPR_Wiped__c);
        System.assertNotEquals(null,accsNotWiped[0].EBLevel__c);
    }

    /**
        Tests that accounts can be wiped completely from the system
    */
    @isTest static void wipeAccount(){
        Account acc = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE LastName='TESTACC1'];
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('AccountDataWipePeriod','1');
        sg.set('AccountDataWipeName','TestDelete');
        GDPR_WipeAccountService.wipeAccount(acc.Id);
        Test.stopTest();

        acc = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE Id=:acc.Id];
        System.assertEquals('TestDelete',acc.Name);
        System.assertEquals(true,acc.GDPR_Wiped__c);
        System.assertEquals(true,acc.GDPR_WipedSoft__c);
        System.assertEquals(null,acc.EBLevel__c);

        Account[] accsNotWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE GDPR_Wiped__c=false];
        System.assertEquals(1,accsNotWiped.size());
        System.assertNotEquals('TestDelete',accsNotWiped[0].Name);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_Wiped__c);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_WipedSoft__c);
        System.assertNotEquals(null,accsNotWiped[0].EBLevel__c);

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
        sg.set('AccountDataWipePeriod','1');
        sg.set('AccountDataWipeName','TestDelete');
        Database.executeBatch(new GDPR_DeleteAccountData_Batch());
        Test.stopTest();

        Account[] accsWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=true];
        System.assertEquals(0,accsWiped.size());

        Account[] accsNotWiped = [SELECT Id,Name,GDPR_Wiped__c,GDPR_WipedSoft__c,EBLevel__c FROM Account WHERE GDPR_WipedSoft__c=false];
        System.assertEquals(2,accsNotWiped.size());
        System.assertNotEquals('TestDelete',accsNotWiped[0].Name);
        System.assertNotEquals('TestDelete',accsNotWiped[1].Name);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_Wiped__c);
        System.assertNotEquals(true,accsNotWiped[1].GDPR_Wiped__c);
        System.assertNotEquals(true,accsNotWiped[0].GDPR_WipedSoft__c);
        System.assertNotEquals(true,accsNotWiped[1].GDPR_WipedSoft__c);
        System.assertNotEquals(null,accsNotWiped[0].EBLevel__c);
        System.assertNotEquals(null,accsNotWiped[1].EBLevel__c);
    }

    /**
        Tests case deletion
    */
    @isTest static void deleteCase(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('MaxRetentionPeriod','-1');
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
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('MaxRetentionPeriod','1');
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
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('NoConsentRetentionPeriod','-1');
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
        Tests that case wipe retains cases within the retention period
    */
    @isTest static void wipeCaseRetain(){
        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('NoConsentRetentionPeriod','1');
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
        Tests that batches which deletes interactions deletes the interactions when not connected to a case
    */
    @isTest static void deleteInteraction(){
        delete [SELECT Id FROM Case];
        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatVisitor].size());
        System.assertEquals(1,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM MessagingEndUser].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());

        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('MaxRetentionPeriod','-1');
        sg.set('NoConsentRetentionPeriod','-1');
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
        Tests that deletion of interactions does not run for interactions connected to cases
    */
    @isTest static void retainInteractionWithCase(){

        delete [SELECT Id FROM Case];
        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatVisitor].size());
        System.assertEquals(1,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM MessagingEndUser].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());

        Test.startTest();
        C_Settings.SettingsGroup sg = C_Settings.getSettings('GDPR');
        sg.set('MaxRetentionPeriod','1');
        sg.set('NoConsentRetentionPeriod','1');
        Database.executeBatch(new GDPR_DeleteChat_Batch());
        Database.executeBatch(new GDPR_DeleteMessaging_Batch());
        Database.executeBatch(new GDPR_DeleteSocialPost_Batch());
        Test.stopTest();

        System.assertEquals(0,[SELECT Id FROM EmailMessage].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatTranscript].size());
        System.assertEquals(1,[SELECT Id FROM LiveChatVisitor].size());
        System.assertEquals(1,[SELECT Id FROM MessagingSession].size());
        System.assertEquals(1,[SELECT Id FROM MessagingEndUser].size());
        System.assertEquals(1,[SELECT Id FROM SocialPost].size());
    }


}

