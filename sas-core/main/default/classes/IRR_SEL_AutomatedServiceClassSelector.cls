/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-07-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class IRR_SEL_AutomatedServiceClassSelector extends fflib_SObjectSelector implements IRR_SEL_IAutomatedServiceClassSelector  {
    
    public static IRR_SEL_IAutomatedServiceClassSelector newInstance() 
    {

        return (IRR_SEL_IAutomatedServiceClassSelector) IRR_Application.Selector.newInstance(
            IRR_Icoupon_Voucher__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            IRR_Icoupon_Voucher__mdt.DeveloperName,
            IRR_Icoupon_Voucher__mdt.MasterLabel,
            IRR_Icoupon_Voucher__mdt.AirportCode__c,
            IRR_Icoupon_Voucher__mdt.CoupanValue__c,
            IRR_Icoupon_Voucher__mdt.Currency__c,
            IRR_Icoupon_Voucher__mdt.Min_Delay__c,
            IRR_Icoupon_Voucher__mdt.Max_Delay__c,
            IRR_Icoupon_Voucher__mdt.ReasonComment__c,
            IRR_Icoupon_Voucher__mdt.Service_Class_Code__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return IRR_Icoupon_Voucher__mdt.SobjectType ;
    }

    public List<IRR_Icoupon_Voucher__mdt> selectAutomatedServiceClass(){

         return Database.query(newQueryFactory().toSOQL());
               
    }

}