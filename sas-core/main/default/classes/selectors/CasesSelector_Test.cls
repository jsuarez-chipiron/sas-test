@IsTest
private class CasesSelector_Test {
  private static CasesSelector cases = CasesSelector.newInstance();

  @testSetup
  static void setup() {
    Proactivity__c normalProactivity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Phone_Number__c = '0000000000'
    );
    Proactivity__c directlyMatchedProactivity = new Proactivity__c(
      Note__c = 'Test 6',
      Type__c = 'Normal'
    );
    Proactivity__c directlyAndIndirectlyMatchedProactivity = new Proactivity__c(
      Note__c = 'Test 7',
      Type__c = 'Normal',
      Email__c = 'test@test.com'
    );
    Proactivity__c mixedMatchProactivity = new Proactivity__c(
      Note__c = 'Test 8',
      Type__c = 'Normal',
      Email__c = 'test@test.com',
      Phone_Number__c = '0000000000'
    );

    insert new List<Proactivity__c>{
      directlyMatchedProactivity,
      directlyAndIndirectlyMatchedProactivity,
      mixedMatchProactivity
    };

    Case caseWithOneProactivityRegularMatcher = new Case(
      FCS_EBNumber__c = '000000001'
    );
    Case caseWithDirectMatch = new Case(
      Proactivity__c = directlyMatchedProactivity.Id,
      FCS_EBNumber__c = '000000002'
    );
    Case caseWithDirectAndIndirectMatch = new Case(
      Proactivity__c = directlyAndIndirectlyMatchedProactivity.Id,
      FCS_EBNumber__c = '000000003'
    );
    Case caseWithMixedMatch = new Case(
      Proactivity__c = mixedMatchProactivity.Id,
      FCS_EBNumber__c = '000000004'
    );

    insert new List<Case>{
      caseWithOneProactivityRegularMatcher,
      caseWithDirectMatch,
      caseWithDirectAndIndirectMatch,
      caseWithMixedMatch
    };

    LIA_Claim__c claimWithOneProactivityRegularMatcher = new LIA_Claim__c(
      Case__c = caseWithOneProactivityRegularMatcher.Id,
      Phone_Number__c = '0000000000'
    );

    LIA_Claim__c claimWithOneProactivityRegularMatcherDoubleMatch = new LIA_Claim__c(
      Case__c = caseWithDirectAndIndirectMatch.Id,
      Contact_Email__c = 'test@test.com'
    );

    insert new List<SObject>{
      normalProactivity,
      claimWithOneProactivityRegularMatcher,
      claimWithOneProactivityRegularMatcherDoubleMatch
    };
  }

  @IsTest
  static void shouldSelectCaseWithNormalProactivityClaimMatch() {
    // Given (setup)
    Proactivity__c normalProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 1'
    ][0];
    Case correctCase = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000001'
    ][0];

    // When
    List<Case> oneCaseNormalMatcher = cases.selectByProactivityId(
      normalProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneCaseNormalMatcher.size(),
      'Should select a single case from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctCase.Id,
      oneCaseNormalMatcher[0].Id,
      'Should select a single case from proactivity ID correctly (wrong case)'
    );
  }

  @IsTest
  static void shouldSelectCaseWithDirectMatchNoClaim() {
    // Given (setup)
    Proactivity__c directMatchProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 6'
    ][0];
    Case correctCase = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c = '000000002'
    ][0];

    // When
    List<Case> oneCaseDirectMatchNoClaim = cases.selectByProactivityId(
      directMatchProactivity.ID
    );

    // Then
    System.assertEquals(
      1,
      oneCaseDirectMatchNoClaim.size(),
      'Should select a single case without claim from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      correctCase.Id,
      oneCaseDirectMatchNoClaim[0].Id,
      'Should select a single case without claim from proactivity ID correctly (wrong case)'
    );
  }

  @IsTest
  static void shouldSelectCaseWithMixedMatch() {
    // Given (setup)
    Proactivity__c mixedMatchProactivity = [
      SELECT Id
      FROM Proactivity__c
      WHERE Note__c = 'Test 8'
    ][0];
    List<Case> correctCases = [
      SELECT Id
      FROM Case
      WHERE FCS_EBNumber__c IN ('000000001', '000000003', '000000004')
    ];

    // When
    List<Case> threeCasesMixMatch = cases.selectByProactivityId(
      mixedMatchProactivity.ID
    );

    List<Id> selectedCaseIds = new List<Id>{};
    for (Case c : threeCasesMixMatch) {
      selectedCaseIds.add(c.Id);
    }

    Integer correctlyMatched = 0;
    for (Case c : correctCases) {
      if (selectedCaseIds.contains(c.Id)) {
        correctlyMatched += 1;
      }
    }

    // Then
    System.assertEquals(
      3,
      threeCasesMixMatch.size(),
      'Should select three cases with mixed matching from proactivity ID correctly (too many/few matches)'
    );
    System.assertEquals(
      3,
      correctlyMatched,
      'Should select three cases with mixed matching from proactivity ID correctly (wrong case)'
    );
  }
}
