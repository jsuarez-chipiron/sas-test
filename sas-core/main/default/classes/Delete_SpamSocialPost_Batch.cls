/*
Batch calss to delete spammed Social Post.
22-Nov-2021
*/

global class Delete_SpamSocialPost_Batch extends SBS_ScheduledBatch {
  List<String> lstSpamTags = new List<String>();
  global override void setVariables(
    String sObj,
    Integer retentionPeriod,
    string caseField,
    String caseType,
    String batchName
  ) {
  }

  global Delete_SpamSocialPost_Batch() {
    List<Spam_Social_Post__c> spamSocialPostTags = Spam_Social_Post__c.getall()
      .values();
    for (Spam_Social_Post__c sp : spamSocialPostTags) {
      lstSpamTags.add(sp.Social_Post_Tag__c);
    }
  }
  /**
Iterates over all interactions to be processed
@param bc The batch context
*/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    string status = 'Needed';

    return Database.getQueryLocator(
      'SELECT Content,Id,ReviewedStatus FROM SocialPost WHERE ReviewedStatus =:status'
    );
  }

  /**
Deletes the interactions which should be deleted according to the retention logic
@param bc The batchable context of the batch job
@param sObjScope The interactions to delete
*/
  global override void executeScope(
    Database.BatchableContext bc,
    SObject[] sObjScope
  ) {
    List<SocialPost> lstDelSocialPosts = new List<SocialPost>();
    for (SocialPost sc : (SocialPost[]) sObjScope) {
      for (String spamTag : lstSpamTags) {
        if (sc.Content.contains(spamTag)) {
          lstDelSocialPosts.add(sc);
          break;
        }
      }
    }
    delete lstDelSocialPosts;
  }
}
