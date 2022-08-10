@IsTest
private class DateUtils_Test {
  @isTest
  static void shouldEvaluateIfInTime() {
    // Given
    Datetime today = DateTime.newInstance(2022, 1, 1);
    Datetime inTime = DateTime.newInstance(2020, 1, 1);
    Datetime justInTime = DateTime.newInstance(2019, 1, 1);
    Datetime aheadInTime = DateTime.newInstance(2024, 1, 1);
    Datetime aheadJustInTime = DateTime.newInstance(2025, 1, 1);
    Datetime justOutOfTime = DateTime.newInstance(2018, 12, 30); // 3 years and 2 extra days (depending on gap year).
    Datetime outOfTime = DateTime.newInstance(2015, 1, 1);
    Datetime aheadJustOutOfTime = DateTime.newInstance(2025, 1, 3);
    Datetime aheadOutOfTime = DateTime.newInstance(2027, 1, 3);
    List<DateTime> dates = new List<DateTime>{
      inTime,
      justInTime,
      aheadInTime,
      aheadJustInTime,
      justOutOfTime,
      outOfTime,
      aheadJustOutOfTime,
      aheadOutOfTime
    };

    // When
    List<Boolean> resultsPos = new List<Boolean>{};
    List<Boolean> resultsNeg = new List<Boolean>{};
    for (Datetime dat : dates) {
      resultsPos.add(DateUtils.isEligableForCompensation(today, dat));
      resultsNeg.add(DateUtils.isEligableForCompensation(dat, today));
    }

    // Then
    List<Boolean> correct = new List<Boolean>{
      true,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    };

    Integer count = 0;
    for (Integer i = 0; i < correct.size(); i++) {
      count += 1;
      System.assertEquals(
        correct[i],
        resultsPos[i],
        'Should assign eligability correctly (Pos). Date number: ' +
        String.valueOf(count)
      );
      System.assertEquals(
        correct[i],
        resultsNeg[i],
        'Should assign eligability correctly (Neg). Date number: ' +
        String.valueOf(count)
      );
    }
  }
}
