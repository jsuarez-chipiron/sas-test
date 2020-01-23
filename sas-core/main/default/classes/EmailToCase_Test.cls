/**
    Test method for the process Case Set priority Urgent that sets the priority 
    to urgent based on input from customer in Subject field or if Email is Flagged as important. 
*/
@isTest 
private class EmailToCase_Test { 

    /**
        Set up the STOPQ-Escalation Queue
        @author Josephine Ding - Deloitte
     */
    @testSetup static void setup() {
        // Create common test accounts
        Group g1 = new Group(Name='STOPQ Escalations', type='Queue');
        insert g1;
        QueueSObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1; 

        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        QueueSObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
        insert testQueue;    
    }

    /**
        Test creating a Case as it would be created via Email-To-Case to the STOPQ Escalation-Queue with Urgent in subject
        @author Josephine Ding - Deloitte
    */
    @isTest 
    static void setCaseUrgentTest(){ 
        Group g  =[SELECT Id FROM Group WHERE Name = 'STOPQ Escalations' LIMIT 1];
        Case c1 = new Case (Status='New', Origin='Email', Subject='Test subject urgent', OwnerId = g.Id);
        Test.startTest();
        insert c1; 
        Test.stopTest();
        System.assertEquals('Urgent', [SELECT Priority FROM Case WHERE Id = :c1.Id].Priority);  
    }

    /**
        Test creating a Case as it would be created via Email-To-Case to the STOPQ Escalation-Queue without Urgent in subject
        @author Philip Ossler - Deloitte
    */
    @isTest 
    static void setCaseNotUrgentTest(){ 
        Group g  =[SELECT Id FROM Group WHERE Name = 'STOPQ Escalations' LIMIT 1];
        Case c1 = new Case (Status='New', Origin='Email', Subject='Test subject', OwnerId = g.Id);
        Test.startTest();
        insert c1; 
        Test.stopTest();
        System.assertNotEquals('Urgent', [SELECT Priority FROM Case WHERE Id = :c1.Id].Priority);  
    }

    /**
        Tests the Process on Email Message where a Case created from an Email with High Importance should have the Priority Urgent
        @author Philip Ossler - Deloitte
    */
    @isTest
    static void sendEmailWithImportanceFlag(){
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        cases[0].Priority = 'Medium';
        cases[0].Origin = 'Email';
        insert(cases[0]);

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.se';
        email.Incoming = True;
        email.ToAddress= 'test@def.se';
        email.Subject = 'Test Subject';
        email.HtmlBody = 'Test Body';
        email.Headers = 'Importance: High';
        email.ParentId = cases[0].Id; 
        insert email;

        List<Case> updatedCase = [SELECT Priority FROM Case WHERE id =: cases[0].Id];
        System.assertEquals('Urgent', updatedCase[0].Priority);
    }

    /**
        Tests the Process on Email Message where a Case created from an Email without any specific importance shouldn't change Priority
        @author Philip Ossler - Deloitte
    */
    @isTest
    static void sendEmailWithoutImportanceFlag(){
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        cases[0].Priority = 'Medium';
        cases[0].Origin = 'Email';
        insert(cases[0]);

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.se';
        email.Incoming = True;
        email.ToAddress= 'test@def.se';
        email.Subject = 'Test Subject';
        email.HtmlBody = 'Test Body';
        email.ParentId = cases[0].Id; 
        insert email;

        List<Case> updatedCase = [SELECT Priority FROM Case WHERE id =: cases[0].Id];
        System.assertNotEquals('Urgent', updatedCase[0].Priority);
    }

    /**
        Tests the Process on Email Message where an Email is sent to Sales Information address which should result in the Case having Type Sales Information
        @author Philip Ossler - Deloitte
    */
    @isTest
    static void sendEmailToSalesInformation(){
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        insert cases;

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.se';
        email.Incoming = True;
        email.ToAddress= 'salesinformation@sas.se';
        email.Subject = 'Test Subject';
        email.HtmlBody = 'Test Body';
        email.ParentId = cases[0].Id; 
        insert email;

        List<Case> updatedCase = [SELECT Type FROM Case WHERE id =: cases[0].Id];
        System.assertEquals('Sales Information', updatedCase[0].Type);
    }

