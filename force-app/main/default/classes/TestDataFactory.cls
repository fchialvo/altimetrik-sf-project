@IsTest
public class TestDataFactory {
    public static void createTestRecords(Integer numLegalAdvisors, Integer numClientsPerAdvisor) {
        List<Legal_Advisor__c> legalAdvisors = new List<Legal_Advisor__c>();
        
        for(Integer i=0;i<numLegalAdvisors;i++) {
            Legal_Advisor__c a = new Legal_Advisor__c(Name='TestAccount' + i);
            legalAdvisors.add(a);
        }
        insert legalAdvisors;
        
        List<Client__c> clients = new List<Client__c>();
        for (Integer j=0;j<numLegalADvisors;j++) {
            Legal_Advisor__c legalAdvisor = legalAdvisors[j];            
            // For each account just inserted, add contacts
            for (Integer k=numClientsPerAdvisor*j;k<numClientsPerAdvisor*(j+1);k++) {
                clients.add(new Client__c(First_Name__c='Test',
                                     Last_Name__c='Test',
                                     Legal_Advisor__c=legalAdvisor.Id));
            }
        }
        // Insert all clients for all legal advisors
        insert clients;
    }
}