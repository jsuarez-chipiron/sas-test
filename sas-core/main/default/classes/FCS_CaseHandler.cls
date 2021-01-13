/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description Handler class for operations performed on case object.
 */
public class FCS_CaseHandler extends C_TriggerHandler {
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
    @TestVisible private static final String SP_STATUS_REVIEWED = 'Reviewed';
    /**
   Static variable for the Case status "Closed"
   */
    @TestVisible private static final String CASE_STATUS_CLOSED = 'Closed';

    /**
    Trigger variables
    */
    private Map < Id, Case > newCaseMap;
    private List < Case > newCaseList;
    private Map < Id, Case > oldCaseMap;
    private List < Case > oldCaseList;
    /**
   Set variables
   */
    public FCS_CaseHandler() {
        this.newCaseMap = (Map < Id, Case > ) Trigger.newMap;
        this.newCaseList = (List < Case > ) Trigger.new;
        this.oldCaseMap = (Map < Id, Case > ) Trigger.oldMap;
        this.oldCaseList = (List < Case > ) Trigger.old;
    }
    /**
   Used to call the trigger in the before insert context
   */
    public override void beforeInsert() {
        assignOwnerFromSoMe(newCaseList);
        validateCaseTags(newCaseList);
        enrichCaseDataBasedOnOrigin(newCaseList);
        enrichCaseDataWithFormData(newCaseList);
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
        assignEurobonusAccountToCase(newCaseList);
    }

    /**
    Used to call the trigger in the after update context
    */
    public override void afterUpdate() {
        manageCaseTagRecords(newCaseList, newCaseMap);
    }

    /**
    Used to call the trigger in the after delete context
    */
    public override void afterDelete() {
        //Make sure that related Survey Invitations are deleted upon case deletion
        delete[SELECT Id FROM SurveyInvitation WHERE FCS_RelatedCase__c IN: oldCaseMap.keySet()];
    }

    /**
     * Updates case fields based on Origin of the Case. The Enrich_Case_Based_On_Origin_Config__mdt
     * custom metadata type is used to defined what data to assign based on Origin.
     * 
     * Should be run only on beforeInsert.
     */
    private static void enrichCaseDataBasedOnOrigin(List<Case> newCaseList) {
        for (Case c: newCaseList) {
            List<Enrich_Case_Based_On_Origin_Config__mdt> enrichmentData = [SELECT Case_Type_To_Assign__c, Case_Visibility_Grouping_To_Assign__c FROM Enrich_Case_Based_On_Origin_Config__mdt WHERE Incoming_Case_Origin__c = :c.Origin];
            if (!enrichmentData.isEmpty()) {
                // A configuration was found for this Origin
                Enrich_Case_Based_On_Origin_Config__mdt caseConfiguration = enrichmentData[0];

                // Fill in fields only if they have a value set in the config
                if (!String.isEmpty(caseConfiguration.Case_Type_To_Assign__c)) {
                    c.Type = caseConfiguration.Case_Type_To_Assign__c;
                }

                if (!String.isEmpty(caseConfiguration.Case_Visibility_Grouping_To_Assign__c)) {
                    c.Case_Grouping__c = caseConfiguration.Case_Visibility_Grouping_To_Assign__c;
                }
            }
        }
    }

    /** 
    *Reads case subject and case description fields and updates case fields with data from description
    *if some requirements are met.
    * Run only on beforeInsert
     */