    /**
        Tests the Process on Email Message where an Email is sent to SASSI Internal address which should result in the Case having Type SASSI Internal
        @author Philip Ossler - Deloitte
    */
    @isTest
    static void sendEmailToSASSIInternal(){
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        insert cases;

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.se';
        email.Incoming = True;
        email.ToAddress= 'sassi.internal@sas.dk';
        email.Subject = 'Test Subject';
        email.HtmlBody = 'Test Body';
        email.ParentId = cases[0].Id; 
        insert email;

        List<Case> updatedCase = [SELECT Type FROM Case WHERE id =: cases[0].Id];
        System.assertEquals('SASSI Internal', updatedCase[0].Type);
    }

    /**
        Tests the Process on Email Message where an Email is sent to System/Tariff address which should result in the Case having no Type
        @author Philip Ossler - Deloitte
    */
    @isTest
    static void sendEmailToSystemTariff(){
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
        insert cases;

        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.se';
        email.Incoming = True;
        email.ToAddress= 'pq_commercial_procedures_and_tariff_support@sas.se';
        email.Subject = 'Test Subject';
        email.HtmlBody = 'Test Body';

        email.ParentId = cases[0].Id; 
        insert email;

        List<Case> updatedCase = [SELECT Type FROM Case WHERE id =: cases[0].Id];
        System.assertEquals(null, updatedCase[0].Type);
    }

 /**
        Test creating a Case when userId of Case Owner starts with 005
        @author Josephine Ding - Deloitte
    */
    @isTest 
    static void setCaseOwnerUserTest(){ 
         Profile pf = [Select Id from Profile where name = 'System Administrator' LIMIT 1];
        //Create the user
        User theUser = new User ();
        theUser.FCS_Team__c = 'Team 1';
        theUser.FCS_Site__c = 'ODE';
        theUser.FCS_Vendor__c = 'Sykes';
        theUser.FCS_VirtualOrganization__c = 'Direct Sales';
        
        theUser.FirstName = 'Test';
        theUser.LastName = 'Name';
        theUser.CompanyName = 'IT Test Company';
        theUser.MobilePhone = '123-456-7890';
        
        theUser.Username = 'testUser-' + '@test.com';
        theUser.Email = 'testUser-' + '@test.com';
        theUser.Alias = 'test';
        theUser.CommunityNickname = 'test1';
        theUser.TimeZoneSidKey = 'America/New_York';
        theUser.LocaleSidKey = 'en_US';
        theUser.EmailEncodingKey = 'UTF-8';
        theUser.ProfileId = pf.Id;
        theUser.LanguageLocaleKey = 'en_US';
        
        theUser.Street = '123 Test St';
        theUser.City = 'Testcity';
        theUser.State = 'va';
        theUser.PostalCode = '23223';
        theUser.Country = 'USA';
        //insert user
        insert theUser;
        //Set the owner of the case to be the User you created 
        Case testCase = new Case(OwnerId = theUser.Id);
                
        Test.startTest();
        //insert testCase; 
        insert testCase;
        //Do asserts and check if the fields in User are the same as updated case value
         //add fields you want to assert
        Test.stopTest();
        Case updatedCase = [SELECT Id,FCS_Team__c,FCS_Site__c,FCS_Vendor__c,FCS_VirtualOrganization__c FROM CASE WHERE id=:testCase.id]; 
	
        System.assertEquals(theUser.FCS_Team__c, updatedCase.FCS_Team__c); 
        System.assertEquals(theUser.FCS_Site__c, updatedCase.FCS_Site__c); 
        System.assertEquals(theUser.FCS_Vendor__c , updatedCase.FCS_Vendor__c); 
        System.assertEquals(theUser.FCS_VirtualOrganization__c, updatedCase.FCS_VirtualOrganization__c); 
          
    }

    @isTest
        //Create a Queue setCaseOwnerQueueTest
    static void setCaseOwnerQueueTest () {
       
        Group g  =[SELECT Id FROM Group WHERE Name = 'test group' LIMIT 1];
   
        //Set the owner of the case to be the Queue you created 
        Case testCase = new Case(OwnerId = g.Id);
                
        Test.startTest();
        //insert testCase; 
        insert testCase;
        //Do asserts and check if the fields in User are the same as updated case value
         //add fields you want to assert
        Test.stopTest();
        Case updatedCase = [SELECT Id,FCS_Team__c,FCS_Site__c,FCS_Vendor__c,FCS_VirtualOrganization__c FROM CASE WHERE id=:testCase.id]; 
		
        System.assertEquals(null, updatedCase.FCS_Team__c); 
        System.assertEquals(null, updatedCase.FCS_Site__c); 
        System.assertEquals(null , updatedCase.FCS_Vendor__c); 
        System.assertEquals(null, updatedCase.FCS_VirtualOrganization__c); 
        
    }
 }