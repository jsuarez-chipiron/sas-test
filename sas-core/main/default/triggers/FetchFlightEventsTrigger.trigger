trigger FetchFlightEventsTrigger on Fetch_Flight__e(after insert) {
  FetchFlightEvents.onAfterInsert(Trigger.New);
}