    private static void enrichCaseDataWithFormData(List<Case> newCaseList){
        /**Lisr caseFormKeywords and incomingEmailAddressAsVerification are Used as part of verification to check if email comes from form */
        List <String> caseFormKeywords=new List<String> {'group-trips', 'sports-trips', 'grouptrips', 'request-grupperejse',
                                                         'sportgruppereiser', 'gruppresor'};
        List <String> incomingEmailAddressAsVerification= new List<String>{'gruppresor.se@sas.se', 'gruppereiser.no@sas.no',    
                                                                           'donotreply@sas.dk', 'uk-groupquotes@sas.dk', 'salesforce_uat4@sas.se'};
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        for (Case c: newCaseList){
            for(String email:incomingEmailAddressAsVerification){
                    for(String keyWord: caseFormKeywords) {
                        Boolean comesFromForm=c.Subject!=Null && c.Subject.toLowercase().Contains(keyWord)  && c.SuppliedEmail==email;
                            if(comesFromForm){
                                if(c.Description != '' && c.Description.length()>0){
                                    String data=c.Description;
                                    String newSuppliedEmail=data.substringBetween('email : ', '\n');            
                                    /**
                                    * validate suppliedEmail email address received from form
                                    * and assign as suppliedEmail if valid
                                    */
                                    
                                    if(newSuppliedEmail == null){
                                        c.SuppliedEmail=c.SuppliedEmail;
                                    }else{
                                        Pattern emailPattern = Pattern.compile(emailRegex);
                                        Matcher emailMatcher = emailPattern.matcher(newSuppliedEmail);
                                        if(emailMatcher.matches()){
                                            c.SuppliedEmail=newSuppliedEmail;
                                        }else{
                                            c.SuppliedEmail=c.SuppliedEmail;
                                        }
                                    }
                                }
                            }
                    }
                }
            }
    }


