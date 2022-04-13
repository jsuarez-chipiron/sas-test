public inherited sharing class AccountsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Account.Id,
      Account.Name,
      Account.FCS_CMP__c,
      Account.FCS_EBLevel__c,
      Account.FCS_EBNumber__c,
      Account.FCS_TPAccountNumber__c,
      Account.IsPersonAccount,
      Account.PersonEmail
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Account.SObjectType;
  }

  public static AccountsSelector newInstance() {
    return (AccountsSelector) SAS_Service_Application.Selector.newInstance(
      Account.SObjectType
    );
  }

  public List<Account> selectById(Set<Id> ids) {
    return (List<Account>) selectSObjectsById(ids);
  }

  public List<Account> selectByEuroBonusNumber(Set<String> euroBonusNumbers) {
    return (List<Account>) Database.query(
      newQueryFactory()
        .setCondition('FCS_EBNumber__c in :euroBonusNumbers')
        .toSOQL()
    );
  }

  public List<Account> selectByEmail(Set<String> emails) {
    return (List<Account>) Database.query(
      newQueryFactory().setCondition('PersonEmail in :emails').toSOQL()
    );
  }

  public List<Account> selectByEuroBonusNumberFull(
    Set<String> euroBonusNumbers
  ) {
    fflib_QueryFactory accountsQF = newQueryFactory()
      .setCondition('FCS_EBNumber__c in :euroBonusNumbers');
    fflib_QueryFactory bookings = new BookingsSelector()
      .addQueryFactorySubselect(accountsQF);
    fflib_QueryFactory passengers = new PassengersSelector()
      .addQueryFactorySubselect(bookings);
    fflib_QueryFactory segments = new SegmentsSelector()
      .addQueryFactorySubselect(bookings);

    new FlightsSelector()
      .configureQueryFactoryFields(
        segments,
        Segment__c.Flight__c.getDescribe().getRelationshipName()
      );

    return (List<Account>) Database.query(accountsQF.toSOQL());
  }
}
