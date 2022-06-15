/**
* @author Gaurav Singh, Coforge
* @date 2022
*
* @description Test class for IRR_SEL_AutomatedService Selector.
*/

@IsTest
public class AutomatedServiceClassSelectortest {

    @IsTest
    static void testgetSObjectFieldList() {
        Test.startTest();
        IRR_SEL_AutomatedServiceClassSelector obj = new IRR_SEL_AutomatedServiceClassSelector();
        obj.getSObjectFieldList();
        obj.selectAutomatedServiceClass();
        IRR_SEL_AutomatedServiceClassSelector.newInstance();
        Test.stopTest();
    }
}