
 /**
 * @author Sanna Sörberg
 * @date 2019-11-27
 * @description Factory class used to generate commonly used test data
 */

@isTest
public class TestDataFactory {

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

    public static List<SocialPost> createSocialPosts(Integer numSocialPosts) {
        List<SocialPost> newSocialPosts = new List<SocialPost>();
        for (Integer i = 0, sz = numSocialPosts; i < sz; i++) {
            SocialPost sp = new SocialPost (Name='Test'+i, Headline='TestHeadLine'+i, Posted=system.now());
            newSocialPosts.add(sp);
        }
        return newSocialPosts;
    }
}