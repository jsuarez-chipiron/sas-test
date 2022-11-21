public inherited sharing class EnhancedLetterheadsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      EnhancedLetterhead.Id,
      EnhancedLetterhead.LetterheadFooter,
      EnhancedLetterhead.LetterheadHeader,
      EnhancedLetterhead.Name
    };
  }

  public Schema.SObjectType getSObjectType() {
    return EnhancedLetterhead.SObjectType;
  }

  public static EnhancedLetterheadsSelector newInstance() {
    return (EnhancedLetterheadsSelector) SAS_Service_Application.Selector.newInstance(
      EnhancedLetterhead.SObjectType
    );
  }

  public List<EnhancedLetterhead> selectById(Set<Id> ids) {
    return (List<EnhancedLetterhead>) selectSObjectsById(ids);
  }
}
