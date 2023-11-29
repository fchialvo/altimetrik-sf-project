public with sharing class ucl_NightlyService implements Schedulable {
    // Create a corresponding class to represent the structure of the JSON response
   public class ClientResponse{
       public String FirstName;
       public String LastName;
       public String Email;
       public String Phone;
       public String Address;
       public String ClientNumber;
    }
    public class LegalAdvisorResponse {
       public String AccountNumber;
       public String AccountName;
       public String AccountStatus;
       public String AsOfDate;
       public List<ClientResponse> Clients;
    }

    public void execute(SchedulableContext sc) {
        try {
            processData();
        } catch (Exception e) {
            //implement error handling
        }
    }
    
    public static void processData() {
        try {
            String endpoint = 'https://altimetrik-bootcamp.herokuapp.com/LegalAccounts';
            HttpResponse response = fetchData(endpoint);
    
            if (response.getStatusCode() == 200) {
                List<LegalAdvisorResponse> legalAdvisors = parseData(response.getBody());
                upsertLegalAdvisorRecords(legalAdvisors);
                
                // Retrieve enabled Legal Advisors
                List<Legal_Advisor__c> enabledLegalAdvisors = [
                    SELECT Id, Account_Number__c, Account_Status__c
                    FROM Legal_Advisor__c
                    WHERE Account_Status__c = 'Enabled'
                ];
                // Upsert Clients for enabled Legal Advisors
                upsertClientRecords(enabledLegalAdvisors, legalAdvisors);
           }
        } catch (Exception e) {
            handleException(e);
        }
    }
    
    private static HttpResponse fetchData(String endpoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        
        return http.send(request);
    }
    
    private static List<LegalAdvisorResponse> parseData(String responseBody) {
        return (List<LegalAdvisorResponse>) JSON.deserialize(
            responseBody,
            List<LegalAdvisorResponse>.class
        );
    }
    
    private static void upsertLegalAdvisorRecords(List<LegalAdvisorResponse> legalAdvisors) {
    List<Legal_Advisor__c> existingLegalAdvisors = [SELECT Account_Number__c, Account_Status__c FROM Legal_Advisor__c WHERE Account_Status__c = 'Enabled'];
    List<Legal_Advisor__c> legalAdvisorRecords = new List<Legal_Advisor__c>();
    
    for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {
        if (legalAdvisor.AccountStatus == 'Disabled') {
            // Check if a Legal Advisor with 'Enabled' status already exists
            Boolean enabledLegalAdvisorExists = false;
            for (Legal_Advisor__c existingLegalAdvisor : existingLegalAdvisors) {
                if (existingLegalAdvisor.Account_Number__c == legalAdvisor.AccountNumber) {
                    enabledLegalAdvisorExists = true;
                    break;
                }
            }

            if (enabledLegalAdvisorExists) {
                Legal_Advisor__c newLegalAdvisor = createLegalAdvisorRecord(legalAdvisor);
                legalAdvisorRecords.add(newLegalAdvisor);
            } else {
                System.debug('Account disabled: ' + legalAdvisor.AccountNumber);
            }
        } else {
            Legal_Advisor__c newLegalAdvisor = createLegalAdvisorRecord(legalAdvisor);
            legalAdvisorRecords.add(newLegalAdvisor);
        }
    }  

    upsert legalAdvisorRecords Legal_Advisor__c.Account_Number__c;
}

    
    private static Legal_Advisor__c createLegalAdvisorRecord(LegalAdvisorResponse legalAdvisor) {
        if(legalAdvisor.AccountStatus == 'Enabled'){
            Legal_Advisor__c newLegalAdvisor = new Legal_Advisor__c();
            newLegalAdvisor.Account_Name__c = legalAdvisor.AccountName;
            newLegalAdvisor.Name = legalAdvisor.AccountName;
            newLegalAdvisor.Account_Number__c = legalAdvisor.AccountNumber;
            newLegalAdvisor.Account_Status__c = legalAdvisor.AccountStatus;
            newLegalAdvisor.As_of_Date__c = Date.parse(legalAdvisor.AsOfDate);
            return newLegalAdvisor;
        }
        return null;
    }
    
	private static void upsertClientRecords(List<Legal_Advisor__c> enabledLegalAdvisors, List<LegalAdvisorResponse> legalAdvisors) {
    Set<String> existingClientNumbers = new Set<String>();

    // find existing clients related to enabled legal advisors
    for (AggregateResult result : [
        SELECT Client_Number__c
        FROM Client__c
        WHERE Legal_Advisor__c IN :enabledLegalAdvisors
        GROUP BY Client_Number__c
    ]) {
        existingClientNumbers.add((String) result.get('Client_Number__c'));
    }

    List<Client__c> clientRecords = new List<Client__c>();

    for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {
        if (isLegalAdvisorEnabled(enabledLegalAdvisors, legalAdvisor.AccountNumber)) {
            for (ClientResponse client : legalAdvisor.Clients) {
                // Create new client or update existing client
                Client__c newClient = createOrUpdateClientRecord(legalAdvisor, client);
                clientRecords.add(newClient);
            }
        }
    }

    upsert clientRecords;
}

    
    private static Client__c createOrUpdateClientRecord(LegalAdvisorResponse legalAdvisor, ClientResponse client) {
        List<Client__c> existingClients = [SELECT Client_Number__c FROM Client__c];
        
        // create a new client or update existing
        Client__c newClient = existingClients.toString().contains(client.ClientNumber) ? returnExistingClient(client.ClientNumber) : new Client__c();
    
        newClient.First_Name__c = client.FirstName;
        newClient.Last_Name__c = client.LastName;
        newClient.Name = client.FirstName + ' ' + client.LastName;
        newClient.Email__c = client.Email;
        newClient.Phone__c = client.Phone;
        newClient.Address__c = client.Address;
        newClient.Client_Number__c = client.ClientNumber;
        newClient.Legal_Advisor__r = new Legal_Advisor__c(Account_Number__c = legalAdvisor.AccountNumber);
    
        return newClient;
	}

    
    //Helper methods
    private static Boolean isLegalAdvisorEnabled(List<Legal_Advisor__c> enabledLegalAdvisors, String accountNumber) {
        for (Legal_Advisor__c legalAdvisor : enabledLegalAdvisors) {
            if (legalAdvisor.Account_Number__c == accountNumber) {
                return true;
            }
        }
        return false;
	}
	
    private static Client__c returnExistingClient(String clientNumber) {
         List<Client__c> existingClient = [SELECT Id, Client_Number__c, First_Name__c, Last_Name__c, Email__c, Phone__c, Address__c
                                       FROM Client__c
                                       WHERE Client_Number__c = :clientNumber
                                       LIMIT 1];

        return existingClient[0];
    }		


    private static void handleException(Exception e) {
        // Log the entire exception, including the stack trace
        System.debug(LoggingLevel.ERROR, e);
        // Handle exceptions (log, throw, or propagate)
        // You might want to log the exception or throw it depending on your use case
    }
}