public class ClockifyService {
    private static String ENDPOINT_BASE;
    private static String API_KEY;
    private static String workspaceId;
    static {
        initializeIntegrationDetails();
    }
    private static void initializeIntegrationDetails() {
        if (!checkFlsPermissions()) {
            throw new ClockifyException('Insufficient FLS permissions on Clockify_Integration__c. Aborting operation.');
        }
        List<bclockify__Clockify_Integration__c> integrationDetails = [
            SELECT Id, bclockify__Endpoint__c, bclockify__API_Key__c, bclockify__Workspace_ID__c 
            FROM bclockify__Clockify_Integration__c 
            WHERE bclockify__Active__c = true LIMIT 1
        ];
        if (!integrationDetails.isEmpty()) {
            bclockify__Clockify_Integration__c details = integrationDetails[0];
            ENDPOINT_BASE = details.bclockify__Endpoint__c;
            API_KEY = details.bclockify__API_Key__c;
            workspaceId = details.bclockify__Workspace_ID__c;
        } else {
            System.debug('No active Clockify Integration record found.');
        }
    }
    private static Boolean checkFlsPermissions() {
        return Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__API_Key__c.isAccessible() &&
               Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__Endpoint__c.isAccessible() &&
               Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__Workspace_ID__c.isAccessible();
    }
    public class ClockifyResponse {
        public String id;
        public String description;
        public String userId;
        public String projectId;
        public String taskId;
        public TimeInterval timeInterval;
    }
    public class TimeInterval {
        public DateTime start;
        public DateTime endDateTime;
        public String duration;
    }
    public class Parameters {
        @InvocableVariable
        public String pUserID;
    }
    @InvocableMethod(label = 'Fetch Time Entries Asynchronously' description = 'Fetches time entries for the specified user asynchronously')
    public static void fetchTimeEntriesAsync(List<Parameters> paramsList) {
        for (Parameters params : paramsList) {
            System.enqueueJob(new FetchTimeEntriesJob(params.pUserID));
        }
    }
    public class FetchTimeEntriesJob implements Queueable, Database.AllowsCallouts {
        private String externalUserId;
        public FetchTimeEntriesJob(String externalUserId) {
            this.externalUserId = externalUserId;
        }
        public void execute(QueueableContext context) {
            String endpoint = ENDPOINT_BASE + '/workspaces/' + workspaceId + '/user/' + this.externalUserId + '/time-entries' + '?page-size=65';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('X-Api-Key', API_KEY);
            Http http = new Http();
            HttpResponse res;
            try {
                res = http.send(req);
                if (res.getStatusCode() == 200) {
                    List<ClockifyResponse> responses = (List<ClockifyResponse>) JSON.deserialize(res.getBody(), List<ClockifyResponse>.class);
                    List<ClockifyTimeEntry__c> entries = processClockifyResponses(responses);
                    upsert entries ClockifyTimeEntry__c.Fields.timeEntryID__c;
                } else {
                    System.debug('Error from Clockify API: ' + res.getStatus());
                }
            } catch (Exception e) {
                System.debug('Error during HTTP request: ' + e.getMessage());
            }
        }
        private List<ClockifyTimeEntry__c> processClockifyResponses(List<ClockifyResponse> responses) {
            List<ClockifyTimeEntry__c> entries = new List<ClockifyTimeEntry__c>();
            for (ClockifyResponse response : responses) {
                ClockifyTimeEntry__c entry = new ClockifyTimeEntry__c();
                entry.timeEntryID__c = response.id;
                entry.description__c = response.description;
                entry.startTime__c = response.timeInterval.start;
                entry.endTime__c = response.timeInterval.endDateTime;
                entry.userId__c = response.userId;
                entry.Clockify_User__c = lookupUser(response.userId);
                entry.Clockify_Project__c = lookupProject(response.projectId);
                entry.Clockify_Task__c = lookupTask(response.taskId);
                entries.add(entry);
            }
            return entries;
        }
        private Id lookupUser(String userId) {
            List<ClockifyUser__c> users = [SELECT Id FROM ClockifyUser__c WHERE UserId__c = :userId LIMIT 1];
            return !users.isEmpty() ? users[0].Id : null;
        }
        private Id lookupProject(String projectId) {
            List<ClockifyProject__c> projects = [SELECT Id FROM ClockifyProject__c WHERE ProjectId__c = :projectId LIMIT 1];
            return !projects.isEmpty() ? projects[0].Id : null;
        }
        private Id lookupTask(String taskId) {
            List<ClockifyTask__c> tasks = [SELECT Id FROM ClockifyTask__c WHERE TaskId__c = :taskId LIMIT 1];
            return !tasks.isEmpty() ? tasks[0].Id : null;
        }
    }
    public class ClockifyException extends Exception {}
}