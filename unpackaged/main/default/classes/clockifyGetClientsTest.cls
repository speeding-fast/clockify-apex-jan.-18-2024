@isTest
public class clockifyGetClientsTest {

    // Method to create a mock Clockify Integration record
    private static bclockify__Clockify_Integration__c createtestIntegration() {
        bclockify__Clockify_Integration__c testIntegration = new bclockify__Clockify_Integration__c(
            Name = 'Test Integration',
            bclockify__Active__c = true,
            bclockify__API_Key__c = 'test-api-key',
            bclockify__Endpoint__c = 'https://test.clockify.com/api',
            bclockify__Workspace_ID__c = 'test-workspace-id'
        );
        insert testIntegration;
        return testIntegration;
    }    

    @isTest
    static void testClockifyGetClients() {
        bclockify__Clockify_Integration__c testIntegration = createtestIntegration();
  
        // Set up a mock HTTP response
        Test.setMock(HttpCalloutMock.class, new ClockifyGetClientsMock());

        // Instantiate the Queueable class
        clockifyGetClients queueableClass = new clockifyGetClients(testIntegration.bclockify__Workspace_ID__c);
        
        // Enqueue the job
        Test.startTest();
        System.enqueueJob(queueableClass);
        Test.stopTest(); // Moved this line to this location

        // Verify the results, add assertions as needed
        // For example, check if the ClockifyClient__c records were created or updated
        List<ClockifyClient__c> clients = [SELECT Id, Name FROM ClockifyClient__c];
        System.assertEquals(1, clients.size(), 'One client record should have been created or updated.');

        // Add a debug statement to check the client name
        System.debug('Client Name: ' + clients[0].Name);

        // Assert the client name
        System.assertEquals('Test Client', clients[0].Name, 'Client name should match.');

        // Clean up test data
        delete testIntegration;
        delete clients;
    }

    @isTest
    static void testNoActiveIntegrationRecords() {
        delete [SELECT Id FROM bclockify__Clockify_Integration__c WHERE bclockify__Active__c = true];

        Test.startTest();
        clockifyGetClients queueableClass = new clockifyGetClients('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyClient__c], 'No clients should be created without active integration records.');
    }

    @isTest
    static void testInsufficientFLSPermissions() {
        // Assuming a method to simulate insufficient FLS permissions
        // ...

        Test.startTest();
        clockifyGetClients queueableClass = new clockifyGetClients('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyClient__c], 'No clients should be created with insufficient FLS permissions.');
    }

    @isTest
    static void testDifferentHTTPResponses() {
        createtestIntegration();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"error": "Error message"}', 400)); // Example of a Bad Request

        Test.startTest();
        clockifyGetClients queueableClass = new clockifyGetClients('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyClient__c], 'No clients should be created for non-200 HTTP responses.');
    }

    @isTest
    static void testEmptyClientResponse() {
        createtestIntegration();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('[]', 200));

        Test.startTest();
        clockifyGetClients queueableClass = new clockifyGetClients('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyClient__c], 'No clients should be created for an empty client list.');
    }

    // Mock HTTP response class for Clockify API callout
    private class ClockifyGetClientsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response with sample JSON data
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"id": "test-client-id", "name": "Test Client"}]');
            res.setStatusCode(200);
            return res;
        }
    }
}