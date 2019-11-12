/**
    Test method for the process Case Set priority Urgent that sets the priority 
    to urgent based on input from customer in Subject field. 
    @author Josephine Ding - Deloitte
*/
@isTest 
private class CaseSetPriorityUrgent_Test { 

    /**
    Set up the STOPQ-Escalation Queue
     */
    @testSetup static void setup() {
        // Create common test accounts
        Group g1 = new Group(Name='STOPQ Escalations', type='Queue');
        insert g1;
        QueueSObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;     
    }

    /**
        Test creating a Case as it would be created via Email-To-Case to the STOPQ Escalation-Queue. 
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

    
 }

