/**
Extensible class used to wipe the of interactions
The batch processes interactions which are not associated to a case
and ensures that wiping period should greate than Case wiping.
*/
global class GDPR_WipeInteraction_Batch extends SBS_ScheduledBatch{
    /**
The sobject name of the interaction sobject
*/
    private String sObjectName;
    /**
The field which links the interaction with a case and thus should be excluded
*/
    private String caseField;
    /**
The date till which interaction will be retained with wiping.
*/
    private DateTime lastRetentionDate;
    /**
The list of fields needs to be wiped for batch job Object
*/
    private List<String> lstFieldsToClear;
    
    global GDPR_WipeInteraction_Batch(){
        
    }
    /**
Overiding of the abstract method used to set the Batch class params
*/
    global override void setVariables(String SObj, Integer wipingPeriod, string caseField, string caseType, string relSObjField, string relSobjName )
    {
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(2),Time.newInstance(0,0,0,0));
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(SObj);
        this.sObjectName = sot+'';
        this.caseField = caseField!=null ? caseField+'' : null;
        lstFieldsToClear = GDPR_Util.getCaseFieldsToClear(this.sObjectName); 
    }
    
    /**
Iterates over all interactions to be processed
@param bc The batch context
*/
    global Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id, CreatedDate';
        q+=' FROM '+sObjectName+' WHERE ';
        q = caseField!=null ? q+caseField+'=null' : q;
        q+=' AND createddate<:lastRetentionDate';
        System.debug('SoqlQuery****'+q);
        return Database.getQueryLocator(q);
    }
    
    /**
wipe the interactions of the Channel object records without case
@param bc The batchable context of the batch job
@param sObjScope The interactions to delete
*/
    global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){    
        
        List<SObject> lstSobjects = GDPR_Util.createSobjectFieldsToClear(sObjScope, sObjectName); 
        
        update lstSobjects ; 
        
    }
}