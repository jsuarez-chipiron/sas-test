/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description Handler class for operations performed on case object.
 */


public class CaseHandler extends C_TriggerHandler {

    /**
    Static variable for the Case Tag type Main
    */
    @TestVisible private static final String MAIN_TAG = 'Main';

    /**
   Static variable for the Case Tag type Sub
   */
    @TestVisible private static final String SUB_MAIN_TAG = 'Sub';


    /**
   Static variable for the Case Tag type Additional
   */
    @TestVisible private static final String ADDITIONAL_TAG = 'Additional';

    /**
Static variable for the Social Post review status "Reviewed"
*/
    @TestVisible private static final String STATUS_REVIEWED= 'Reviewed';

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
        ValidateCaseTags(newCaseList);

    }

    /**
  Used to call the trigger in the before update context
  */
    public override void beforeUpdate() {
        ValidateCaseTags(newCaseList);

    }

    /**
   Used to call the trigger in the after insert context
   */
    public override void afterInsert() {
        ManageCaseTagRecords(newCaseList, newCaseMap);
        UpdateSocialPost(newCaseList);

    }


    /**
    Used to call the trigger in the after update context
    */
    public override void afterUpdate() {
        ManageCaseTagRecords(newCaseList, newCaseMap);

    }

    /**
    Method to set owner (Global Support SoMe) on case created from SoMe-posts
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void AssignOwnerFromSoMe(List<Case> newCaseList) {
        for (Case c : newCaseList) {
            //Route cases created from Social Posts to GlobalSupportSoMe-queue
            if ((c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType()==SocialPost.SObjectType)) {
                List<Group> soMeQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'GlobalSupportSoMe'];
                if(soMeQueue.size() != 0) c.OwnerId = soMeQueue[0].Id;
                else C_log.log(C_Log.Severity.Warning, 'GlobalSupportSoMe queue not found', null, null, null );
            }
        }
    }

    /**
    Method to set owner (Global Support SoMe) on case created from SoMe-posts
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void UpdateSocialPost(List<Case> newCaseList) {
       Map<Id,Case>caseBySoMeIds = new Map<Id,Case>();
        for(Case c : newCaseList){
            if(c.SourceId!=null && c.SourceId.getSobjectType()==SocialPost.SObjectType) {
                caseBySoMeIds.put(c.SourceId, c);
            }
        }
        if(!caseBySoMeIds.isEmpty()) {
            List<SocialPost> sps = [SELECT Id FROM SocialPost WHERE Id =:caseBySoMeIds.keySet() AND ParentId=null];
            List<SocialPost> spToUpdate = new List<SocialPost> ();
        for (SocialPost sp : sps) {
            sp.ParentId=caseBySoMeIds.get(sp.Id).Id;
            sp.CaseCreated__c = true;
            sp.Done__c=true;
            sp.ReviewedStatus=STATUS_REVIEWED;
            spToUpdate.add(sp);

            }

        update spToUpdate;
    }
    }



    /**
    Method to make sure Case Reason and Case Tags is not the same value
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void ValidateCaseTags(List<Case> newCaseList) {
        Integer cSize = newCaseList.size();
        for (Integer i = 0; i < cSize; i++) {
            Case newC = newCaseList[i];
                List<String> caseTagString = newC.CaseTags__c != null ? newC.CaseTags__c.split(';') : null;
                if (caseTagString != null) {
                    for (String s : CaseTagString) {
                        if (s == newC.CaseReason__c) {
                            newC.addError('You can not provide the same additional reason (case tag) as the Case Reason');

                        }
                    }
            }
        }
    }

    /**
     * Creates/updates/delete case tag records when tags (Case Reason, Case SubReason or Case Tag) is updated on case
     * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
     */
    private static void ManageCaseTagRecords(List <Case> newCaseList, Map<Id, Case> newCaseMap) {
        try {

            // Map with current tags on case with CaseId+Tag+Type as key
            Map<String, CaseTag__c> newTagByKeyId = createToBeCaseTagMap(newCaseList);

            // Map with existing case tag records and CaseId+Tag+Type as key
            Map<String, CaseTag__c> oldTagByKeyId = createCurrentCaseTagMap(newCaseMap);


            // List to put current case tag records that should be deleted
            List<CaseTag__c> deleteCaseTags = new List<CaseTag__c>();

            // List to put case tag records that should be created
            List<CaseTag__c> createCaseTags = new List<CaseTag__c>();

            // Loop over new/updated tags on case and compare with tags in case tag records
            for (String keyId : newTagByKeyId.keySet()) {
                if (oldTagByKeyId.containsKey(keyId)) oldTagByKeyId.remove(keyId);
                else if (!oldTagByKeyId.containsKey(keyId)) createCaseTags.add(newTagByKeyId.get(keyId));
            }

            //Delete old tags not included in newTagByKeyId Map

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
    public static Map<String, CaseTag__c> createCurrentCaseTagMap(Map<Id, Case> newCaseMap){
        List<CaseTag__c> caseTagRecords = [SELECT Id, CaseTag__c, Type__c, CaseId__c FROM CaseTag__c WHERE CaseId__c = :newCaseMap.keySet()];
        Map<String, CaseTag__c> caseTagsByKeyId = new Map<String, CaseTag__c> ();

        if (!caseTagRecords.isEmpty()) {
            for (CaseTag__c ct : caseTagRecords) {
                if (!caseTagsByKeyId.containsKey(ct.CaseId__c + ct.CaseTag__c + ct.Type__c)) caseTagsByKeyId.put(ct.CaseId__c + ct.CaseTag__c+ct.Type__c, ct);
            }
        }
        return caseTagsByKeyId;
    }

    /**
    * Returns a map containg the updated version (new) of the case tags records with CaseId+CaseTag+Type as key
    * @param newCaseList The list of the new version of the case i.e. the Trigger.new variable
    * @return newTagsByKeyId Map with new case tags on Case with CaseId+Tag+Type as key
    */
    public static Map<String, CaseTag__c> createToBeCaseTagMap(List<Case> newCaseList) {
        Integer cSize = newCaseList.size();
        Map<String, CaseTag__c> newTagsByKeyId = new Map<String, CaseTag__c>();
        for (Integer i = 0; i < cSize; i++) {
            Case newC = newCaseList == null ? null : newCaseList[i];
                List<String> caseTagString = newC.CaseTags__c != null ? newC.CaseTags__c.split(';') : null;
                if (newC.CaseReason__c != null) newTagsByKeyId.put(newC.Id + newC.CaseReason__c + MAIN_TAG, new CaseTag__c(CaseId__c = newC.Id, CaseTag__c = newC.CaseReason__c, Type__c = MAIN_TAG));
                if (newC.CaseSubReason__c != null) newTagsByKeyId.put(newC.Id + newC.CaseSubReason__c + SUB_MAIN_TAG, new CaseTag__c(CaseId__c = newC.Id, CaseTag__c = newC.CaseSubReason__c, Type__c = SUB_MAIN_TAG));
                if (caseTagString != null) {
                    for (String s : CaseTagString) {
                        newTagsByKeyId.put(newC.Id + s + ADDITIONAL_TAG, new CaseTag__c(CaseId__c = newC.Id, CaseTag__c = s, Type__c = ADDITIONAL_TAG));
                    }
                }
            }
        return newTagsByKeyId;
    }
}




