/**
Service class providing the functionality related to EmailMessage
@author Thippeswamy A 
**/
global with sharing class GDPR_WipeEmailService 
{
    
    /**
used the delete the sensitive attachment related to email message
@param list of EmailMessage
*/
    global static void deleteEmailMessageAttachments(EmailMessage[] emailmesgList){
        Set<Id> setEmailMsgIds =  C_Util.getIdSet(emailmesgList);
        deleteRelatedEntities(setEmailMsgIds);
    }
    /**
delete related entities of EmailMessage
@Param set of EmailMessageIds
*/
    global static void deleteRelatedEntities(Set<Id> emailids){
        List<Attachment> lstAttchments = [Select Id from Attachment where parentId=:emailids];
        Delete lstAttchments;
        
    }
}