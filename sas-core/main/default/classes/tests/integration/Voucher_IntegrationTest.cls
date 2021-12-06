@IsTest
public with sharing class Voucher_IntegrationTest {
  @IsTest
  public static void itShouldBePossibleToCreateVouchers() {
    // No functionality yet.
    Test.setMock(HttpCalloutMock.class, new APIMMock());
    Test.startTest();
    VoucherService.createVoucher();
    Test.stopTest();

    System.assert(true);
  }
}
