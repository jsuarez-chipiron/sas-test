public class IRR_SEL_AutomatedServiceClassSelector extends fflib_SObjectSelector implements IRR_SEL_IAutomatedServiceClassSelector  {
    
    public static IRR_SEL_IAutomatedServiceClassSelector newInstance() 
    {

        return (IRR_SEL_IAutomatedServiceClassSelector) IRR_Application.Selector.newInstance(
            ServiceClass__mdt.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() 
    {

        return new List<Schema.SObjectField> 
        { 

            ServiceClass__mdt.DeveloperName,
            ServiceClass__mdt.MasterLabel,
            ServiceClass__mdt.AirportCode__c,
            ServiceClass__mdt.CoupanValue__c,
            ServiceClass__mdt.Currency__c,
            ServiceClass__mdt.Min_Delay__c,
            ServiceClass__mdt.Max_Delay__c,
            ServiceClass__mdt.Service_Class_Code__c

        };

    }

    public Schema.SObjectType getSObjectType() {

        return ServiceClass__mdt.SobjectType ;
    }

    public List<ServiceClass__mdt> selectAutomatedServiceClass(){

         return Database.query(newQueryFactory().toSOQL());
               
    }

}