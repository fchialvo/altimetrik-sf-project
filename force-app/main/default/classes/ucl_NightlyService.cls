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
       // Method to be executed as part of the scheduled job
       try {
           // Fetch and process data from the Heroku service
           processHerokuData();
           logSuccess();
           // Log successful execution
        } catch (Exception e) {
           // Log and handle any exceptions
           logError(e.getMessage());
           
           // Send email notification to system administrators
           sendErrorEmail(e.getMessage());
        }
    }

    public static void processHerokuData() {
       Http http = new Http();
       HttpRequest request = new HttpRequest();
       request.setEndpoint('https://altimetrik-bootcamp.herokuapp.com/LegalAccounts');
       request.setMethod('GET');
       
        try {
           HttpResponse response = http.send(request);
   
           if (response.getStatusCode() == 200) {
               List<LegalAdvisorResponse> legalAdvisors = (List<LegalAdvisorResponse>) JSON.deserialize(
                   response.getBody(),
                   List<LegalAdvisorResponse>.class
               );
               //list for all legal advisors in the JSON file
               List<Legal_Advisor__c> legalAdvisorRecords = new List<Legal_Advisor__c>();
               //list for all the clients
               List<Client__c> clientRecords = new List<Client__c>();
   
               for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {                    
                   //create legal advisor sObject for each item on the list
                   Legal_Advisor__c newLegalAdvisor = new Legal_Advisor__c();
                   newLegalAdvisor.Account_Name__c = legalAdvisor.AccountName;
                   newLegalAdvisor.Account_Number__c = legalAdvisor.AccountNumber;
                   newLegalAdvisor.Account_Status__c = legalAdvisor.AccountStatus;
                   newLegalAdvisor.As_of_Date__c = Date.parse(legalAdvisor.AsOfDate);

                   legalAdvisorRecords.add(newLegalAdvisor);
                }
                                   
                upsert legalAdvisorRecords Legal_Advisor__c.Account_Number__c;

                List<Client__c> RelatedClients = new List<Client__c>();

                for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {                    
                   for(ClientResponse Client: legalAdvisor.Clients){
                       //the same process for its related clients
                       Client__c newClient = new Client__c();
                       newClient.First_Name__c = Client.FirstName;
                       newClient.Last_Name__c = Client.LastName;
                       newClient.Email__c = Client.Email;
                       newClient.Phone__c = Client.Phone;
                       newClient.Address__c = Client.Address;
                       newClient.Client_Number__c = Client.ClientNumber;
                       
                       newClient.Legal_Advisor__r = new Legal_Advisor__c(Account_Number__c = legalAdvisor.AccountNumber);

                        clientRecords.add(newClient);
                   }
               }                

               upsert clientRecords;
            } 
        } catch (Exception e) {
           // Handle exceptions (log, throw, or propagate)
           System.debug('Error: ' + e.getMessage());
        }
    }


   private void logSuccess() {
       System.debug('success!');
   }

   private void logError(String errorMessage) {
       // Implement logging for errors
       // Example: Insert a log record in a custom object with error details
   }

    private void sendErrorEmail(String errorMessage) {
       // Implement sending email notification to system administrators
       // Example: Use the Messaging.SingleEmailMessage class to send an email
       // Include error details in the email body
    }
}