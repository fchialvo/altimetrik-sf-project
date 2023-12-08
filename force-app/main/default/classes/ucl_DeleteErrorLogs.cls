global class ucl_DeleteErrorLogs implements Schedulable{
    global void execute(SchedulableContext SC) {
       deleteData();
    }
    public static void deleteData() {
        List<Error_Log__c> logs = [select Id FROM Error_Log__c WHERE Timestamp__c = LAST_N_DAYS:30];
        if(!logs.isEmpty())
            delete logs;
     }
}