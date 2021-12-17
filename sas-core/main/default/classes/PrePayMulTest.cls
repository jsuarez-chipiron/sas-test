@isTest
public class PrePayMulTest {
  public static testMethod void createTextFile() {
    List<PrePayMul> prePayList = new List<PrePayMul>();

    prePayList.add(PrePayMulTestUtil.createTestData());

    Test.startTest();
    CreateTextFileController crTextCtr = new CreateTextFileController();
    crTextCtr.createTextFile(prePayList);
    Test.stopTest();
  }
}
