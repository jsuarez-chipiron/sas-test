trigger FetchCAREDataEventsTrigger on Fetch_CARE_Data__e(after insert) {
  FetchCAREDataEvents.onAfterInsert(Trigger.New);
}
