global class MigrateCaseTagsBatch extends SBS_ScheduledBatch {
  public String caseOrigin;
  public String caseDepartment;
  public String caseRecordType;
  
  public Map<String,OldCaseTagtoNewCaseTags__c> mapOldToNewCaseTags;
  
  global MigrateCaseTagsBatch ( String cseOrigin, String cseDepartment, String cseRecordType) {
   mapOldToNewCaseTags = new Map<String,OldCaseTagtoNewCaseTags__c>();
   List<OldCaseTagtoNewCaseTags__c> lstOldcaseTags = OldCaseTagtoNewCaseTags__c.getall().values();
   for(OldCaseTagtoNewCaseTags__c cussetting :lstOldcaseTags  )
   {
     String key;
     if(cussetting.Old_Case_Sub_Reason__c!='' && cussetting.Old_Case_Sub_Reason__c!=null)
     {
         key = cussetting.Old_Case_Reason__c+'@'+cussetting.Old_Case_Sub_Reason__c;
     }
     else
     {
       key = cussetting.Old_Case_Reason__c;
     }
     
     if(mapOldToNewCaseTags.containsKey(key))
     {
       // nothing
     }
     else
     {
       mapOldToNewCaseTags.put(key,cussetting);   
     }
   }
    caseOrigin = cseOrigin;
    caseDepartment = cseDepartment;
    caseRecordType = cseRecordType;
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'Select Id,FCS_CaseReason__c,FCS_CaseSubReason__c,FCS_Case_Reason__c,FCS_CaseType__c FROM Case where Origin = :caseOrigin and Department__c = :caseDepartment and RecordType.Name =:caseRecordType and FCS_Case_Reason__c=null and FCS_CaseReason__c!=null LIMIT 10000'
    );
  }

  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    List<Case> lstcase = (List<Case>) sObjScope;
    for (Case cse : lstcase) {
     if(cse.FCS_CaseReason__c!='' && cse.FCS_CaseReason__c!=null)
     { string key;
        if(cse.FCS_CaseSubReason__c!='' && cse.FCS_CaseSubReason__c!=null)
        {
         key = cse.FCS_CaseReason__c+'@'+cse.FCS_CaseSubReason__c;
        }
        else
        {
          key = cse.FCS_CaseReason__c;
        }
          System.debug('key***'+key);
          cse.FCS_Case_Reason__c =mapOldToNewCaseTags.get(key).New_Case_Reason__c;
          cse.FCS_CaseType__c = mapOldToNewCaseTags.get(key).New_Case_Type__c;
          
        if(mapOldToNewCaseTags.get(key).New_Case_Reason__c == 'Other')
        {
        
          
          cse.FCS_CaseResolutionDetails__c = mapOldToNewCaseTags.get(key).Old_Case_Sub_Reason__c;
        
        }
     }
   }
    update lstcase;
  }
}