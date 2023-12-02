@isTest
private class ucl_NightlyServiceTest {
    @isTest
    static void testProcessData() {
        Test.setMock(HttpCalloutMock.class, new ucl_NightlyServiceMock());
        ucl_NightlyService.processData();

       	List<Legal_Advisor__c> enabledLegalAdvisors = [SELECT Account_Number__c, Account_Status__c FROM Legal_Advisor__c WHERE Account_Status__c = 'Enabled'];
        List<Legal_Advisor__c> legalAdvisor = [SELECT Account_Name__c, Account_Number__c FROM Legal_Advisor__c WHERE Account_Number__c = '9afccdd3-e7c4-4789-a465-1734886633d2'];
        System.assertEquals(1, legalAdvisor.size());
        System.assertEquals('Centidel', legalAdvisor[0].Account_Name__c);
        System.assertEquals(true, ucl_NightlyService.isLegalAdvisorEnabled(enabledLegalAdvisors, legalAdvisor[0].Account_Number__c));

    }
    @isTest
    static void testExistingData(){
       // Set up test data
       Legal_Advisor__c existingLegalAdvisor = new Legal_Advisor__c(
            Account_Number__c = '123',
            Account_Status__c = 'Enabled'
        );
        insert existingLegalAdvisor;
        Test.startTest();
       	Test.setMock(HttpCalloutMock.class, new ucl_NightlyServiceMock());  
        ucl_NightlyService.processData();
        Test.stopTest();
        List<Legal_Advisor__c> updatedLegalAdvisor = [SELECT Account_Number__c, Account_Status__c FROM Legal_Advisor__c WHERE Account_Number__c = '123'];
        List<Legal_Advisor__c> enabledLegalAdvisors = [SELECT Account_Number__c, Account_Status__c FROM Legal_Advisor__c WHERE Account_Status__c = 'Enabled'];

        System.assertEquals(1, updatedLegalAdvisor.size());
        System.assertEquals('Disabled', updatedLegalAdvisor[0].Account_Status__c);
        System.assertEquals(false, ucl_NightlyService.isLegalAdvisorEnabled(enabledLegalAdvisors, updatedLegalAdvisor[0].Account_Number__c));
    }

    @isTest
	static void testDeletingClients(){
       // Set up test data
       	ucl_TestDataFactory.createTestRecords(1, 2);
        Test.startTest();
       	Test.setMock(HttpCalloutMock.class, new ucl_NightlyServiceMock());  
        ucl_NightlyService.processData();
        Test.stopTest();
        List<Client__c> oldClient = [SELECT Client_Number__c FROM Client__c WHERE First_Name__c = 'Test'];

        System.assertEquals(0, oldClient.size());
    } 
    
    @isTest
    static void testErrorHandling(){
        // Mock an exception that might occur during processing
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ucl_ErrorMock());
        ucl_NightlyService.processData();
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
		
        // Validate that the error has been logged
        List<Error_Log__c> errorLogs = [SELECT Name FROM Error_Log__c];
        System.assertNotEquals(0, errorLogs.size());
        // Validate that an email has been sent
        system.assertEquals(1, invocations, 'An email should be sent');
        
    }
  
}