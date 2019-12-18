
@isTest
private class TestDataFactory_Test {
   /* 
@isTest	
	static void insertCaseRecords () {
       List<Case> newCase = TestDataFactory.createDefaultCases(1, null, null, null, null);
        System.assertEquals('c', newCase[0].subject); 
		System.assertEquals (null,newCase[0].accountId);
		System.assertEquals (null,newCase[0].contactId);
		System.assertEquals ('baggage', newCase[0].reason);
		}
@isTest		
	static void insertAccountCase(){
		accountId accId = new accountId (); 
		insert accId; 
		newCase[0].accountId = [select ID FROM Account Limit 1][0].id; 
		List<Case> newCase = TestDataFactory.createDefaultCases(1, newCase[0].accountId, null, null, null);
		System.assertEquals('c', newCase[0].subject); 
		System.assertEquals (accountId, newCase[0].accountId);
		System.assertEquals (null,newCase[0].contactId);
		System.assertEquals ('baggage', newCase[0].reason);
		}
@isTest		
	static void insertContactCase(){
		contactId conId = new contactId (); 
		insert conId; 
		newCase[0].conId = [select ID FROM Contact Limit 1][0].id; 
		List<Case> newCase = TestDataFactory.createDefaultCases(1, null, newCase[0].contactId, null, null);
		System.assertEquals('c', newCase[0].subject); 
		System.assertEquals (null, newCase[0].accountId);
		System.assertEquals (conId, newCase[0].contactId);
		System.assertEquals ('baggage', newCase[0].reason);
		}
@isTest
	static void insertReasonCase(){
		Case c1 = new Case (); 
		insert c1;
        newCase[0].CaseReason__c = 'TestReason 1';
        newCase[0].CaseSubReason__c = 'TestSubReason 1';
		
		List<Case> newCase = TestDataFactory.createDefaultCases(1, null, null, null, newCase[0].CaseReason__c);
		System.assertEquals('c', newCase[0].subject); 
		System.assertEquals (null,newCase[0].accountId);
		System.assertEquals (null,newCase[0].contactId);
		System.assertEquals ('TestReason 1', newCase[0].CaseReason__c);
		}	
	
@isTest 
	static void createSocialPosts 	
      */     
    }
	