public inherited sharing class ContentVersionsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      ContentVersion.Id,
      ContentVersion.ContentDocumentId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return ContentVersion.SObjectType;
  }

  public List<ContentVersion> selectById(Set<Id> ids) {
    return (List<ContentVersion>) selectSObjectsById(ids);
  }
}
