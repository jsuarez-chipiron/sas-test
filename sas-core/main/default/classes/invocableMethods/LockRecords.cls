public with sharing class LockRecords {
	@InvocableMethod(label='Lock records')
	public static void LockRecord(List<String> recordIds) {
    Set<String> uniqueRecordIds = new Set<String>(recordIds);
    List<String> uniqueRecordIdsAsList = new List<String>(uniqueRecordIds);
		Approval.lock(uniqueRecordIdsAsList);
	}
}
