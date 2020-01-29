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
    @TestVisible private static final String SP_STATUS_REVIEWED= 'Reviewed';
    /**
   Static variable for the Case status "Closed"
   */
    @TestVisible private static final String CASE_STATUS_CLOSED= 'Closed';

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
        assignOwnerFromSoMe(newCaseList);
        validateCaseTags(newCaseList);
    }
    /**
  Used to call the trigger in the before update context
  */
    public override void beforeUpdate() {
        validateCaseTags(newCaseList);
    }
    /**
   Used to call the trigger in the after insert context
   */
    public override void afterInsert() {
        manageCaseTagRecords(newCaseList, newCaseMap);
        updateSocialPost(newCaseList);
    }

    /**
    Used to call the trigger in the after update context
    */
    public override void afterUpdate() {
        manageCaseTagRecords(newCaseList, newCaseMap);
    }

    /**
    Method to set owner on case created from SoMe-post quick actions
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void assignOwnerFromSoMe(List<Case> newCaseList) {
        Set<Id> socialPostIds = new Set<Id>();
        List<Case> caseInScope = new List<Case>();
        for (Case c : newCaseList) {
            Boolean infoTag = (c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType() == SocialPost.SObjectType && c.Status == CASE_STATUS_CLOSED && c.RecordTypeId == C_RecordTypeHelper.CASE_INFORMATION);
            Boolean supportTag = (c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType() == SocialPost.SObjectType && c.Status == CASE_STATUS_CLOSED && c.RecordTypeId == C_RecordTypeHelper.CASE_SUPPORT);
            Boolean feedbackTag = (c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType() == SocialPost.SObjectType && c.Status == CASE_STATUS_CLOSED && c.RecordTypeId == C_RecordTypeHelper.CASE_FEEDBACK);
            if ((infoTag || supportTag || feedbackTag)) {
                socialPostIds.add(c.SourceId);
                caseInScope.add(c);
            }
        }
        Map<Id,SocialPost> socialPostsByIds = new Map<Id, SocialPost>([SELECT Id, OwnerId FROM SocialPost WHERE Id =:socialPostIds]);
        for (Case c : caseInScope){
            if(socialPostsByIds.containsKey(c.SourceId)){
                if(socialPostsByIds.get(c.SourceId).OwnerId.getSObjectType()==User.SObjectType){
                    c.OwnerId=socialPostsByIds.get(c.SourceId).OwnerId;
                }
                else {
                    c.addError('The Social Post needs to be assign to a user before tagging the post');
                }
            }
        }
    }

    /**
    Method to update parent social post with status fields when case is created
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void updateSocialPost(List<Case> newCaseList) {
        Map<Id,Case>caseBySoMeIds = new Map<Id,Case>();
        for(Case c : newCaseList){
            if(c.SourceId!=null && c.SourceId.getSobjectType()==SocialPost.SObjectType && c.Status!=CASE_STATUS_CLOSED) {
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
                sp.ReviewedStatus=SP_STATUS_REVIEWED;
                spToUpdate.add(sp);
            }
            update spToUpdate;
        }
    }

    /**
    Method to make sure Case Reason and Case Tags is not the same value
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void validateCaseTags(List<Case> newCaseList) {
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
    private static void manageCaseTagRecords(List <Case> newCaseList, Map<Id, Case> newCaseMap) {
        try {
            Map<String, CaseTag__c> newTagByKeyId = createToBeCaseTagMap(newCaseList);
            Map<String, CaseTag__c> oldTagByKeyId = createCurrentCaseTagMap(newCaseMap);
            List<CaseTag__c> deleteCaseTags = new List<CaseTag__c>();
            List<CaseTag__c> createCaseTags = new List<CaseTag__c>();

            for (String keyId : newTagByKeyId.keySet()) {
                if (oldTagByKeyId.containsKey(keyId)) oldTagByKeyId.remove(keyId);
                else if (!oldTagByKeyId.containsKey(keyId)) createCaseTags.add(newTagByKeyId.get(keyId));
            }
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