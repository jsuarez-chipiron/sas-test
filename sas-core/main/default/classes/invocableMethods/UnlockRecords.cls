public with sharing class UnlockRecords {
	@InvocableMethod(label='Unlock records')
	public static void UnlockRecord(List<String> recordIds) {
    Set<String> uniqueRecordIds = new Set<String>(recordIds);
    List<String> uniqueRecordIdsAsList = new List<String>(uniqueRecordIds);
		Approval.unlock(uniqueRecordIdsAsList);
	}
}
