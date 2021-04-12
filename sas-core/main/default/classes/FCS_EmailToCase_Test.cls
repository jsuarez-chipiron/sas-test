/**
    Test method for the process Case Set priority Urgent that sets the priority 
    to urgent based on input from customer in Subject field or if Email is Flagged as important. 
*/
@isTest 
private class FCS_EmailToCase_Test { 

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
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
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
        List<Case> cases = FCS_TestDataFactory.createCases(1, null, null, C_RecordTypeHelper.CASE_INTERNAL_BACKOFFICE, null);
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
 }