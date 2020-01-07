/** 
    Test class testing daily batch service from scheduling 
    to running the batches.
*/
@isTest
global class SBS_ScheduledBatchService_Test {

    /**
        Tests running a successful batch
    */
    @isTest static void testSuccessfulBatch(){
        String timeSegment = 'testSuccessfulBatch';
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_SUCCESS,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_SUCCESS,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(0,sbrc.TotalErrors__c);
        System.assertEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(0,errList.size());
    }

    /**
        Tests running a successful batch using a batch without a finish method
    */
    @isTest static void testSuccessfulBatchVariant(){
        String timeSegment = 'testSuccessfulBatch';
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch2_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_SUCCESS,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_SUCCESS,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(0,sbrc.TotalErrors__c);
        System.assertEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(0,errList.size());
    }

    /**
        Tests running a batch which generates an exception
    */
    @isTest static void testExceptionBatch(){
        String timeSegment = 'testExceptionBatch';
        SBS_ScheduledBatch_Test.THROW_EXCEPTION = true;
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_FAIL,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(1,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(1,errList.size());
        SBS_ScheduledBatchRunTxnError__c err = errList[0];
        System.assertEquals('TEST EXCEPTION',err.ErrorMessage__c);
        System.assertNotEquals(null,err.Scope__c);
        System.assertNotEquals(null,err.StackTrace__c);
    }

    /**
        Tests running a batch which generates a custom error
    */
    @isTest static void testCustomErrorBatch(){
        String timeSegment = 'testCustomErrorBatch';
        SBS_ScheduledBatch_Test.CUSTOM_ERROR = true;
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_FAIL,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(1,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(1,errList.size());
        SBS_ScheduledBatchRunTxnError__c err = errList[0];
        System.assertEquals('ERROR MESSAGE',err.ErrorMessage__c);
        System.assertNotEquals(null,err.Scope__c);
        System.assertEquals(null,err.StackTrace__c);
    }


    /**
        Tests running a batch which generates an exception on init
    */
    @isTest static void testInitExceptionBatch(){
        String timeSegment = 'testInitExceptionBatch';
        SBS_ScheduledBatch_Test.THROW_INIT_EXCEPTION = true;
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_INIT_ERROR,sbrc.Status__c);
        System.assertEquals(null,sbrc.TotalBatches__c);
        System.assertEquals(null,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(0,errList.size());
    }

    /**
        Tests running a batch which generates an exception on finish
    */
    @isTest static void testFinishExceptionBatch(){
        String timeSegment = 'testFinishExceptionBatch';
        SBS_ScheduledBatch_Test.THROW_FINISH_EXCEPTION = true;
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_FAIL,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(0,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(0,errList.size());
    }


    /**
        Tests running a successful batch for a batch part of a group
    */
    @isTest static void testSuccessfulGroupBatch(){
        String timeSegment = 'testSuccessfulGroupBatch';
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G1'),
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH2',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G1')
        };
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList) ORDER BY RunOrder__c];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_SUCCESS,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(2,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_SUCCESS,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(0,sbrc.TotalErrors__c);
        System.assertEquals(null,sbrc.ErrorMessage__c);
        sbrc = sbrcList[1];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(2,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_SUCCESS,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(0,sbrc.TotalErrors__c);
        System.assertEquals(null,sbrc.ErrorMessage__c);


        System.assertEquals(0,errList.size());
    }

    /**
        Tests running a batch which generates an exception for a batch part of a group
    */
    @isTest static void testExceptionGroupBatch(){
        String timeSegment = 'testExceptionGroupBatch';
        SBS_ScheduledBatch_Test.THROW_EXCEPTION = true;
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G1'),
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH2',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G1')
        };
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList) ORDER BY RunOrder__c];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(2,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_FAIL,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(1,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);
        sbrc = sbrcList[1];
        System.assertEquals(null,sbrc.ApexJobId__c);
        System.assertEquals(null,sbrc.StartTime__c);
        System.assertEquals(null,sbrc.FinishTime__c);
        System.assertEquals(2,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_INIT_ERROR,sbrc.Status__c);
        System.assertEquals(null,sbrc.TotalBatches__c);
        System.assertEquals(null,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);


        System.assertEquals(1,errList.size());
    }

    /**
        Tests running a batch which generates an exception for a batch but is not part of the same group as the next batch
    */
    @isTest static void testExceptionNonGroupBatch(){
        String timeSegment = 'testExceptionNonGroupBatch';
        SBS_ScheduledBatch_Test.THROW_EXCEPTION = true;
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G1'),
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH2',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G2')
        };
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList) ORDER BY RunOrder__c];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(2,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_FAIL,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(1,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);
        sbrc = sbrcList[1];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(2,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_FAIL,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(1,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);


        System.assertEquals(2,errList.size());
    }


    /**
        Tests that the batch is included with day of week schedule
    */
    @isTest static void testDayOfWeekInclude(){
        String timeSegment = 'testDayOfWeekInclude';
        Test.startTest();
        //Batch scheduled for first working day starting with a friday (which is marked as a holiday)
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Date1',ActivityDate=Date.newInstance(2019,12,13),IsAllDay=true,IsRecurrence=false,RecurrenceDayOfMonth=null,RecurrenceDayOfWeekMask=null,RecurrenceStartDate=null,RecurrenceEndDateOnly=null,RecurrenceInstance=null,RecurrenceInterval=null,RecurrenceMonthOfYear=null,RecurrenceType=null)};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Week',DayOfWeek__c='5',WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,16);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(1,sbrcList.size());
    }

    /**
        Tests that the batch is excluded with day of week schedule
    */
    @isTest static void testDayOfWeekExclude(){
        String timeSegment = 'testDayOfWeekExclude';
        Test.startTest();
        //Batch scheduled for first working day starting with a friday (which is marked as a holiday)
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Date1',ActivityDate=Date.newInstance(2019,12,13),IsAllDay=true,IsRecurrence=false,RecurrenceDayOfMonth=null,RecurrenceDayOfWeekMask=null,RecurrenceStartDate=null,RecurrenceEndDateOnly=null,RecurrenceInstance=null,RecurrenceInterval=null,RecurrenceMonthOfYear=null,RecurrenceType=null)};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Week',DayOfWeek__c='5',WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,13);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(0,sbrcList.size());
    }


    /**
        Tests that the batch is included with day of month schedule
    */
    @isTest static void testDayOfMonthInclude(){
        String timeSegment = 'testDayOfMonthInclude';
        Test.startTest();
        //Batch scheduled for first working day starting with a friday (which is marked as a holiday)
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Date1',ActivityDate=Date.newInstance(2019,12,13),IsAllDay=true,IsRecurrence=false,RecurrenceDayOfMonth=null,RecurrenceDayOfWeekMask=null,RecurrenceStartDate=null,RecurrenceEndDateOnly=null,RecurrenceInstance=null,RecurrenceInterval=null,RecurrenceMonthOfYear=null,RecurrenceType=null)};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Month',DayOfWeek__c=null,DayOfMonth__c=13,WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,16);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(1,sbrcList.size());
    }

    /**
        Tests that the batch is excluded with day of month schedule
    */
    @isTest static void testDayOfMonthExclude(){
        String timeSegment = 'testDayOfMonthExclude';
        Test.startTest();
        //Batch scheduled for first working day starting with a friday (which is marked as a holiday)
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Date1',ActivityDate=Date.newInstance(2019,12,13),IsAllDay=true,IsRecurrence=false,RecurrenceDayOfMonth=null,RecurrenceDayOfWeekMask=null,RecurrenceStartDate=null,RecurrenceEndDateOnly=null,RecurrenceInstance=null,RecurrenceInterval=null,RecurrenceMonthOfYear=null,RecurrenceType=null)};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Month',DayOfWeek__c=null,DayOfMonth__c=13,WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,13);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(0,sbrcList.size());
    }

    /**
        Tests that the batch is included with day of year schedule
    */
    @isTest static void testDayOfYearInclude(){
        String timeSegment = 'testDayOfYearInclude';
        Test.startTest();
        //Batch scheduled for first working day starting with a friday (which is marked as a holiday)
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Date1',ActivityDate=Date.newInstance(2019,12,13),IsAllDay=true,IsRecurrence=false,RecurrenceDayOfMonth=null,RecurrenceDayOfWeekMask=null,RecurrenceStartDate=null,RecurrenceEndDateOnly=null,RecurrenceInstance=null,RecurrenceInterval=null,RecurrenceMonthOfYear=null,RecurrenceType=null)};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Year',DayOfWeek__c=null,DayOfMonth__c=13,MonthOfYear__c='12',WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,16);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(1,sbrcList.size());
    }

    /**
        Tests that the batch is excluded with day of year schedule
    */
    @isTest static void testDayOfYearExclude(){
        String timeSegment = 'testDayOfYearExclude';
        Test.startTest();
        //Batch scheduled for first working day starting with a friday (which is marked as a holiday)
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Date1',ActivityDate=Date.newInstance(2019,12,13),IsAllDay=true,IsRecurrence=false,RecurrenceDayOfMonth=null,RecurrenceDayOfWeekMask=null,RecurrenceStartDate=null,RecurrenceEndDateOnly=null,RecurrenceInstance=null,RecurrenceInterval=null,RecurrenceMonthOfYear=null,RecurrenceType=null)};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Year',DayOfWeek__c=null,DayOfMonth__c=13,MonthOfYear__c='12',WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,13);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(0,sbrcList.size());
    }


    /**
        Tests that the batch is included with last day of month schedule
    */
    @isTest static void testLastDayOfMonthInclude(){
        String timeSegment = 'testLastDayOfMonthInclude';
        Test.startTest();
        //Batch scheduled for last day of month in november which is a saturday
        C_CalendarUtil.holidayList = new Holiday[]{};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Last Day Of Month',DayOfWeek__c=null,DayOfMonth__c=null,MonthOfYear__c=null,WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,2);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(1,sbrcList.size());
    }

    /**
        Tests that the batch is excluded with last day of month schedule
    */
    @isTest static void testLastDayOfMonthExclude(){
        String timeSegment = 'testLastDayOfMonthExclude';
        Test.startTest();
        //Batch scheduled for last day of month in november which is a saturday
        C_CalendarUtil.holidayList = new Holiday[]{};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Last Day Of Month',DayOfWeek__c=null,DayOfMonth__c=null,MonthOfYear__c=null,WorkingDayOffset__c='1',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,11,30);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(0,sbrcList.size());
    }

    /**
        Tests that the batch is should only run during working days is included
    */
    @isTest static void testOnlyWorkingDaysInclude(){
        String timeSegment = 'testOnlyWorkingDaysInclude';
        Test.startTest();
        C_CalendarUtil.holidayList = new Holiday[]{};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',DayOfWeek__c=null,DayOfMonth__c=null,MonthOfYear__c=null,OnlyExecuteOnWorkingDays__c=true,ScopeSize__c=200,Priority__c=1)};
        //A monday
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,16);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(1,sbrcList.size());
    }

    /**
        Tests that the batch is should only run during working days is excluded
    */
    @isTest static void testOnlyWorkingDaysExclude(){
        String timeSegment = 'testOnlyWorkingDaysExclude';
        Test.startTest();
        C_CalendarUtil.holidayList = new Holiday[]{};
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',DayOfWeek__c=null,DayOfMonth__c=null,MonthOfYear__c=null,OnlyExecuteOnWorkingDays__c=true,ScopeSize__c=200,Priority__c=1)};
        //A sunday
        SBS_ScheduledBatchService.CURRENT_DATE_OVERRIDE = Date.newInstance(2019,12,15);
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        System.assertEquals(0,sbrcList.size());
    }

    /**
        Tests that having a batch with bad configuration causes only the poorly configured batch to fail
    */
    @isTest static void testBadConfiguration(){
        String timeSegment = 'testBadConfiguration';
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Day Of Week',DayOfWeek__c='BAD VALUE',ScopeSize__c=200,Priority__c=1,Group__c='G1'),
            new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH2',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1,Group__c='G2')
        };
        SBS_ScheduledBatchService.run(timeSegment);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList) ORDER BY RunOrder__c];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_STATUS_FAIL,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertNotEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(2,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertEquals(null,sbrc.ApexJobId__c);
        System.assertEquals(null,sbrc.StartTime__c);
        System.assertEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_INIT_ERROR,sbrc.Status__c);
        System.assertEquals(null,sbrc.TotalBatches__c);
        System.assertEquals(null,sbrc.TotalErrors__c);
        System.assertNotEquals(null,sbrc.ErrorMessage__c);
        sbrc = sbrcList[1];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertNotEquals(null,sbrc.FinishTime__c);
        System.assertEquals(2,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_SUCCESS,sbrc.Status__c);
        System.assertEquals(1,sbrc.TotalBatches__c);
        System.assertEquals(0,sbrc.TotalErrors__c);
        System.assertEquals(null,sbrc.ErrorMessage__c);


        System.assertEquals(0,errList.size());
    }

    /**
        Tests creating a successful batch run defined using code
    */
    @isTest static void testDynamicBatchSuccess(){
        Test.startTest();
        List<SBS_ScheduledBatchService.BatchExecution> batches = new List<SBS_ScheduledBatchService.BatchExecution>();
		batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
		batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
		SBS_ScheduledBatchService.ScheduledBatchRun sbr = new SBS_ScheduledBatchService.ScheduledBatchRun(batches);
		SBS_ScheduledBatchService.run(sbr);
        Test.stopTest();
        System.assertEquals(2,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(2,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(2,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests batch run defined using code with an exception
    */
    @isTest static void testDynamicBatchException(){
        SBS_ScheduledBatch_Test.THROW_EXCEPTION = true;
        Boolean error = false;
        try{
            Test.startTest();
            List<SBS_ScheduledBatchService.BatchExecution> batches = new List<SBS_ScheduledBatchService.BatchExecution>();
            batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
            batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
            SBS_ScheduledBatchService.ScheduledBatchRun sbr = new SBS_ScheduledBatchService.ScheduledBatchRun(batches);
            SBS_ScheduledBatchService.run(sbr);
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        //Real error will run all batches but test logic causes the exception to stop the processing
        System.assertEquals(true,error);
        System.assertEquals(1,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(0,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests batch run defined using code with a custom error
    */
    @isTest static void testDynamicBatchCustomError(){
        SBS_ScheduledBatch_Test.CUSTOM_ERROR = true;
        Boolean error = false;
        try{
            Test.startTest();
            List<SBS_ScheduledBatchService.BatchExecution> batches = new List<SBS_ScheduledBatchService.BatchExecution>();
            batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
            batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
            SBS_ScheduledBatchService.ScheduledBatchRun sbr = new SBS_ScheduledBatchService.ScheduledBatchRun(batches);
            SBS_ScheduledBatchService.run(sbr);
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        //Real error will run all batches but test logic causes the exception to stop the processing
        System.assertEquals(true,error);
        System.assertEquals(1,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(0,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests batch run defined using code with an exception in the finish method
    */
    @isTest static void testDynamicBatchFinishException(){
        SBS_ScheduledBatch_Test.THROW_FINISH_EXCEPTION = true;
        Boolean error = false;
        try{
            Test.startTest();
            List<SBS_ScheduledBatchService.BatchExecution> batches = new List<SBS_ScheduledBatchService.BatchExecution>();
            batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
            batches.add(new SBS_ScheduledBatchService.BatchExecution(SBS_ScheduledBatch_Test.class,200,null));
            SBS_ScheduledBatchService.ScheduledBatchRun sbr = new SBS_ScheduledBatchService.ScheduledBatchRun(batches);
            SBS_ScheduledBatchService.run(sbr);
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        System.assertEquals(false,error);
        System.assertEquals(2,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(2,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(2,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests running a batch outside of scheduled batch service
    */
    @isTest static void testExternalBatchRunSuccess(){
        Boolean error = false;
        try{
            Test.startTest();
            SBS_ScheduledBatch_Test.DISABLE_TRANSACTION_CONTROL = true;
            Database.executeBatch(new SBS_ScheduledBatch_Test());
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        System.assertEquals(false,error);
        System.assertEquals(1,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }


    /**
        Tests running a batch outside of scheduled batch service with an execute exception
    */
    @isTest static void testExternalBatchRunException(){
        Boolean error = false;
        try{
            Test.startTest();
            SBS_ScheduledBatch_Test.DISABLE_TRANSACTION_CONTROL = true;
            SBS_ScheduledBatch_Test.THROW_EXCEPTION = true;
            Database.executeBatch(new SBS_ScheduledBatch_Test());
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        System.assertEquals(true,error);
        System.assertEquals(1,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(0,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests running a batch outside of scheduled batch service with a custom error
    */
    @isTest static void testExternalBatchRunCustomError(){
        Boolean error = false;
        try{
            Test.startTest();
            SBS_ScheduledBatch_Test.DISABLE_TRANSACTION_CONTROL = true;
            SBS_ScheduledBatch_Test.CUSTOM_ERROR = true;
            Database.executeBatch(new SBS_ScheduledBatch_Test());
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        System.assertEquals(true,error);
        System.assertEquals(1,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(0,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests running a batch outside of scheduled batch service with an finish exception
    */
    @isTest static void testExternalBatchRunFinishException(){
        Boolean error = false;
        try{
            Test.startTest();
            SBS_ScheduledBatch_Test.DISABLE_TRANSACTION_CONTROL = true;
            SBS_ScheduledBatch_Test.THROW_FINISH_EXCEPTION = true;
            Database.executeBatch(new SBS_ScheduledBatch_Test());
            Test.stopTest();
        }
        catch(Exception e){
            error = true;
        }
        System.assertEquals(true,error);
        System.assertEquals(1,SBS_ScheduledBatch_Test.START_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.EXECUTE_COUNT);
        System.assertEquals(1,SBS_ScheduledBatch_Test.FINISH_COUNT);
    }

    /**
        Tests that the batch can be correctly initated using the scheduleable job
        Note: Testing a scheduleable job which schedules a batch does not execute a batch
        This is in contrast to batch chaining in tests which execute the cahined batch as well
    */
    @isTest static void testSchedulableJob(){
        String timeSegment = 'testSchedulableJob';
        Test.startTest();
        SBS_ScheduledBatchService.BATCH_CMP_LIST_OVERRIDE = new SBS_ScheduledBatchComponent__mdt[]{new SBS_ScheduledBatchComponent__mdt(DeveloperName='TEST_BATCH',Class__c='SBS_ScheduledBatch_Test',Schedule__c='Daily',ScopeSize__c=200,Priority__c=1)};
        SBS_ScheduledBatchService_Schedulable s = new SBS_ScheduledBatchService_Schedulable(timeSegment);
        System.schedule('TEST SCHEDULED BATCH SERVICE', '0 0 0 * * ?', s);
        Test.stopTest();

        SBS_ScheduledBatchRun__c[] sbrList = [SELECT Id,Status__c,StartTime__c,FinishTime__c,TimeSegment__c FROM SBS_ScheduledBatchRun__c];
        SBS_ScheduledBatchRunComponent__c[] sbrcList = [SELECT Id,ApexJobId__c,RunOrder__c,StartTime__c,FinishTime__c,Status__c,TotalBatches__c,TotalErrors__c,ErrorMessage__c FROM SBS_ScheduledBatchRunComponent__c WHERE ScheduledBatchRun__c IN :getIds(sbrList)];
        SBS_ScheduledBatchRunTxnError__c[] errList = [SELECT Id,ErrorMessage__c,Scope__c,StackTrace__c FROM SBS_ScheduledBatchRunTxnError__c WHERE ScheduledBatchRunComponent__c IN :getIds(sbrcList)];

        System.assertEquals(1,sbrList.size());
        SBS_ScheduledBatchRun__c sbr = sbrList[0];
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_STARTED,sbr.Status__c);
        System.assertNotEquals(null,sbr.StartTime__c);
        System.assertEquals(null,sbr.FinishTime__c);
        System.assertEquals(timeSegment,sbr.TimeSegment__c);

        System.assertEquals(1,sbrcList.size());
        SBS_ScheduledBatchRunComponent__c sbrc = sbrcList[0];
        System.assertNotEquals(null,sbrc.ApexJobId__c);
        System.assertNotEquals(null,sbrc.StartTime__c);
        System.assertEquals(null,sbrc.FinishTime__c);
        System.assertEquals(1,sbrc.RunOrder__c);
        System.assertEquals(SBS_ScheduledBatchService.BATCH_RUN_CMP_STATUS_STARTED,sbrc.Status__c);
        System.assertEquals(null,sbrc.TotalBatches__c);
        System.assertEquals(null,sbrc.TotalErrors__c);
        System.assertEquals(null,sbrc.ErrorMessage__c);

        System.assertEquals(0,errList.size());
    }

    /**
        Retrieves the set of ids for the provided list of sobjects
        @param sObjList The list of SObjects from which to extract the ids
        @return The set of ids
    */
    private static Set<Id> getIds(SObject[] sObjList){
        Set<Id> idSet = new Set<Id>();
        for(SObject so : sObjList)idSet.add(so.Id);
        return idSet;
    }
}
