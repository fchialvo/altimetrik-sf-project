/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
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
       	TestDataFactory.createTestRecords(1, 2);
        Test.startTest();
       	Test.setMock(HttpCalloutMock.class, new ucl_NightlyServiceMock());  
        ucl_NightlyService.processData();
        Test.stopTest();
        List<Client__c> oldClient = [SELECT Client_Number__c FROM Client__c WHERE First_Name__c = 'Test'];

        System.assertEquals(0, oldClient.size());
    }    
}