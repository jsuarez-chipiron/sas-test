public without sharing class VoucherService {
  private static VoucherIntegrationService IntegrationService = (VoucherIntegrationService) SAS_Service_Application.Service.newInstance(
    VoucherIntegrationService.class
  );

  public enum VoucherType {
    GIFTCARD,
    COMP
  }

  public enum VoucherSubType {
    EU261,
    CARE,
    GOODWILL,
    DAMAGEBAG,
    DELAYEDBAG,
    PILFBAG,
    VDBCOMP,
    IDBCOMP,
    VDGCOMP,
    IDGCOMP,
    GRNDTRNS,
    SLBKSEAT,
    COVID19,
    RTCREDIT,
    NRTBONUS,
    EBPAAMEX
  }

  public enum VoucherCurrency {
    SEK,
    EUR
  }

  @future(callout=true)
  public static void createVoucher() {
    // TODO: Save what happened as some record in Salesforce.
    // TODO: Pass correct incoming data into the request

    VoucherCreateRequest voucherToCreate = new VoucherCreateRequest(
      VoucherType.COMP,
      VoucherSubType.CARE,
      VoucherCurrency.SEK,
      0,
      'ABC',
      'ABC',
      'ABC',
      'ABC',
      'ABC',
      'ABC',
      'ABC',
      'ABC'
    );

    VoucherCreateResponse resp = IntegrationService.createVoucher(
      voucherToCreate
    );
  }
}
