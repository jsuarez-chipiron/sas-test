public class IRR_Mod_ICouponInfo {

    @AuraEnabled
    public String couponBatchId { get; set; }
    @AuraEnabled
    public String serviceClassCode { get; set; }
    @AuraEnabled
    public Decimal voucherAmount { get; set; }
    @AuraEnabled
    public String currencyCode { get; set; }

}