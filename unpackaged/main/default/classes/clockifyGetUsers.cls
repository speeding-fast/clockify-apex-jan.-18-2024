public class clockifyGetUsers implements Queueable, Database.AllowsCallouts {
    private String ENDPOINT_BASE;
    private String API_KEY;
    private String workspaceId;
    public clockifyGetUsers(String workspaceId) {
        this.workspaceId = workspaceId;
        initializeIntegrationDetails();
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
        } else {
            throw new ClockifyException('No active Clockify Integration record found.');
        }
    }
    public class User {
        public String id;
        public String name;
        public String email;
    }
    public void execute(QueueableContext context) {
        String endpoint = ENDPOINT_BASE + '/workspaces/' + this.workspaceId + '/users';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('X-Api-Key', API_KEY);
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            handleResponse(res);
        } catch (Exception e) {
            System.debug('Exception during HTTP request: ' + e.getMessage());
        }
    }
    private void handleResponse(HttpResponse res) {
        if (res.getStatusCode() == 200) {
            List<User> users = (List<User>) JSON.deserialize(res.getBody(), List<User>.class);
            List<ClockifyUser__c> newUsers = new List<ClockifyUser__c>();
            for (User u : users) {
                ClockifyUser__c newUser = new ClockifyUser__c();
                // Check if fields are createable before setting the values
                if (isFieldCreateable('ClockifyUser__c', 'UserId__c')) {
                    newUser.UserId__c = u.id;
                }
                if (isFieldCreateable('ClockifyUser__c', 'Name')) {
                    newUser.Name = u.name;
                }
                if (isFieldCreateable('ClockifyUser__c', 'Email__c')) {
                    newUser.Email__c = u.email;
                }
                newUsers.add(newUser);
            }
            if (!newUsers.isEmpty()) {
                Database.upsert(newUsers, ClockifyUser__c.fields.UserId__c, false);
            }
        } else {
            System.debug('Error from Clockify API: ' + res.getStatus());
        }
    }
    private Boolean checkFlsPermissions() {
        // Check FLS for Clockify_Integration__c fields
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
    public class ClockifyException extends Exception {}
}