/**
Extensible class used to wipe the deletion of interactions
The batch processes interactions which are not associated to a case
and ensures that wiping period should greate than Case wiping.
*/
global class GDPR_DeleteInteraction_Batch extends SBS_ScheduledBatch{
    /**
The sobject name of the interaction sobject
*/
    private String sObjectName;
    /**
The field which links the interaction with a case and thus should be excluded
*/
    private String caseField;
    /**
SObject name of related SObject which should be removed as well
*/
    
    private String relSObjName;
    /**
The field on the primary obejct which links the primary object to the parent object
*/
    private String relSObjField; 
    /**
The date until which to retain the record related to specified sobject
*/
    private DateTime lastRetentionDate;
    
    global GDPR_DeleteInteraction_Batch(){
    }
    
    /**
Overiding of the abstract method used to set the Batch class params
*/
    global override void setVariables(String sObj, Integer wipingPeriod, string caseField,String caseType, string relSObjField, string relSobjName)
    {
        lastRetentionDate = DateTime.newInstance(Date.today().addDays(-wipingPeriod),Time.newInstance(0,0,0,0));
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(sObj);
        this.sObjectName = sot+'';
        this.caseField = caseField!=null ? caseField+'' : null;
        this.relSObjName = relSObjName;
        this.relSObjField = relSObjField ;
    }
    
    /**
Iterates over all interactions to be processed
@param bc The batch context
*/
    global Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id, CreatedDate, ';
        q = relSObjField!=null ? q+relSObjField: q;
        q+=' FROM '+sObjectName+' WHERE ';
        q = caseField!=null ? q+caseField+'=null' : q;
        if(sObjectName=='Booking__c')
        {
          q+=' AND LastModifiedDate<:lastRetentionDate';
        }
        else
        {
          q+=' AND createddate<:lastRetentionDate';
        }
        return Database.getQueryLocator(q);
        
    }
    
    /**
Deletes the interactions which should be deleted according to the retention logic
@param bc The batchable context of the batch job
@param sObjScope The interactions to delete
*/
    global override void executeScope(Database.BatchableContext bc, SObject[] sObjScope){
          Set<Id> relIds = new Set<Id>();
          for(SObject sObj : sObjScope)
          {
              if(relSObjField!=null){
                    Id relId = (Id)sObj.get(relSObjField);
                    if(relId!=null)relIds.add(relId);
                }
          }
          delete sObjScope;
          
        if(!relIds.isEmpty()){
            SObject[] relRecs = Database.query('SELECT Id FROM '+relSObjName+' WHERE Id IN :relIds AND Id NOT IN (SELECT '+relSObjField+' FROM '+sObjectName+' WHERE '+relSObjField+' IN :relIds)');
            delete relRecs;
        }
        
        
    }
}