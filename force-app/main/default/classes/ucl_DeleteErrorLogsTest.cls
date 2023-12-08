@isTest
public class ucl_DeleteErrorLogsTest {
	@isTest
    static void test() {
        Test.startTest();
        ucl_DeleteErrorLogs myClass = new ucl_DeleteErrorLogs();
        String chron = '0 0 23 * * ?';        
        DateTime oldDate = DateTime.now().addDays(-30);
        Error_Log__c log = new Error_Log__c(Timestamp__c = oldDate);
		insert log;
        system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
       	
        List<Error_Log__c> logs = [SELECT Id, Timestamp__c FROM Error_Log__c WHERE Timestamp__c = :oldDate];
		System.assertEquals(0, logs.size());
    }
}