/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description Handler class for operations performed on case object.
 */


public class CaseHandler extends C_TriggerHandler {

    private static final String MAIN_TAG = 'Main';
    private static final String SUB_MAIN_TAG = 'Sub';
    private static final String ADDITIONAL_TAG = 'Additional';

    /**
    Trigger variables
    */
    private Map<Id, Case> newCaseMap;
    private List<Case> newCaseList;
    private Map<Id, Case> oldCaseMap;
    private List<Case> oldCaseList;

    /**
   Set variables
   */
    public CaseHandler() {
        this.newCaseMap = (Map<Id, Case>) Trigger.newMap;
        this.newCaseList = (List <Case>) Trigger.new;
        this.oldCaseMap = (Map<Id, Case>) Trigger.oldMap;
        this.oldCaseList = (List <Case>) Trigger.old;
    }


    /**
   Used to call the trigger in the before insert context
   */
    public override void beforeInsert() {
        AssignOwnerFromSoMe(newCaseList);

    }

    /**
   Used to call the trigger in the after insert context
   */
    public override void afterInsert() {
        ManageCaseTagRecords(newCaseMap, oldCaseMap);

    }


    /**
    Used to call the trigger in the after update context
    */
    public override void afterUpdate() {
        ManageCaseTagRecords(newCaseMap, oldCaseMap);

    }

    /**
    Method to set owner (Global Support SoMe) on case created from SoMe-posts
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void AssignOwnerFromSoMe(List<Case> newCaseList) {
        for (Case c : newCaseList) {
            //Route cases created from Social Posts to GlobalSupportSoMe-queue
            system.debug(c.SourceId);
            if ((c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && String.valueOf(c.SourceId).startsWith('0ST'))) {
                try {
                    List<Group> SoMeQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'GlobalSupportSoMe'];
                    c.OwnerId = SoMeQueue[0].Id;
                } catch (Exception e) {
                    System.debug('An exception occurred: ' + e.getMessage());
                    C_log.logexception(e, null, null);

                }
            }
        }
    }

    /**
     * Creates/updates/delete case tag records when tags (Case Reason, Case SubReason or Case Tag) is updated on case
     * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
     * @param oldCaseMap The map between the id and the old version of the case i.e. the Trigger.oldMap variable
     */
    private static void ManageCaseTagRecords(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap) {
        try {

            // Map with existing case tag records and CaseId+Tag+Type as key
            Map<String, CaseTag__c> oldTagByKeyId = createCaseTagMap(newCaseMap);

            // Map with current tags on case with CaseId+Tag+Type as key
            Map<String, CaseTag__c> newTagByKeyId = createCaseMap(newCaseMap, oldCaseMap);

            // List to put current case tag records that should be deleted
            List<CaseTag__c> deleteCaseTags = new List<CaseTag__c>();

            // List to put case tag records that should be created
            List<CaseTag__c> createCaseTags = new List<CaseTag__c>();

            // Loop over new/updated tags on case and compare with tags in case tag records
            for (String keyId : newTagByKeyId.keySet()) {
                if (oldTagByKeyId.containsKey(keyId)) oldTagByKeyId.remove(keyId);
                if (!oldTagByKeyId.containsKey(keyId)) createCaseTags.add(newTagByKeyId.get(keyId));
            }

            //Delete old tags not included in newTagByKeyId map
            deleteCaseTags = oldTagByKeyId.values();

            if (createCaseTags != null) upsert createCaseTags;
            if (deleteCaseTags != null) delete deleteCaseTags;
        }
            catch (Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
            C_log.logexception(e, null, null);

        }

    }

    /**
    * Returns a map containing the current (old) case tags records that needs to be evaluate agianst the new version of the case, CaseId+CaseTag+Type as key
    * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
    * @return caseTagsByKeyId Map with existing case tag records (CaseTag__c) with CaseId+Tag+Type as key
    */
public static Map<String, CaseTag__c> createCaseTagMap(Map<Id, Case> newCaseMap){
   List<CaseTag__c> caseTagRecords = [SELECT Id, CaseTag__c, Type__c, CaseId__c FROM CaseTag__c WHERE CaseId__c = :newCaseMap.keySet()];
   Map<String, CaseTag__c> caseTagsByKeyId = new Map<String, CaseTag__c> ();

   if (!caseTagRecords.isEmpty()) {
       for (CaseTag__c ct : caseTagRecords) {
           if (!caseTagsByKeyId.containsKey(ct.CaseId__c + ct.CaseTag__c + ct.Type__c)) caseTagsByKeyId.put(ct.CaseId__c + ct.CaseTag__c, ct);
       }
   }
   return caseTagsByKeyId;
}

    /**
    * Returns a map containg the updated version (new) of the case tags records with CaseId+CaseTag+Type as key
    * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
    * @param oldCaseMap The map between the id and the old version of the case i.e. the Trigger.oldMap variable
    * @return newTagsByKeyId Map with new case tags on Case with CaseId+Tag+Type as key
    */
   public static Map<String, CaseTag__c> createCaseMap(Map<Id, Case> newCaseMap, Map<Id, Case>oldCaseMap) {
       Integer cSize = newCaseMap == null ? oldCaseMap.values().size() : newCaseMap.values().size();
       Map<String, CaseTag__c> newTagsByKeyId = new Map<String, CaseTag__c>();
       for (Integer i = 0; i < cSize; i++) {
           Case newC = newCaseMap == null ? null : newCaseMap.values()[i];
           List<String> caseTagString = newC.CaseTags__c != null ? newC.CaseTags__c.split(';') : null;
           newTagsByKeyId.put(newC.Id+newC.CaseReason__c+MAIN_TAG, new CaseTag__c(CaseId__c=newC.Id, CaseTag__c=newC.CaseReason__c, Type__c=MAIN_TAG));
           if(newC.CaseSubReason__c!=null) newTagsByKeyId.put(newC.Id+newC.CaseSubReason__c+SUB_MAIN_TAG,  new CaseTag__c(CaseId__c=newC.Id, CaseTag__c=newC.CaseSubReason__c, Type__c=SUB_MAIN_TAG));
           if (caseTagString != null) {
               for (String s : CaseTagString) {
                   newTagsByKeyId.put(newC.Id + s + ADDITIONAL_TAG, new CaseTag__c(CaseId__c=newC.Id, CaseTag__c=s, Type__c=ADDITIONAL_TAG));
               }
           }
       }
       return newTagsByKeyId;
   }
}




