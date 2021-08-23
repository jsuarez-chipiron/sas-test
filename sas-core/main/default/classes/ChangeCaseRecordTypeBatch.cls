global class ChangeCaseRecordTypeBatch extends SBS_ScheduledBatch {
  public String caseOrigin;
  public List<String> caseRecordTypes;

  global ChangeCaseRecordTypeBatch(
    String cseOrigin,
    List<String> cseRecordTypes
  ) {
    caseRecordTypes = cseRecordTypes;
    caseOrigin = cseOrigin;
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'Select Id, Department__c,Origin,RecordTypeId,Team__c FROM Case where Origin = :caseOrigin and RecordType.Name =:caseRecordTypes'
    );
  }

  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    List<Case> lstcase = (List<Case>) sObjScope;
    for (Case cse : lstcase) {
      if (cse.origin == 'Chat') {
        cse.Department__c = 'SoMe Support';
        cse.Team__c = 'Chat';
        cse.RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
      }
      if (cse.origin == 'Facebook Messenger') {
        cse.Department__c = 'SoMe Support';
        cse.Team__c = 'Facebook Messenger';
        cse.RecordTypeId = C_RecordTypeHelper.CASE_CHAT;
      }
      if (cse.origin == 'Facebook' || cse.origin == 'Twitter') {
        cse.Department__c = 'SoMe Support';
        cse.Team__c = 'SoMe';
        cse.RecordTypeId = C_RecordTypeHelper.CASE_CHANNEL;
      }
    }

    update lstcase;
  }
}
