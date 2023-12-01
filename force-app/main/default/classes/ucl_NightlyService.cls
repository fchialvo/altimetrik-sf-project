public with sharing class ucl_NightlyService implements Schedulable {
  // corresponding classes to represent the structure of the JSON response
  public class ClientResponse {
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
        List<LegalAdvisorResponse> legalAdvisors = parseData(
          response.getBody()
        );
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

  //LEGAL ADVISORS

  private static void upsertLegalAdvisorRecords(
    List<LegalAdvisorResponse> legalAdvisors
  ) {
    List<Legal_Advisor__c> legalAdvisorRecords = new List<Legal_Advisor__c>();

    Set<String> legalAdvisorAccountNumbers = new Set<String>();
    for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {
      legalAdvisorAccountNumbers.add(legalAdvisor.AccountNumber);
    }

    // Query existing legal advisors based on the account numbers in the input list
    Set<String> existingLegalAdvisors = new Set<String>();
    for (Legal_Advisor__c existingLegalAdvisor : [
      SELECT Account_Number__c
      FROM Legal_Advisor__c
      WHERE Account_Number__c IN :legalAdvisorAccountNumbers
    ]) {
      existingLegalAdvisors.add(existingLegalAdvisor.Account_Number__c);
    }

    for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {
      Boolean legalAdvisorExists = existingLegalAdvisors.contains(
        legalAdvisor.AccountNumber
      );
      if (legalAdvisor.AccountStatus == 'Disabled') {
        if (legalAdvisorExists) {
          // if Account Status is now Disabled but the record already exists in the org
          Legal_Advisor__c newLegalAdvisor = createOrUpdateLegalAdvisorRecord(
            legalAdvisor,
            legalAdvisorExists
          );
          legalAdvisorRecords.add(newLegalAdvisor);
        }
      } else {
        // if Account Status is Enabled
        Legal_Advisor__c newLegalAdvisor = createOrUpdateLegalAdvisorRecord(
          legalAdvisor,
          legalAdvisorExists
        );
        legalAdvisorRecords.add(newLegalAdvisor);
      }
    }

    upsert legalAdvisorRecords Legal_Advisor__c.Account_Number__c;
  }

  private static Legal_Advisor__c createOrUpdateLegalAdvisorRecord(
    LegalAdvisorResponse legalAdvisor,
    Boolean legalAdvisorExists
  ) {
    Legal_Advisor__c newLegalAdvisor = legalAdvisorExists
      ? returnExistingLegalAdvisor(legalAdvisor.AccountNumber)
      : new Legal_Advisor__c();

    newLegalAdvisor.Account_Name__c = legalAdvisor.AccountName;
    newLegalAdvisor.Name = legalAdvisor.AccountName;
    newLegalAdvisor.Account_Number__c = legalAdvisor.AccountNumber;
    newLegalAdvisor.Account_Status__c = legalAdvisor.AccountStatus;
    newLegalAdvisor.As_of_Date__c = Date.parse(legalAdvisor.AsOfDate);
    return newLegalAdvisor;
  }

  // CLIENTS

  private static void upsertClientRecords(
    List<Legal_Advisor__c> enabledLegalAdvisors,
    List<LegalAdvisorResponse> legalAdvisors
  ) {
    Quiddity quiddityValue = Request.getCurrent().getQuiddity(); // know if the client is updated by an admin in the Clients record page
    List<Client__c> clientRecords = new List<Client__c>();
    List<String> clientNumbers = new List<String>(); //new Client Records' numbers, for later validation

    //fetch client numbers that already exist in the org
    Set<String> existingClientNumbers = new Set<String>();
    for (Client__c existingClient : [SELECT Client_Number__c FROM Client__c]) {
      existingClientNumbers.add(existingClient.Client_Number__c);
    }

    for (LegalAdvisorResponse legalAdvisor : legalAdvisors) {
      if (
        isLegalAdvisorEnabled(enabledLegalAdvisors, legalAdvisor.AccountNumber)
      ) {
        for (ClientResponse client : legalAdvisor.Clients) {
          // Create new client or update existing client
          Boolean clientExists = existingClientNumbers.contains(
            client.ClientNumber
          );
          Client__c newClient = createOrUpdateClientRecord(
            legalAdvisor,
            client,
            clientExists
          );
          clientRecords.add(newClient);
          clientNumbers.add(newClient.Client_Number__c);
        }
      }
    }
    switch on quiddityValue {
      when VF {
        upsert clientRecords;
      }
      when else {
        for (String existingClient : existingClientNumbers) {
          if (!clientNumbers.contains(existingClient)) {
            Client__c client = returnExistingClient(existingClient);
            delete client; //if an existing client is no longer coming in the JSON file, it has to be deleted from the Org.
          }
        }
      }
    }
    upsert clientRecords;
  }

  private static Client__c createOrUpdateClientRecord(
    LegalAdvisorResponse legalAdvisor,
    ClientResponse client,
    Boolean clientExists
  ) {
    // create a new client or update existing
    Client__c newClient = clientExists
      ? returnExistingClient(client.ClientNumber)
      : new Client__c();

    newClient.First_Name__c = client.FirstName;
    newClient.Last_Name__c = client.LastName;
    newClient.Name = client.FirstName + ' ' + client.LastName;
    newClient.Email__c = client.Email;
    newClient.Phone__c = client.Phone;
    newClient.Address__c = client.Address;
    newClient.Client_Number__c = client.ClientNumber;
    newClient.Legal_Advisor__r = new Legal_Advisor__c(
      Account_Number__c = legalAdvisor.AccountNumber
    );

    return newClient;
  }

  //Helper methods
  private static Boolean isLegalAdvisorEnabled(
    List<Legal_Advisor__c> enabledLegalAdvisors,
    String accountNumber
  ) {
    for (Legal_Advisor__c legalAdvisor : enabledLegalAdvisors) {
      if (legalAdvisor.Account_Number__c == accountNumber) {
        return true;
      }
    }
    return false;
  }

  private static Client__c returnExistingClient(String clientNumber) {
    List<Client__c> existingClient = [
      SELECT
        Client_Number__c,
        First_Name__c,
        Last_Name__c,
        Email__c,
        Phone__c,
        Address__c
      FROM Client__c
      WHERE Client_Number__c = :clientNumber
      LIMIT 1
    ];

    return existingClient[0];
  }
  private static Legal_Advisor__c returnExistingLegalAdvisor(
    String accountNumber
  ) {
    List<Legal_Advisor__c> existingLegalAdvisor = [
      SELECT
        Account_Name__c,
        Name,
        Account_Number__c,
        Account_Status__c,
        As_of_date__c
      FROM Legal_Advisor__c
      WHERE Account_Number__c = :accountNumber
      LIMIT 1
    ];
    return existingLegalAdvisor[0];
  }

  private static void handleException(Exception e) {
    // Log the entire exception, including the stack trace
    System.debug(LoggingLevel.ERROR, e);
    // Handle exceptions (log, throw, or propagate)
    // You might want to log the exception or throw it depending on your use case
  }
}
