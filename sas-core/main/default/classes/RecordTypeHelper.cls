/**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description  Helper class to simplify retrieval and usage of record types in apex. (New record types still need to be correctly conigured in this class to be supported)
    The class can be used directly as it is lazy initialized upon use by a static block.
	Example of use: RecordTypeHelper.CASE_INFORMATION
 */


public with sharing class RecordTypeHelper {

    /**
    Static variables to store id of record types on case object
    */
    public static final Id CASE_INFORMATION;
    public static final Id CASE_FEEDBACK;
    public static final Id CASE_SUPPORT;
    public static final Id CASE_INTERNAL_BACKOFFICE;

    static {
        RecordType[] rtList = [SELECT Id,SobjectType,DeveloperName FROM RecordType WHERE SobjectType ='Case' ];
        for (Integer i = 0, sz = rtList.size(); i < sz; i++) {
            RecordType rt = rtList[i];
            if (rt.SobjectType == 'Case') {
                if (rt.DeveloperName == 'Information') CASE_INFORMATION = rt.Id;
                if (rt.DeveloperName == 'Feedback') CASE_FEEDBACK = rt.Id;
                if (rt.DeveloperName == 'Support') CASE_SUPPORT = rt.Id;
                if(rt.DeveloperName == 'Internal_Backoffice') CASE_INTERNAL_BACKOFFICE = rt.Id;
            }
        }
    }
}