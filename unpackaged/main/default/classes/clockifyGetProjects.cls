public without sharing class clockifyGetProjects implements Queueable, Database.AllowsCallouts {

    // Declare variables to store integration record details
    private String ENDPOINT_BASE;
    private String API_KEY;
    private String workspaceId;

    // Constructor to initialize integration details
    public clockifyGetProjects(String workspaceId) {
        this.workspaceId = workspaceId;
        initializeIntegrationDetails();
    }

    private void initializeIntegrationDetails() {
       // Check FLS before accessing Clockify Integration fields
        if (!checkFlsPermissions()) {
            System.debug('Insufficient FLS permissions. Aborting operation.');
            return;
        }
        // Query a single Clockify Integration record where the checkbox field 'Active__c' is true
        List<bclockify__Clockify_Integration__c> integrationDetailsList = [SELECT Id, Name, bclockify__API_Key__c, bclockify__Endpoint__c, bclockify__Workspace_ID__c FROM bclockify__Clockify_Integration__c WHERE bclockify__Active__c = true LIMIT 1];

        if (!integrationDetailsList.isEmpty()) {
            // Assume only one integration record is active; you may need to handle multiple records accordingly
            bclockify__Clockify_Integration__c integrationDetails = integrationDetailsList[0];

            // Assign Integration Details to variables
            ENDPOINT_BASE = integrationDetails.bclockify__Endpoint__c;
            API_KEY = integrationDetails.bclockify__API_Key__c;
        } else {
            System.debug('No active Clockify Integration record found.');
        }
    }

    public class Project {
        public String id;
        public String name;
        public String clientName;
    }

    public void execute(QueueableContext context) {
        // Ensure integration details are initialized before proceeding
        if (String.isBlank(ENDPOINT_BASE) || String.isBlank(API_KEY) || String.isBlank(workspaceId)) {
            System.debug('Integration details are missing. Aborting operation.');
            return;
        }

        String endpoint = ENDPOINT_BASE + '/workspaces/' + this.workspaceId + '/projects';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('X-Api-Key', API_KEY);

        Http http = new Http();
        HttpResponse res = http.send(req);

        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug('Exception during HTTP request to Clockify: ' + e.getMessage());
            return;
        }

        if (res.getStatusCode() == 200) {
            // Parse JSON response into a list of Project objects
            List<Project> projects = (List<Project>) JSON.deserialize(res.getBody(), List<Project>.class);

            // Create a new list of ClockifyProject__c to be inserted or updated
            List<ClockifyProject__c> newProjects = new List<ClockifyProject__c>();

            for (Project p : projects) {
               if (isFieldCreateable('ClockifyProject__c', 'ProjectId__c') && isFieldCreateable('ClockifyProject__c', 'Name') && isFieldCreateable('ClockifyProject__c', 'Project_Name__c')){
                ClockifyProject__c newProject = new ClockifyProject__c();

                // Salesforce Clockify Projects
                newProject.ProjectId__c = p.id;
                newProject.Name = p.name;
                newProject.Project_Name__c = p.clientName;
                newProjects.add(newProject);
            }
            }
            if (!newProjects.isEmpty()) {
                Database.upsert(newProjects, ClockifyProject__c.fields.ProjectId__c, false);
            }
        } else {
            System.debug('Error from Clockify API: ' + res.getStatus());
            System.debug('Error Message: ' + res.getBody());
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

}