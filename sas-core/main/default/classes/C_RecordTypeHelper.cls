/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description  Helper class to simplify retrieval and usage of record types in apex. (New record types still need to be correctly conigured in this class to be supported)
    The class can be used directly as it is lazy initialized upon use by a static block.
	Example of use: C_RecordTypeHelper.CASE_INFORMATION
 */
public with sharing class C_RecordTypeHelper {
    /**
    Static variables to store id of record types on case object
    */
    @TestVisible public static final Id CASE_INFORMATION;
    @TestVisible public static final Id CASE_FEEDBACK;
    @TestVisible public static final Id CASE_SUPPORT;
    @TestVisible public static final Id CASE_INTERNAL_BACKOFFICE;

    /**
    Static variables to store id of record types on account object
    */
    @TestVisible public static final Id ACCOUNT_PERSON_EBCUSTOMER;
    @TestVisible public static final Id ACCOUNT_PERSON_ANONYMOUS;

    static {
        RecordType[] rtList = [SELECT Id,SobjectType,DeveloperName FROM RecordType WHERE SobjectType IN ('Case', 'Account') ];
        for (Integer i = 0, sz = rtList.size(); i < sz; i++) {
            RecordType rt = rtList[i];
            if (rt.SobjectType == 'Case') {
                if (rt.DeveloperName == 'Information') CASE_INFORMATION = rt.Id;
                if (rt.DeveloperName == 'Feedback') CASE_FEEDBACK = rt.Id;
                if (rt.DeveloperName == 'Support') CASE_SUPPORT = rt.Id;
                if (rt.DeveloperName == 'Internal_Backoffice') CASE_INTERNAL_BACKOFFICE = rt.Id;
            } else if(rt.SobjectType == 'Account'){
                if (rt.DeveloperName == 'EBCustomer') ACCOUNT_PERSON_EBCUSTOMER = rt.Id;
                if (rt.DeveloperName == 'AnonymousCustomer') ACCOUNT_PERSON_ANONYMOUS = rt.Id;
            }
        }
    }
}