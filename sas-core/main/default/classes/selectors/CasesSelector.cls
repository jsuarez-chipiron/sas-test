public inherited sharing class CasesSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Case.Id,
      Case.AccountId,
      Case.CaseNumber,
      Case.CreatedDate,
      Case.Handling_Instructions__c,
      Case.FCS_EBLevel__c,
      Case.FCS_EBNumber__c,
      Case.FCS_Case_Reason__c,
      Case.FCS_CaseType__c,
      Case.ParentId,
      Case.RecordTypeId,
      Case.Status,
      Case.SuppliedEmail,
      Case.Department__c,
      Case.Team__c,
      Case.Origin,
      Case.FCS_CaseType__c,
      Case.FCS_CaseResolution__c,
      Case.FCS_CaseResolutionDetails__c,
      Case.Proactivity__c,
      Case.LIA_Claim__c,
      Case.OwnerId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Case.SObjectType;
  }

  public static CasesSelector newInstance() {
    return (CasesSelector) SAS_Service_Application.Selector.newInstance(
      Case.SObjectType
    );
  }

  private static ClaimsSelector claims = ClaimsSelector.newInstance();

  public List<Case> selectById(Set<Id> ids) {
    return (List<Case>) selectSObjectsById(ids);
  }

  public List<Case> selectByIdWithClaim(Set<Id> ids) {
    fflib_QueryFactory caseQF = newQueryFactory()
      .setCondition('Id in :ids')
      .selectField('Owner.Name');
    fflib_QueryFactory claimsQF = new ClaimsSelector()
      .addQueryFactorySubselect(caseQF);

    return (List<Case>) Database.query(caseQF.toSOQL());
  }

  public List<Case> selectByParentId(Set<Id> parentIds) {
    return (List<Case>) Database.query(
      newQueryFactory().setCondition('ParentId in :parentIds').toSOQL()
    );
  }

  public List<Case> selectByDirectlyLinkedProactivityId(
    Set<Id> proactivityIds
  ) {
    fflib_QueryFactory directlyLinkedQF = newQueryFactory()
      .setCondition('Proactivity__c IN :proactivityIds');

    return (List<Case>) Database.query(directlyLinkedQF.toSOQL());
  }

  public List<Case> selectByProactivityId(Id proactivityId) {
    List<LIA_Claim__c> claimsByProactivity = claims.selectByProactivityId(
      proactivityId
    );

    // Check directly linked cases with no claims.
    List<Case> directlyLinkedCases = selectByDirectlyLinkedProactivityId(
      new Set<Id>{ proactivityId }
    );

    if (claimsByProactivity.size() == 0 && directlyLinkedCases.size() == 0) {
      return new List<Case>();
    }

    Set<Id> casesToFind = new Set<Id>();
    for (LIA_Claim__c claim : claimsByProactivity) {
      casesToFind.add(claim.Case__c);
    }

    // Handle duplicate values (edgecase)
    Set<Case> resultNoDuplicates = new Set<Case>();
    List<Case> result = new List<Case>{};
    resultNoDuplicates.addAll(selectById(casesToFind));
    resultNoDuplicates.addAll(directlyLinkedCases);
    result.addAll(resultNoDuplicates);

    return result;
  }

  public List<Case> selectByAccountId(Set<Id> accountIds) {
    fflib_QueryFactory casesQF = newQueryFactory()
      .setCondition('AccountId in :accountIds');
    return (List<Case>) Database.query(casesQF.toSOQL());
  }

  public List<Case> selectByChatId(Set<Id> chatIds) {
    ChatTranscriptsSelector chatTranscripts = (ChatTranscriptsSelector) SAS_Service_Application.Selector.newInstance(
      LiveChatTranscript.SObjectType
    );

    Set<Id> caseIds = new Set<Id>();
    for (LiveChatTranscript ct : chatTranscripts.selectById(chatIds)) {
      caseIds.add(ct.caseId);
    }
    return (List<Case>) this.selectSObjectsById(caseIds);
  }

  public List<Case> selectBySocialPostId(Set<Id> socialPostIds) {
    SocialPostsSelector socialPosts = (SocialPostsSelector) SAS_Service_Application.Selector.newInstance(
      SocialPost.SObjectType
    );
    Set<Id> caseIds = new Set<Id>();
    for (SocialPost sp : socialPosts.selectById(socialPostIds)) {
      caseIds.add(sp.parentId);
    }
    return (List<Case>) this.selectSObjectsById(caseIds);
  }

  public List<Case> selectByMessagingId(Set<Id> messagingsessionsId) {
    MessagingSessionsSelector messagingSessions = (MessagingSessionsSelector) SAS_Service_Application.Selector.newInstance(
      MessagingSession.SObjectType
    );
    Set<Id> caseIds = new Set<Id>();
    for (
      MessagingSession ms : messagingSessions.selectById(messagingsessionsId)
    ) {
      caseIds.add(ms.caseId);
    }
    return (List<Case>) this.selectSObjectsById(caseIds);
  }

  public List<Case> selectByBookingReference(Set<String> bookingReferences) {
    CaseToBookingsSelector caseToBookings = (CaseToBookingsSelector) SAS_Service_Application.Selector.newInstance(
      CaseToBooking__c.SObjectType
    );
    Set<Id> caseIds = new Set<Id>();
    for (
      CaseToBooking__c ctb : caseToBookings.selectByBookingReference(
        bookingReferences
      )
    ) {
      caseIds.add(ctb.Case__c);
    }

    return (List<Case>) this.selectSObjectsById(caseIds);
  }

  public List<Case> selectSimilarCasesById(Id caseId) {
    List<LIA_Claim__c> similarClaims = claims.selectSimilarClaimsByCaseId(
      caseId
    );
    if (similarClaims == null || similarClaims.size() == 0) {
      return new List<Case>();
    }

    Set<Id> caseIds = new Set<Id>();
    for (LIA_Claim__c claim : similarClaims) {
      caseIds.add(claim.Case__c);
    }

    return selectByIdWithClaim(caseIds);
  }

  public List<Case> selectInactiveByDepartment(String department) {
    String statusToFetch = Cases.STATUS_CLOSED;
    Datetime lastUpdatedCutoff = System.Test.isRunningTest()
      ? System.now().addDays(1)
      : System.now()
          .addDays(Cases.departmentToDaysInactive.get(department) * -1);

    fflib_QueryFactory casesQF = newQueryFactory()
      .setCondition(
        'Status = :statusToFetch AND LastModifiedDate <= :lastUpdatedCutoff AND Department__c = :department'
      );
    return (List<Case>) Database.query(casesQF.toSOQL());
  }

  public override String getOrderBy() {
    return 'CaseNumber';
  }
}
