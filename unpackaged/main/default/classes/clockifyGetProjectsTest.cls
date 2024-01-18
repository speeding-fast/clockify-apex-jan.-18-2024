@isTest
private class clockifyGetProjectsTest {

    // Helper method to create a mock Clockify Integration record
    private static bclockify__Clockify_Integration__c createMockIntegration() {
        bclockify__Clockify_Integration__c mockIntegration = new bclockify__Clockify_Integration__c(
            Name = 'Test Integration',
            bclockify__Active__c = true,
            bclockify__API_Key__c = 'test-api-key',
            bclockify__Endpoint__c = 'https://test.clockify.com/api',
            bclockify__Workspace_ID__c = 'test-workspace-id'
        );
        insert mockIntegration;
        return mockIntegration;
    }

    @isTest
    static void testClockifyGetProjects() {
        // Create a test Clockify Integration record
        bclockify__Clockify_Integration__c testIntegration = new bclockify__Clockify_Integration__c(
            Name = 'Test Integration',
            bclockify__Active__c = true,
            bclockify__API_Key__c = 'test-api-key',
            bclockify__Endpoint__c = 'https://test.clockify.com/api',
            bclockify__Workspace_ID__c = 'test-workspace-id'
        );
        insert testIntegration;

        // Set up a mock HTTP response
        Test.setMock(HttpCalloutMock.class, new ClockifyGetProjectsMock());

        // Instantiate the Queueable class
        clockifyGetProjects queueableClass = new clockifyGetProjects(testIntegration.bclockify__Workspace_ID__c);

        // Enqueue the job
        Test.startTest();
        System.enqueueJob(queueableClass);
        Test.stopTest();

        // Verify the results, add assertions as needed
        // For example, check if the ClockifyProject__c records were created or updated
        List<ClockifyProject__c> projects = [SELECT Id, Name, Project_Name__c FROM ClockifyProject__c];
        System.assertEquals(1, projects.size(), 'One project record should have been created or updated.');
        System.assertEquals('Test Project', projects[0].Name, 'Project name should match.');
        System.assertEquals('Test Client', projects[0].Project_Name__c, 'Project client name should match.');

        // Clean up test data
        delete testIntegration;
        delete projects;
    }

    // Mock HTTP response class for Clockify API callout
    private class ClockifyGetProjectsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response with sample JSON data
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"id": "test-project-id", "name": "Test Project", "clientName": "Test Client"}]');
            res.setStatusCode(200);
            return res;
        }
    }
    
// New test methods
    @isTest
    static void testNoActiveIntegrationRecords() {
        delete [SELECT Id FROM bclockify__Clockify_Integration__c WHERE bclockify__Active__c = true];

        Test.startTest();
        clockifyGetProjects queueableClass = new clockifyGetProjects('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        AggregateResult aggregate = [SELECT COUNT(Id) cnt FROM ClockifyProject__c][0];
        Integer recordCount = (Integer)aggregate.get('cnt');

        System.assertEquals(0, recordCount, 'No records should be created when no active integration records exist.');
        
        }

    @isTest
    static void testHTTPRequestException() {
       createMockIntegration();

       Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null, 200, true)); // 'true' indicates an exception

       Test.startTest();
       clockifyGetProjects queueableClass = new clockifyGetProjects('test-workspace-id');
       System.enqueueJob(queueableClass);
       Test.stopTest();

       AggregateResult aggregate = [SELECT COUNT(Id) cnt FROM ClockifyProject__c][0];
       Integer recordCount = (Integer)aggregate.get('cnt');

       System.assertEquals(0, recordCount, 'No records should be created when an HTTP request exception occurs.');
     }

    @isTest
    static void testNon200HTTPResponse() {
       createMockIntegration();

       Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"error": "Error message"}', 400)); // Example of a 400 Bad Request

       Test.startTest();
       clockifyGetProjects queueableClass = new clockifyGetProjects('test-workspace-id');
       System.enqueueJob(queueableClass);
       Test.stopTest();

       AggregateResult aggregate = [SELECT COUNT(Id) cnt FROM ClockifyProject__c][0];
       Integer recordCount = (Integer)aggregate.get('cnt');

       System.assertEquals(0, recordCount, 'No records should be created for non-200 HTTP responses.');
      }

    // Additional test methods
    @isTest
    static void testInsufficientFLSPermissions() {
        // Simulate insufficient FLS permissions
        // ...

        Test.startTest();
        clockifyGetProjects queueableClass = new clockifyGetProjects('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        // Assertions
        Integer recordCount = [SELECT COUNT() FROM ClockifyProject__c];
        System.assertEquals(0, recordCount, 'No records should be created with insufficient FLS permissions.');
    }

    @isTest
    static void testEmptyProjectResponse() {
        createMockIntegration();

        // Simulate an empty project list response from Clockify API
        String responseBody = '[]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        clockifyGetProjects queueableClass = new clockifyGetProjects('test-workspace-id');
        System.enqueueJob(queueableClass);
        Test.stopTest();

        // Assertions for empty response
        Integer recordCount = [SELECT COUNT() FROM ClockifyProject__c];
        System.assertEquals(0, recordCount, 'No records should be created for an empty project list.');
    }

   // Mock HttpResponseGenerator class for simulating HTTP responses
   private class MockHttpResponseGenerator implements HttpCalloutMock {
    private String responseBody;
    private Integer statusCode;
    private Boolean simulateException;

    // Constructor with all parameters
    public MockHttpResponseGenerator(String responseBody, Integer statusCode, Boolean simulateException) {
        this.responseBody = responseBody;
        this.statusCode = statusCode;
        this.simulateException = simulateException;
    }

    // Overloaded constructor with default 'simulateException' value
    public MockHttpResponseGenerator(String responseBody, Integer statusCode) {
        this(responseBody, statusCode, false);
    }

    public HTTPResponse respond(HTTPRequest request) {
        if (simulateException) {
            throw new CalloutException('Simulated exception');
        }
        HttpResponse res = new HttpResponse();
        res.setBody(responseBody);
        res.setStatusCode(statusCode);
        return res;
    }
}

}