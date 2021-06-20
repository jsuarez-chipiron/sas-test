public inherited sharing class AccountsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Account.Id,
      Account.Name,
      Account.FCS_EBLevel__c,
      Account.FCS_EBNumber__c,
      Account.IsPersonAccount
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Account.SObjectType;
  }

  public List<Account> selectById(Set<Id> ids) {
    return (List<Account>) selectSObjectsById(ids);
  }

  /*public List<Account> selectByIdFull(Set<Id> ids) {
    fflib_QueryFactory accountsQF = newQueryFactory()
      .setCondition('Id in :ids');

    new CasesSelector()
      .configureQueryFactoryFields(
        accountsQF,
        Case.AccountId.getDescribe().getRelationshipName()
      );

    return (List<Account>) Database.query(accountsQF.toSOQL());
  }*/

  public List<Account> selectByEuroBonusNumber(Set<String> euroBonusNumbers) {
    return (List<Account>) Database.query(
      newQueryFactory()
        .setCondition('FCS_EBNumber__c in :euroBonusNumbers')
        .toSOQL()
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
