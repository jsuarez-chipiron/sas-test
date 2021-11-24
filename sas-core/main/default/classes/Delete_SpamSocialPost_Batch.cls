/*
Batch calss to delete spammed Social Post.
22-Nov-2021
*/

global class Delete_SpamSocialPost_Batch extends SBS_ScheduledBatch
{
    List<String> lstSpamTags = new List<String>();
    global override void setVariables(
        String sObj,
        Integer retentionPeriod,
        string caseField,
        String caseType,
        String batchName
    ) {
     
    }
    
    global Delete_SpamSocialPost_Batch()
    {
       List<Social_Post_Spam_Hash_Tags__c> spamSocialPostTags = Social_Post_Spam_Hash_Tags__c.getall().values();
        for(Social_Post_Spam_Hash_Tags__c sp:spamSocialPostTags )
        {
            lstSpamTags.add(sp.Spam_Hash_Tag__c);
        }
    }
    /**
Iterates over all interactions to be processed
@param bc The batch context
*/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        string status = 'Needed';
        
        return Database.getQueryLocator('SELECT Content,Id,ReviewedStatus FROM SocialPost WHERE ReviewedStatus =:status');  
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
        for(SocialPost sc : (SocialPost[])sObjScope)
        {
            for(String spamTag : lstSpamTags)
            {
                if(sc.Content.contains(spamTag))
                {
                    lstDelSocialPosts.add(sc);
                    break;
                } 
            }
        }
        delete lstDelSocialPosts;
        
    }
}