public without sharing class Segments extends fflib_SObjectDomain {
  public Segments(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
    this.instanceRecords = (List<Segment__c>) Records;
  }

  public List<Segment__c> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Segments(records);
    }
  }

  public static Segments newInstance(List<Segment__c> sObjectList) {
    return (Segments) SAS_Service_Application.Domain.newInstance(sObjectList);
  }
}
