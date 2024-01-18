public without sharing class clockifyGetTasksInvocable implements Queueable, Database.AllowsCallouts {
    private String ENDPOINT_BASE;
    private String API_KEY;
    private String workspaceId;
    private String projectId;
    public clockifyGetTasksInvocable(String projectId) { 
        this.projectId = projectId;
        try {
            initializeIntegrationDetails();
        } catch (Exception e) {
            System.debug('An error occurred during initialization: ' + e.getMessage());
        }
    }
    private void initializeIntegrationDetails() {
        if (!checkFlsPermissions()) {
            throw new ClockifyException('Insufficient FLS permissions on Clockify_Integration__c. Aborting operation.');
        }
        List<bclockify__Clockify_Integration__c> integrationDetailsList = [
            SELECT Id, Name, bclockify__API_Key__c, bclockify__Endpoint__c, bclockify__Workspace_ID__c 
            FROM bclockify__Clockify_Integration__c 
            WHERE bclockify__Active__c = true LIMIT 1
        ];
        if (!integrationDetailsList.isEmpty()) {
            bclockify__Clockify_Integration__c integrationDetails = integrationDetailsList[0];
            ENDPOINT_BASE = integrationDetails.bclockify__Endpoint__c;
            API_KEY = integrationDetails.bclockify__API_Key__c;
            workspaceId = integrationDetails.bclockify__Workspace_ID__c;
        } else {
            throw new ClockifyException('No active Clockify Integration record found.');
        }
    }
    public class Task {
        public String id;
        public String name;
        public String assigneeId;
        public List<String> assigneeIds;
        public Boolean billable;
        public String duration;
        public String estimate;
        public Integer hourlyRate;
        public Integer costRate;
        public String projectId;
        public String status;
        public List<String> userGroupIds;
    }
    @InvocableMethod(label='Get Clockify Tasks: clockifyGetTasksInvocable' description='Retrieves the tasks from Clockify for a specific project.')
    public static void clockifyGetProjectTasks(List<String> projectIds) {
        for (String projectId : projectIds) {
            System.enqueueJob(new clockifyGetTasksInvocable(projectId));
        }
    }
    public void execute(QueueableContext context) {
        if (String.isBlank(ENDPOINT_BASE) || String.isBlank(API_KEY) || String.isBlank(workspaceId)) {
            System.debug('Integration details are missing. Aborting operation.');
            return;
        }
        String endpoint = ENDPOINT_BASE + '/workspaces/' + this.workspaceId + '/projects/' + this.projectId + '/tasks';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('X-Api-Key', API_KEY);
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
            if (res.getStatusCode() == 200) {
                List<Task> tasks = (List<Task>) JSON.deserialize(res.getBody(), List<Task>.class);
                List<ClockifyTask__c> newTasks = new List<ClockifyTask__c>();
                for (Task t : tasks) {
                   if (isFieldCreateable('ClockifyTask__c', 'assigneeId__c') && isFieldCreateable('ClockifyTask__c', 'assigneeIds__c') && isFieldCreateable('ClockifyTask__c', 'billable__c') && isFieldCreateable('ClockifyTask__c', 'Name') && isFieldCreateable('ClockifyTask__c', 'Duration__c') && isFieldCreateable('ClockifyTask__c', 'Estimate__c') && isFieldCreateable('ClockifyTask__c', 'HourlyRate__c') && isFieldCreateable('ClockifyTask__c', 'CostRate__c') && isFieldCreateable('ClockifyTask__c', 'ProjectId__c') && isFieldCreateable('ClockifyTask__c', 'Clockify_Project__c') && isFieldCreateable('ClockifyTask__c', 'Clockify_User__c') && isFieldCreateable('ClockifyTask__c', 'Status__c') && isFieldCreateable('ClockifyTask__c', 'TaskId__c')) {
                    ClockifyTask__c newTask = new ClockifyTask__c();
                    newTask.assigneeId__c = t.assigneeId;
                    newTask.assigneeIds__c = String.join(t.assigneeIds, ',');
                    newTask.billable__c = t.billable;
                    newTask.Name = t.name;
                    newTask.Duration__c = t.duration;
                    newTask.Estimate__c = t.estimate;
                    newTask.HourlyRate__c = t.hourlyRate;
                    newTask.CostRate__c = t.costRate;
                    newTask.ProjectId__c = t.projectId;
                    newTask.Status__c = t.status;
                    newTask.TaskId__c = t.id;
                    Id projId = lookupProject(t.projectId);
                    if (projId != null) {
                        newTask.Clockify_Project__c = projId;
                    }
                    Id userId = lookupUser(t.assigneeId);
                    if(userId != null) {
                        newTask.Clockify_User__c = userId;
                    }
                    newTasks.add(newTask);
                }
                 }
                 if (!newTasks.isEmpty()) {
                Database.upsert(newTasks, ClockifyTask__c.fields.TaskId__c, false);
            }
            } else {
                System.debug('Error from Clockify API: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Exception during HTTP request to Clockify: ' + e.getMessage());
        }
    }
    private Boolean checkFlsPermissions() {
        return Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__Active__c.isAccessible() &&
               Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__API_Key__c.isAccessible() &&
               Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__Endpoint__c.isAccessible() &&
               Schema.sObjectType.bclockify__Clockify_Integration__c.fields.bclockify__Workspace_ID__c.isAccessible();
    }
private Boolean isFieldCreateable(String objectApiName, String fieldApiName) {
    try {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        
        if (objectType != null) {
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            if (fieldMap.containsKey(fieldApiName.toLowerCase())) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName.toLowerCase()).getDescribe();
                return fieldDescribe.isCreateable() && fieldDescribe.isUpdateable();
            } else {
                System.debug('Field not found: ' + fieldApiName);
            }
        } else {
            System.debug('Object not found: ' + objectApiName);
        }
    } catch (Exception e) {
        // Log or handle the exception as needed
        System.debug('Exception in isFieldCreateableAndUpdateable: ' + e.getMessage());
    }
    
    return false;
}
   @TestVisible
    private Id lookupProject(String projectId) {
        ClockifyProject__c project;
        try {
            project = [SELECT Id FROM ClockifyProject__c WHERE ProjectId__c = :projectId LIMIT 1];
            return project.Id;
        } catch (Exception e) {
            System.debug('Error querying for ClockifyProject__c: ' + e.getMessage());
            return null;
        }
    }
    @TestVisible
    private Id lookupUser(String assigneeId) {
        ClockifyUser__c user;
        try {
            user = [SELECT Id FROM ClockifyUser__c WHERE UserId__c = :assigneeId LIMIT 1];
            return user.Id;
        } catch (Exception e) {
            System.debug('Error querying for ClockifyUser__c: ' + e.getMessage());
            return null;
        }
    }
    public class ClockifyException extends Exception {}
}