global without sharing class ScheduledClockifySync implements Schedulable {
    private String workspaceId;
    global void execute(SchedulableContext SC) {
        if (!checkFlsPermissions()) {
            System.debug('Insufficient FLS permissions. Aborting operation.');
            return;
        }
        
        List<bclockify__Clockify_Integration__c> integrationDetails = [
            SELECT Id, Name, bclockify__Workspace_ID__c 
            FROM bclockify__Clockify_Integration__c 
            WHERE bclockify__Active__c = true LIMIT 1
        ];
        if (!integrationDetails.isEmpty()) {
            workspaceId = integrationDetails[0].bclockify__Workspace_ID__c;
            enqueueJobs(workspaceId);
        } else {
            System.debug('No active Clockify integration found.');
        }
    }
    private Boolean checkFlsPermissions() {
        Set<String> fieldsToCheck = new Set<String>{
            'bclockify__Active__c',
            'bclockify__Workspace_ID__c',
            'Name'
        };
        for (String field : fieldsToCheck) {
            if (!Schema.sObjectType.bclockify__Clockify_Integration__c.fields.getMap().get(field).getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }
    private void enqueueJobs(String workspaceId) {
        System.enqueueJob(new clockifyGetProjects(workspaceId));
        System.enqueueJob(new clockifyGetClients(workspaceId));
        System.enqueueJob(new clockifyGetUsers(workspaceId));
    }
}