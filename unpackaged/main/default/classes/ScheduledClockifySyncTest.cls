@isTest
private class ScheduledClockifySyncTest {
    public class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"id":"12345","name":"Test Project","clientName":"Test Client"}]');
            res.setStatusCode(200);
            return res;
        }
    }

    // Helper method to create test data
    private static void createTestData() {
        // Insert test Clockify Integration record
        bclockify__Clockify_Integration__c integration = new bclockify__Clockify_Integration__c(
            Name = 'Test Integration',
            bclockify__Active__c = true,
            bclockify__Workspace_ID__c = 'TestWorkspaceId'
            // Add other necessary fields for your integration
        );
        insert integration;

        // Create and insert a ClockifyClient__c record
        bclockify__ClockifyClient__c testClient = new bclockify__ClockifyClient__c(Name = 'Test Client');
        insert testClient;

        // Create and insert a ClockifyUser__c record
        bclockify__ClockifyUser__c testUser = new bclockify__ClockifyUser__c(Name = 'Test User');
        insert testUser;

        // Create and insert a ClockifyProject__c record
        bclockify__ClockifyProject__c testProject = new bclockify__ClockifyProject__c(
            ProjectId__c = '12345',
            Name = 'Test Project',
            bclockify__Clockify_Client_Name__c = testClient.Id,
            bclockify__users__c = testUser.Id
        );
        insert testProject;
    }

    @isTest
    static void testScheduledExecution() {
        // Create test data
        createTestData();

        // Set the mock callout class
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());

        // Schedule the ScheduledClockifySync class
        Datetime dt = Datetime.now().addMinutes(5);
        String cronExp = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        Test.StartTest();
        String jobId = System.schedule('ScheduledClockifySyncTest', cronExp, new ScheduledClockifySync());

        // Query CronTrigger to verify scheduling
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        // Executing the scheduled jobs by calling the Test.stopTest method
        Test.stopTest();

        // Additional assertions after asynchronous code execution
        List<bclockify__ClockifyProject__c> projects = [SELECT ProjectId__c, Name FROM bclockify__ClockifyProject__c];
        List<bclockify__ClockifyClient__c> clients = [SELECT Id, Name FROM bclockify__ClockifyClient__c];
        List<bclockify__ClockifyUser__c> users = [SELECT Id, Name FROM bclockify__ClockifyUser__c];

        // Assertions for created records
        System.assertEquals(1, projects.size());
        System.assertEquals('12345', projects[0].ProjectId__c);
        System.assertEquals('Test Project', projects[0].Name);
        System.assertEquals(1, clients.size());
        System.assertEquals('Test Client', clients[0].Name);
        System.assertEquals(1, users.size());
        System.assertEquals('Test User', users[0].Name);

        // Clean up: Delete the test Clockify Integration record
        bclockify__Clockify_Integration__c integration = [SELECT Id FROM bclockify__Clockify_Integration__c WHERE Name = 'Test Integration' LIMIT 1];
        delete integration;
    }
}