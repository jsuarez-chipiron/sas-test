public without sharing class ContentVersions extends fflib_SObjectDomain {
  public ContentVersions(List<SObject> records) {
    super(records);
    Configuration.disableTriggerCRUDSecurity();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new ContentVersions(records);
    }
  }

  public static ContentVersions newInstance(List<ContentVersion> sObjectList) {
    return (ContentVersions) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public override void onAfterInsert() {
    handleRacerFiles();
  }

  private void handleRacerFiles() {
    List<Id> racerFileIds = new List<Id>();

    for (ContentVersion cv : (List<ContentVersion>) Records) {
      if (RacerResponseHandlers.isARacerFile(cv.Title)) {
        racerFileIds.add(cv.Id);
      }
    }

    RacerResponseHandlers.handle(racerFileIds);
  }
}