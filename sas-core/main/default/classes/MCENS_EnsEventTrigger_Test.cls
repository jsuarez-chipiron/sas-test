/**
 * Test class for the platform event handling of the ENS events
 * @author Peter Södergren
 */
@isTest
private class MCENS_EnsEventTrigger_Test {
    /**
     * Creates communication log data used in the test
     */
    @testSetup static void setup(){
        IRR_CommunicationLog__c[] comLog = new IRR_CommunicationLog__c[]{
            new IRR_CommunicationLog__c(IRR_MessageKey__c='MCENS_EnsEventTrigger_Test_1',IRR_Status__c='Created'),
            new IRR_CommunicationLog__c(IRR_MessageKey__c='MCENS_EnsEventTrigger_Test_2',IRR_Status__c='Created'),
            new IRR_CommunicationLog__c(IRR_MessageKey__c='MCENS_EnsEventTrigger_Test_3',IRR_Status__c='Created'),
            new IRR_CommunicationLog__c(IRR_MessageKey__c='MCENS_EnsEventTrigger_Test_4',IRR_Status__c='Created'),
            new IRR_CommunicationLog__c(IRR_MessageKey__c='MCENS_EnsEventTrigger_Test_5',IRR_Status__c='Created')
        };
        insert comLog;
    }
    /**
     * Test processing all the different types of events
     */
    @isTest static void processEvents(){
        EventCreator ec = new EventCreator();
        List<MCENS_EnsEvent__e> evtList = new List<MCENS_EnsEvent__e>();
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_1","status":"Sent"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailNotSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_2","statusCode":"1234","statusMessage":"ERRORMESSAGE","reason":"ERRORREASON"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailBounced','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_3","bounceCode":"4321","bounceMessage":"BOUNCEMESSAGE","smtpReason":"SMTPREASON"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_4"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsNotSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_5","reason":"ERRORREASON","statusCode":"47"}'));
        MCENS_EnsEventTriggerHandler h = new MCENS_EnsEventTriggerHandler(evtList,0,null);
        h.run();
        System.assertEquals('5',h.getLastReplayId());
        StatusAsserter sa = new StatusAsserter();
        sa.assert('MCENS_EnsEventTrigger_Test_1', 'Sent', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_2', 'Error', 1234, 'ERRORMESSAGE', 'ERRORREASON');
        sa.assert('MCENS_EnsEventTrigger_Test_3', 'Bounced', 4321, 'BOUNCEMESSAGE', 'SMTPREASON');
        sa.assert('MCENS_EnsEventTrigger_Test_4', 'Sent', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_5', 'Error', 47, null, 'ERRORREASON');

    }
    /**
     * Tests behaviour where the event cannot be found but found at a later point in time
     * Tests that only the initial scope is being reprocessed
     */
    @isTest static void eventNotFoundSuccess(){
        EventCreator ec = new EventCreator();
        List<MCENS_EnsEvent__e> evtList = new List<MCENS_EnsEvent__e>();
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_FAIL","status":"Sent"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailNotSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_2","statusCode":"1234","statusMessage":"ERRORMESSAGE","reason":"ERRORREASON"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailBounced','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_3","bounceCode":"4321","bounceMessage":"BOUNCEMESSAGE","smtpReason":"SMTPREASON"}'));
        String errMsg;
        try{
            MCENS_EnsEventTriggerHandler h = new MCENS_EnsEventTriggerHandler(evtList,0,null);
            h.run();
        }
        catch(EventBus.RetryableException re){
            errMsg = re.getMessage();
        }
        System.assertNotEquals(null, errMsg);
        StatusAsserter sa = new StatusAsserter();
        sa.assert('MCENS_EnsEventTrigger_Test_1', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_2', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_3', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_4', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_5', 'Created', null, null, null);



        evtList[0] = ec.create(true,'TransactionalSendEvents.EmailSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_1","status":"Sent"}');
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_4"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsNotSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_5","reason":"ERRORREASON","statusCode":"47"}'));
        try{
            MCENS_EnsEventTriggerHandler h = new MCENS_EnsEventTriggerHandler(evtList,1,errMsg);
            errMsg = null;
            h.run();
            System.assertEquals('3',h.getLastReplayId());
        }
        catch(EventBus.RetryableException re){
            errMsg = re.getMessage();
        }
        System.assertEquals(null, errMsg);
        
        sa = new StatusAsserter();
        sa.assert('MCENS_EnsEventTrigger_Test_1', 'Sent', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_2', 'Error', 1234, 'ERRORMESSAGE', 'ERRORREASON');
        sa.assert('MCENS_EnsEventTrigger_Test_3', 'Bounced', 4321, 'BOUNCEMESSAGE', 'SMTPREASON');
        sa.assert('MCENS_EnsEventTrigger_Test_4', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_5', 'Created', null, null, null);
        
    }
    /**
     * Tests event not found and not being found at a later point
     * Tests that only the initial scope is being reprocessed
     */
    @isTest static void eventNotFoundFail(){
        EventCreator ec = new EventCreator();
        List<MCENS_EnsEvent__e> evtList = new List<MCENS_EnsEvent__e>();
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_1","status":"Sent"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailNotSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_2","statusCode":"1234","statusMessage":"ERRORMESSAGE","reason":"ERRORREASON"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailBounced','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_FAIL","bounceCode":"4321","bounceMessage":"BOUNCEMESSAGE","smtpReason":"SMTPREASON"}'));
        String errMsg;
        try{
            MCENS_EnsEventTriggerHandler h = new MCENS_EnsEventTriggerHandler(evtList,0,null);
            h.run();
        }
        catch(EventBus.RetryableException re){
            errMsg = re.getMessage();
        }
        System.assertNotEquals(null, errMsg);
        StatusAsserter sa = new StatusAsserter();
        sa.assert('MCENS_EnsEventTrigger_Test_1', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_2', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_3', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_4', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_5', 'Created', null, null, null);

        evtList.add(ec.create(true,'TransactionalSendEvents.SmsSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_4"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsNotSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_5","reason":"ERRORREASON","statusCode":"47"}'));
        Long newTs = DateTime.now().addMinutes(-4).getTime();
        evtList[0].Timestamp__c = newTs;
        evtList[1].Timestamp__c = newTs;
        evtList[2].Timestamp__c = newTs;
        evtList[3].Timestamp__c = newTs;
        evtList[4].Timestamp__c = newTs;

        try{
            MCENS_EnsEventTriggerHandler h = new MCENS_EnsEventTriggerHandler(evtList,5,errMsg);
            errMsg = null;
            h.run();
            System.assertEquals('3',h.getLastReplayId());
        }
        catch(EventBus.RetryableException re){
            errMsg = re.getMessage();
        }
        System.assertEquals(null, errMsg);
        
        sa = new StatusAsserter();
        sa.assert('MCENS_EnsEventTrigger_Test_1', 'Sent', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_2', 'Error', 1234, 'ERRORMESSAGE', 'ERRORREASON');
        sa.assert('MCENS_EnsEventTrigger_Test_3', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_4', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_5', 'Created', null, null, null);

        System.assertEquals(1,[SELECT Id FROM C_Log__c WHERE Severity__c='Warning' AND LogGroup__c='MCENS'].size());
    }

    /**
     * Tests running the event through the actual event bus to test the full solution
     */
    @isTest static void testEventBus(){
        EventCreator ec = new EventCreator();
        ec.timestamp = DateTime.now().addMinutes(-4).getTime();
        List<MCENS_EnsEvent__e> evtList = new List<MCENS_EnsEvent__e>();
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_1","status":"Sent"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailNotSent','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_FAIL","statusCode":"1234","statusMessage":"ERRORMESSAGE","reason":"ERRORREASON"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.EmailBounced','{"to":"test@test.com.invalid","subscriberKey":"test@test.com.invalid","messageKey":"MCENS_EnsEventTrigger_Test_3","bounceCode":"4321","bounceMessage":"BOUNCEMESSAGE","smtpReason":"SMTPREASON"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_4"}'));
        evtList.add(ec.create(true,'TransactionalSendEvents.SmsNotSent','{"to":"46700000000","subscriberKey":"46700000000","messageKey":"MCENS_EnsEventTrigger_Test_5","reason":"ERRORREASON","statusCode":"47"}'));
        Test.startTest();
        Eventbus.publish(evtList);
        Test.getEventBus().deliver();
        Test.getEventBus().deliver();
        Test.getEventBus().deliver();
        Test.getEventBus().deliver();
        Test.getEventBus().deliver();
        Test.stopTest();
        StatusAsserter sa = new StatusAsserter();
        sa.assert('MCENS_EnsEventTrigger_Test_1', 'Sent', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_2', 'Created', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_3', 'Bounced', 4321, 'BOUNCEMESSAGE', 'SMTPREASON');
        sa.assert('MCENS_EnsEventTrigger_Test_4', 'Sent', null, null, null);
        sa.assert('MCENS_EnsEventTrigger_Test_5', 'Error', 47, null, 'ERRORREASON');

        System.assertEquals(1,[SELECT Id FROM C_Log__c WHERE Severity__c='Warning' AND LogGroup__c='MCENS'].size());
    }

    /**
     * Utility class to create ENS platform events
     */
    class EventCreator{
        /**
         * The creation date of the event
         */
        DateTime createdDate = DateTime.now();
        /**
         * Auto incremented replay id
         */
        Integer replayId = 1;
        /**
         * The composite id of the event from the ENS
         */
        String compositeId = '1.2.3.4';
        /**
         * The key of the definition to which the event relates
         */
        String definitionKey = '123456';
        /**
         * The enterprise id in MC of the enterprise which generated the event
         */
        Integer eid = 111111;
        /**
         * The mid in MC of the business unit which generated the event
         */
        Integer mid = 222222;
        /**
         * The timestamp of the event
         */
        Long timestamp = createdDate.getTime();


        /**
         * Creates the platform event
         * @param includeSystemFields Whether system fields should be set for the event
         * @param type The type of the event
         * @param info The info structure string 
         * @return The ENS Platform event record
         */
        MCENS_EnsEvent__e create(Boolean includeSystemFields, String type, String info){
            MCENS_EnsEvent__e e = includeSystemFields ? ((MCENS_EnsEvent__e)JSON.deserialize('{"CreatedDate":'+JSON.serialize(createdDate)+',"ReplayId":'+replayId+'}',MCENS_EnsEvent__e.class)) : new MCENS_EnsEvent__e();
            if(includeSystemFields)replayId++;
            e.CompositeId__c = compositeId;
            e.DefinitionKey__c = definitionKey;
            e.EId__c = eid;
            e.MId__c = mid;
            e.Timestamp__c = timestamp;
            e.Type__c = type;
            e.Info__c = info;
            return e;
        }
    }
    /**
     * Utility class to assert the status of communication logs
     */
    class StatusAsserter{
        /**
         * THe map of communication logs by message key
         */
        Map<String,IRR_CommunicationLog__c> comLogMap;
        /**
         * Loads all communication logs
         */
        StatusAsserter(){
            comLogMap = new Map<String,IRR_CommunicationLog__c>();
            IRR_CommunicationLog__c[] comLogList = [SELECT Id,IRR_MessageKey__c,IRR_Status__c,IRR_StatusCode__c,IRR_ErrorMessage__c,IRR_ErrorReason__c FROM IRR_CommunicationLog__c];
            for(IRR_CommunicationLog__c comLog : comLogList){
                comLogMap.put(comLog.IRR_MessageKey__c,comLog);
            }
        }
        /**
         * Asserts that the communication log with the supplied message key has the supplied properties
         * @param msgKey The message key of the communication log to check
         * @param status The status which the communication log record should have
         * @param statusCode The status code which the communication log record should have
         * @param errMsg The error message which the communication log record should have
         * @param errReason The error reason which the communication log record should have
         */
        void assert(String msgKey,String status,Integer statusCode,String errMsg,String errReason){
            IRR_CommunicationLog__c comLog = comLogMap.get(msgKey);
            System.assertNotEquals(null, comLog);
            System.assertEquals(status, comLog.IRR_Status__c);
            System.assertEquals(statusCode, comLog.IRR_StatusCode__c);
            System.assertEquals(errMsg, comLog.IRR_ErrorMessage__c);
            System.assertEquals(errReason, comLog.IRR_ErrorReason__c);
        }
    }
}
