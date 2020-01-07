
 /**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description Factory class used to generate commonly used test data
 */

@isTest
public class FCS_TestDataFactory {
    /**
        Sequence number used to seed unique fields to ensure no collisions occur
    */
    public static Integer SEQ_NUM = 0;

    /**
    * Creates cases with minimal info, as well as Account and Contact if supplied number of case + record type
    * @param numCases Number of cases to be created
    * @param accId Id for account to create case with (null is acceptable)
    * @param conId Id for contact to create case with (null is acceptable)
    * @param rtId Id of the record type to be created (null is acceptable)
    * @param reason String of the case reason. Default value: Baggage (null is acceptable)
    *
    * @return list of new cases
    */
    public static List<Case> createCases(Integer numCases, Id accId, Id conId, Id rtId, String reason) {
        List<Case> newCases = new List<Case>();
        for (Integer i = 0, sz = numCases; i < sz; i++) {
            Case c = new Case();
            c.Subject = 'c';
            c.AccountId = accId;
            c.ContactId = conId;
            if (rtId != null)c.RecordTypeId = rtId;
            c.Reason = reason == null ? 'Baggage' : reason;
            newCases.add(c);
        }
        return newCases;
    }


    /**
    * Creates social post with minimal info
    * @param numSocialPosts Number of social posts to be created
    * @return list of social posts
    */
    public static List<SocialPost> createSocialPosts(Integer numSocialPosts) {
        List<SocialPost> newSocialPosts = new List<SocialPost>();
        for (Integer i = 0, sz = numSocialPosts; i < sz; i++) {
            SocialPost sp = new SocialPost (Name='Test'+i, Headline='TestHeadLine'+i, Posted=system.now());
            newSocialPosts.add(sp);
        }
        return newSocialPosts;
    }

    /**
        Creates frequent flyers which cna be used in the test methods
        @param numAccounts The number of accounts to create
        @return The list of accounts (Not Saved)
    */
    public static Account[] createFrequentFlyers(Integer numAccounts){
        Account[] accs = new Account[numAccounts];
        for(Integer i=0;i<numAccounts;i++){
            Account acc = new Account();
            acc.RecordTypeId = RecordTypeHelper.ACCOUNT_PERSON_EBCUSTOMER;
            acc.FirstName = 'TestFirstName';
            acc.LastName = 'TestLastName';
            acc.CODSId__c = 'TEST'+SEQ_NUM;
            acc.PersonEmail = 'test@test.com';
            acc.PersonMobilePhone = '+46701234567';
            acc.PersonHomePhone = '+4681234567';
            acc.Gender__c = (SEQ_NUM & 1) > 0 ? 'F' : 'M';
            acc.FrequentFlyer__c = acc.CODSId__c;
            acc.PersonBirthDate = Date.newInstance(1990 - Math.mod(SEQ_NUM,50),Math.mod(SEQ_NUM,12)+1,Math.mod(SEQ_NUM,29)+1);
            acc.EBNumber__c = 'EBTEST'+SEQ_NUM;
            acc.EBLevel__c = (SEQ_NUM & 3) < 2 ? 'B' : (SEQ_NUM & 3) < 3 ? 'S' : 'G';
            acc.EBMbrshipLvlStatusStartDate__c = Date.today().toStartOfMonth();
            acc.EBMbrshipLvlStatusEndDate__c = acc.EBMbrshipLvlStatusStartDate__c.addYears(1);
            SEQ_NUM++;
            accs[i] = acc;
        }
        return accs;
    }
}