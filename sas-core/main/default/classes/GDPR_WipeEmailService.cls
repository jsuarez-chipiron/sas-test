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
    global static void deleteEmailMessageAttachmentandFiles(EmailMessage[] emailmesgList){
        Set<Id> setEmailMsgIds =  C_Util.getIdSet(emailmesgList);
        deleteRelatedEntities(setEmailMsgIds);
    }
    /**
delete related entities of EmailMessage
@Param set of EmailMessageIds
*/
    global static void deleteRelatedEntities(Set<Id> emailMsgIds){
        List<ContentDocument> cdDelList; // content document delete list
        List<Attachment> lstAttchments = [Select Id from Attachment where parentId=:emailMsgIds];
        Set<Id> setContDocIds; // set to identify duplicate content document
        ContentDocumentLink[] cdlList = [SELECT Id,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :emailMsgIds];
        if(!cdlList.isEmpty())
        {
            cdDelList = new List<ContentDocument>();
            setContDocIds = new Set<Id>();
            for(ContentDocumentLink cdl :cdlList){
                {   if(!setContDocIds.contains(cdl.ContentDocumentId))
                {
                    cdDelList.add(new ContentDocument(Id=cdl.ContentDocumentId));
                }
                }
                delete cdDelList;
            } 
        }
        delete lstAttchments;
    }
}