    /**
    Method to set owner on case created from SoMe-post quick actions
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void assignOwnerFromSoMe(List < Case > newCaseList) {
        Set < Id > socialPostIds = new Set < Id > ();
        List < Case > caseInScope = new List < Case > ();
        for (Case c: newCaseList) {
            Boolean infoTag = (c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType() == SocialPost.SObjectType && c.Status == CASE_STATUS_CLOSED && c.RecordTypeId == C_RecordTypeHelper.CASE_INFORMATION);
            Boolean supportTag = (c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType() == SocialPost.SObjectType && c.Status == CASE_STATUS_CLOSED && c.RecordTypeId == C_RecordTypeHelper.CASE_SUPPORT);
            Boolean feedbackTag = (c.Origin == 'Facebook' || c.Origin == 'Twitter') && (c.SourceId != null && c.SourceId.getSOBjectType() == SocialPost.SObjectType && c.Status == CASE_STATUS_CLOSED && c.RecordTypeId == C_RecordTypeHelper.CASE_FEEDBACK);
            if ((infoTag || supportTag || feedbackTag)) {
                socialPostIds.add(c.SourceId);
                caseInScope.add(c);
            }
        }
        Map < Id, SocialPost > socialPostsByIds = new Map < Id, SocialPost > ([SELECT Id, OwnerId FROM SocialPost WHERE Id =: socialPostIds]);
        for (Case c: caseInScope) {
            if (socialPostsByIds.containsKey(c.SourceId)) {
                if (socialPostsByIds.get(c.SourceId).OwnerId.getSObjectType() == User.SObjectType) {
                    c.OwnerId = socialPostsByIds.get(c.SourceId).OwnerId;
                } else {
                    c.addError('The Social Post needs to be assign to a user before tagging the post');
                }
            }
        }
    }

    /**
    Method to update parent social post with status fields when case is created
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void updateSocialPost(List < Case > newCaseList) {
        Map < Id, Case > caseBySoMeIds = new Map < Id, Case > ();
        for (Case c: newCaseList) {
            if (c.SourceId != null && c.SourceId.getSobjectType() == SocialPost.SObjectType) {
                caseBySoMeIds.put(c.SourceId, c);
            }
        }
        if (!caseBySoMeIds.isEmpty()) {
            List < SocialPost > sps = [SELECT Id FROM SocialPost WHERE Id =: caseBySoMeIds.keySet() AND ParentId = null];
            List < SocialPost > spToUpdate = new List < SocialPost > ();
            for (SocialPost sp: sps) {
                sp.ParentId = caseBySoMeIds.get(sp.Id).Id;
                if (caseBySoMeIds.get(sp.Id).Status != CASE_STATUS_CLOSED) {
                    sp.FCS_CaseCreated__c = true;
                    sp.FCS_Done__c = true;
                    sp.FCS_ClosedDate__c = system.now();
                    sp.ReviewedStatus = SP_STATUS_REVIEWED;
                }
                spToUpdate.add(sp);
            }
            update spToUpdate;
        }
    }

    /**
    Method to make sure Case Reason and Case Tags is not the same value
    @param newCaseList The list of new version of the case i.e. the Trigger.new variable
    */
    private static void validateCaseTags(List < Case > newCaseList) {
        Integer cSize = newCaseList.size();
        for (Integer i = 0; i < cSize; i++) {
            Case newC = newCaseList[i];
            List < String > caseTagString = newC.FCS_CaseTags__c != null ? newC.FCS_CaseTags__c.split(';') : null;
            if (caseTagString != null) {
                for (String s: CaseTagString) {
                    if (s == newC.FCS_CaseReason__c) {
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
    private static void manageCaseTagRecords(List < Case > newCaseList, Map < Id, Case > newCaseMap) {
        Map < String, FCS_CaseTag__c > newTagByKeyId = createToBeCaseTagMap(newCaseList);
        Map < String, FCS_CaseTag__c > oldTagByKeyId = createCurrentCaseTagMap(newCaseMap);
        List < FCS_CaseTag__c > deleteCaseTags = new List < FCS_CaseTag__c > ();
        List < FCS_CaseTag__c > createCaseTags = new List < FCS_CaseTag__c > ();

        for (String keyId: newTagByKeyId.keySet()) {
            if (oldTagByKeyId.containsKey(keyId)) oldTagByKeyId.remove(keyId);
            else if (!oldTagByKeyId.containsKey(keyId)) createCaseTags.add(newTagByKeyId.get(keyId));
        }
        deleteCaseTags = oldTagByKeyId.values();
        if (createCaseTags != null) upsert createCaseTags;
        if (deleteCaseTags != null) delete deleteCaseTags;
    }
    /**
     * Returns a map containing the current (old) case tags records that needs to be evaluate agianst the new version of the case, FCS_CaseId__c+CaseTag+Type as key
     * @param newCaseMap The map between the id and the new version of the case i.e. the Trigger.newMap variable
     * @return caseTagsByKeyId Map with existing case tag records (FCS_CaseTag__c) with FCS_CaseId__c+Tag+Type as key
     */
    public static Map < String, FCS_CaseTag__c > createCurrentCaseTagMap(Map < Id, Case > newCaseMap) {
        List < FCS_CaseTag__c > caseTagRecords = [SELECT Id, FCS_CaseTag__c, FCS_Type__c, FCS_CaseId__c FROM FCS_CaseTag__c WHERE FCS_CaseId__c =: newCaseMap.keySet()];
        Map < String, FCS_CaseTag__c > caseTagsByKeyId = new Map < String, FCS_CaseTag__c > ();
        if (!caseTagRecords.isEmpty()) {
            for (FCS_CaseTag__c ct: caseTagRecords) {
                if (!caseTagsByKeyId.containsKey(ct.FCS_CaseId__c + ct.FCS_CaseTag__c + ct.FCS_Type__c)) caseTagsByKeyId.put(ct.FCS_CaseId__c + ct.FCS_CaseTag__c + ct.FCS_Type__c, ct);
            }
        }
        return caseTagsByKeyId;
    }

    /**
     * Returns a map containg the updated version (new) of the case tags records with FCS_CaseId__c+CaseTag+Type as key
     * @param newCaseList The list of the new version of the case i.e. the Trigger.new variable
     * @return newTagsByKeyId Map with new case tags on Case with FCS_CaseId__c+Tag+Type as key
     */
    public static Map < String, FCS_CaseTag__c > createToBeCaseTagMap(List < Case > newCaseList) {
        Integer cSize = newCaseList.size();
        Map < String, FCS_CaseTag__c > newTagsByKeyId = new Map < String, FCS_CaseTag__c > ();
        for (Integer i = 0; i < cSize; i++) {
            Case newC = newCaseList == null ? null : newCaseList[i];
            List < String > caseTagString = newC.FCS_CaseTags__c != null ? newC.FCS_CaseTags__c.split(';') : null;
            if (newC.FCS_CaseReason__c != null) newTagsByKeyId.put(newC.Id + newC.FCS_CaseReason__c + MAIN_TAG, new FCS_CaseTag__c(FCS_CaseId__c = newC.Id, FCS_CaseTag__c = newC.FCS_CaseReason__c, FCS_Type__c = MAIN_TAG));
            if (newC.FCS_CaseSubReason__c != null) newTagsByKeyId.put(newC.Id + newC.FCS_CaseSubReason__c + SUB_MAIN_TAG, new FCS_CaseTag__c(FCS_CaseId__c = newC.Id, FCS_CaseTag__c = newC.FCS_CaseSubReason__c, FCS_Type__c = SUB_MAIN_TAG));
            if (caseTagString != null) {
                for (String s: CaseTagString) {
                    newTagsByKeyId.put(newC.Id + s + ADDITIONAL_TAG, new FCS_CaseTag__c(FCS_CaseId__c = newC.Id, FCS_CaseTag__c = s, FCS_Type__c = ADDITIONAL_TAG));
                }
            }
        }
        return newTagsByKeyId;
    }
    /**
     * @param newCaseList The list of the new version of the case i.e. the Trigger.new variable
       assign the EuroBonus Account to Case based on the Email for Pandion customers
       It search If there is any existing Account in salesforce , if not then call the Feature method , in turn call 
       the C shark to fetch the details
    */
    public static void assignEurobonusAccountToCase(List < Case > newCaseList) {
        List < String > lstEmailAddress = new List < String > ();
        List < Case > lstUpdateCases = new List < Case > ();
        List < Id > lstCaseIds = new List < Id > ();
        List < Account > lstAcc = new List < Account > ();
        for (Case cse: newCaseList) {
            if (cse.Origin == 'Pandion SE' || cse.Origin == 'Pandion NO' || cse.Origin == 'Pandion DK') {
                if (cse.SuppliedEmail != null && cse.SuppliedEmail != '') {
                    lstEmailAddress.add(cse.SuppliedEmail);
                    lstCaseIds.add(cse.Id);
                }
            }

        }
        if (!lstEmailAddress.isEmpty()) {
            lstAcc = [SELECT Id, FCS_EBNumber__c From Account where PersonEmail =: lstEmailAddress[0] AND isPersonAccount = true];
        }
        if (!lstAcc.isEmpty()) {
            Case cse = new Case();
            cse.FCS_EBNumber__c = lstAcc[0].FCS_EBNumber__c;
            cse.accountId = lstAcc[0].Id;
            cse.Id = newCaseList[0].Id;
            lstUpdateCases.add(cse);
        } else if (lstCaseIds.size() > 0) {
            findEuroBonusAccount(lstCaseIds);
        }
        if (!lstUpdateCases.isEmpty()) {
            Update lstUpdateCases;
        }
    }
    /**
     get the eurobonus account from C-shark using Email
     @param set of caseIds
    */
    @future(callOut = true)
    public static void findEuroBonusAccount(List < Id > lstCseIds) {
        Account acc;
        List < Case > lstUpdateCases = new List < Case > ();
        List < Case > lstCases = new List < Case > ();
        lstCases = [Select Id, FCS_EBNumber__c, SuppliedEmail, AccountId From Case where Id =: lstCseIds[0] And SuppliedEmail != null LIMIT 1];
        if (!lstCases.isEmpty()) {
            acc = FCS_IdentifyCustomerController.findCustomer('EmailPersonal__c', lstCases[0].SuppliedEmail);
            if (acc != null) {
                Case cs = new Case();
                cs.Id = lstCases[0].Id;
                cs.FCS_EBNumber__c = acc.FCS_EBNumber__c;
                cs.accountId = acc.Id;
                lstUpdateCases.add(cs);
            }
            if (!lstUpdateCases.isEmpty()) {
                Update lstUpdateCases;
            }

        }
    }

}