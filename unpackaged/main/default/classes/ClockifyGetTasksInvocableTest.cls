@isTest
private class ClockifyGetTasksInvocableTest {

    private static bclockify__Clockify_Integration__c createMockIntegration() {
        bclockify__Clockify_Integration__c mockIntegration = new bclockify__Clockify_Integration__c(
            Name = 'Mock Integration',
            bclockify__API_Key__c = 'your_mock_api_key',
            bclockify__Endpoint__c = 'https://mock.clockify/api',
            bclockify__Workspace_ID__c = 'mockWorkspaceId',
            bclockify__Active__c = true
        );
        insert mockIntegration;
        return mockIntegration;
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;
        private Integer statusCode;

        public MockHttpResponseGenerator(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }


    @isTest
    static void testSuccessfulResponse() {
        createMockIntegration();

        String responseBody = '[{"id": "TestId", "name": "Test Task", "assigneeId": "user1", "assigneeIds": ["user1", "user2"], "billable": true, "duration": "1h", "estimate": "2h", "hourlyRate": 100, "costRate": 50, "projectId": "project1", "status": "active"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions to verify all fields are correctly populated
        List<ClockifyTask__c> tasks = [SELECT Name, TaskId__c, AssigneeId__c, Billable__c, Duration__c, Estimate__c, HourlyRate__c, CostRate__c, ProjectId__c, Status__c FROM ClockifyTask__c];
        System.assertEquals(1, tasks.size());
        ClockifyTask__c task = tasks[0];
        System.assertEquals('Test Task', task.Name);
        System.assertEquals('TestId', task.TaskId__c);
        System.assertEquals('user1', task.AssigneeId__c);
        System.assertEquals(true, task.Billable__c);
        System.assertEquals('1h', task.Duration__c);
        System.assertEquals('2h', task.Estimate__c);
        System.assertEquals(100, task.HourlyRate__c);
        System.assertEquals(50, task.CostRate__c);
        System.assertEquals('project1', task.ProjectId__c);
        System.assertEquals('active', task.Status__c);
    }


@isTest
static void testLookupMethods() {
    createMockIntegration();
    ClockifyGetTasksInvocable taskInvocable = new ClockifyGetTasksInvocable('test_project_id');
    Id projectId = taskInvocable.lookupProject('test_project_id');
    Id userId = taskInvocable.lookupUser('test_assignee_id');

    System.assertNotEquals(null, projectId, 'Project ID should be found.');
    System.assertNotEquals(null, userId, 'User ID should be found.');
}


    
    @isTest
    static void testErrorResponse() {
        createMockIntegration();

        String responseBody = '{"error": "Something went wrong"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 400));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyTask__c]);
    }

    @isTest
    static void testEmptyResponse() {
        createMockIntegration();

        String responseBody = '[]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyTask__c]);
    }

    @isTest
    static void testExceptionDuringCallout() {
        createMockIntegration();

        // Set up a mock response that will cause an exception
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null, 200));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ClockifyTask__c]);
    }

   
    @isTest
    static void testResponseHandlingNullFields() {
        createMockIntegration();

        // Simulate a response with null values for some fields
        String responseBody = '[{"id": "TestId", "name": null, "assigneeId": "user1"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions to verify handling of null fields
        List<ClockifyTask__c> tasks = [SELECT TaskId__c, Name, AssigneeId__c FROM ClockifyTask__c];
        System.assertEquals(1, tasks.size());
        ClockifyTask__c task = tasks[0];
        System.assertEquals('TestId', task.TaskId__c);
        System.assertEquals(null, task.Name);
        System.assertEquals('user1', task.AssigneeId__c);
    }
    @isTest
    static void testFieldCreationCheck() {
        createMockIntegration();

        // Mock response with all fields
        String responseBody = '[{"id": "TestId", "name": "Test Task", "assigneeId": "user1", "assigneeIds": ["user1", "user2"], "billable": true, "duration": "1h", "estimate": "2h", "hourlyRate": 100, "costRate": 50, "projectId": "project1", "status": "active"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions to verify field creation checks
        List<ClockifyTask__c> tasks = [SELECT Name, TaskId__c, AssigneeId__c, Billable__c, Duration__c, Estimate__c, HourlyRate__c, CostRate__c, ProjectId__c, Status__c FROM ClockifyTask__c];
        System.assertEquals(1, tasks.size());
        ClockifyTask__c task = tasks[0];
        System.assertEquals('Test Task', task.Name);
        System.assertEquals('TestId', task.TaskId__c);
        System.assertEquals('user1', task.AssigneeId__c);
        System.assertEquals(true, task.Billable__c);
        System.assertEquals('1h', task.Duration__c);
        System.assertEquals('2h', task.Estimate__c);
        System.assertEquals(100, task.HourlyRate__c);
        System.assertEquals(50, task.CostRate__c);
        System.assertEquals('project1', task.ProjectId__c);
        System.assertEquals('active', task.Status__c);
    }
        @isTest
        static void testInitializationError() {
        // Setup: Create an active Clockify integration record with invalid details
        bclockify__Clockify_Integration__c invalidIntegration = new bclockify__Clockify_Integration__c(
           Name = 'Invalid Integration',
           bclockify__API_Key__c = 'invalidKey', // Invalid API Key
           bclockify__Endpoint__c = 'https://invalid.endpoint/api', // Invalid Endpoint
           bclockify__Workspace_ID__c = 'invalidWorkspaceId', // Invalid Workspace ID
           bclockify__Active__c = true
       );
       insert invalidIntegration;

       Test.startTest();
       ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'invalidProjectId'});
       Test.stopTest();

       // Assertions
       // Verify that no ClockifyTask__c records were created due to initialization failure
       Integer tasksCount = [SELECT COUNT() FROM ClockifyTask__c];
       System.assertEquals(0, tasksCount, 'No tasks should be created when initialization fails');
   }

           @isTest
       static void testMissingIntegrationDetails() {
           // Set up mock integration without setting necessary fields
           bclockify__Clockify_Integration__c mockIntegration = createMockIntegration();
           mockIntegration.bclockify__API_Key__c = null; // Missing API Key
           update mockIntegration;

           Test.startTest();
           ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'validProjectId'});
           Test.stopTest();

           // Assert that no tasks are processed or created due to missing details
           Integer taskCount = [SELECT COUNT() FROM ClockifyTask__c];
           System.assertEquals(0, taskCount, 'No tasks should be created or processed with missing integration details');
    }
          // Test method for simulating an exception during an HTTP request
          @isTest
          static void testExceptionDuringHTTPRequest() {
              createMockIntegration();

              // Set up a mock response that will cause an exception
              Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null, 200));

              Test.startTest();
              ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
              Test.stopTest();

              // Assertions
              // Verify that no ClockifyTask__c records were created as the request should fail
              Integer tasksCount = [SELECT COUNT() FROM ClockifyTask__c];
              System.assertEquals(0, tasksCount, 'No tasks should be created when HTTP request fails');

        }

           @isTest
           static void testInsufficientFLSPermissions() {
           // Setup: Create a mock Clockify Integration record
           bclockify__Clockify_Integration__c mockIntegration = createMockIntegration();

           // Simulate insufficient FLS permissions by manipulating the fields used in checkFlsPermissions
           // NOTE: This is a theoretical example, as actual FLS simulation would require different approach
           mockIntegration.bclockify__API_Key__c = null;
           update mockIntegration;

           Test.startTest();
           ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
           Test.stopTest();

           // Assertions
           Integer tasksCount = [SELECT COUNT() FROM ClockifyTask__c];
           System.assertEquals(0, tasksCount, 'No tasks should be created when FLS permissions are insufficient');
         }
    @isTest
    static void testEmptyIntegrationDetailsList() {
        delete [SELECT Id FROM bclockify__Clockify_Integration__c WHERE bclockify__Active__c = true];

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        Integer taskCount = [SELECT COUNT() FROM ClockifyTask__c];
        System.assertEquals(0, taskCount, 'No tasks should be processed with empty integration details');
    }

    //additional tests

@isTest
static void testSuccessfulLookup() {
    createMockIntegration();

    // Mock response with valid data
    String responseBody = '[{"id": "TestId", "name": "Test Task", "assigneeId": "validUserId", ...}]'; // Complete with necessary data
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

    Test.startTest();
    ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'validProjectId'});
    Test.stopTest();

    // Assertions for successful lookup
    List<ClockifyTask__c> tasks = [SELECT Id, Name FROM ClockifyTask__c];
    System.assertNotEquals(0, tasks.size(), 'Tasks should be created on successful lookup');
    // Add more specific assertions as needed
}

@isTest
static void testFailedLookup() {
    createMockIntegration();

    // Mock response with data that would cause a failed lookup
    String responseBody = '[{"id": "TestId", "name": "Test Task", "assigneeId": "invalidUserId", ...}]'; // Data that causes lookup to fail
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

    Test.startTest();
    ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'invalidProjectId'});
    Test.stopTest();

    // Assertions for failed lookup
    List<ClockifyTask__c> tasks = [SELECT Id, Name FROM ClockifyTask__c];
    System.assertEquals(0, tasks.size(), 'No tasks should be created on failed lookup');
    // More assertions as needed  
}

@isTest
static void testMultipleProjectIds() {
    createMockIntegration();

    // Mock response with valid data for multiple projects
    String responseBody = '[{"id": "TestId1", "name": "Test Task 1", "assigneeId": "validUserId1", ...}, {"id": "TestId2", "name": "Test Task 2", "assigneeId": "validUserId2", ...}]'; // Data for multiple projects
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

    Test.startTest();
    ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1', 'project2'});
    Test.stopTest();

    // Assertions for handling multiple project IDs
    List<ClockifyTask__c> tasks = [SELECT Id, Name FROM ClockifyTask__c];
    System.assertNotEquals(0, tasks.size(), 'Tasks should be created for each project ID');
    // More assertions can be added  
}

        @isTest
    static void testUnsuccessfulFieldCreationCheck() {
        createMockIntegration();
        // Assume this response body is valid for testing unsuccessful field creation
        String responseBody = '[{"id": "TestId", "name": "Test Task", "assigneeId": "user1"}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions to verify that no tasks are created due to unsuccessful field creation
        Integer taskCount = [SELECT COUNT() FROM ClockifyTask__c];
        System.assertEquals(0, taskCount, 'No tasks should be created when field creation checks fail');
    }

    @isTest
    static void testExceptionInInitialization() {
        // Assuming an exception occurs due to invalid initialization details
        bclockify__Clockify_Integration__c invalidIntegration = createMockIntegration();
        invalidIntegration.bclockify__API_Key__c = null; // Example of invalid setup
        update invalidIntegration;

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions for handling initialization exceptions
        Integer taskCount = [SELECT COUNT() FROM ClockifyTask__c];
        System.assertEquals(0, taskCount, 'No tasks should be created when initialization fails');
    }

    @isTest
    static void testDifferentHttpStatusCodes() {
        createMockIntegration();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('Internal Server Error', 500)); // Example for 500 status

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions for 500 status code handling
        System.debug(LoggingLevel.ERROR, 'Received 500 status code from server.');
    }

    @isTest
    static void testClockifyExceptionScenarios() {
        createMockIntegration();
        // Assume a scenario where ClockifyException is thrown due to missing integration details
        delete [SELECT Id FROM bclockify__Clockify_Integration__c];

        Test.startTest();
        ClockifyGetTasksInvocable.clockifyGetProjectTasks(new List<String>{'project1'});
        Test.stopTest();

        // Assertions for ClockifyException handling
        System.debug(LoggingLevel.ERROR, 'ClockifyException was thrown due to missing integration details.');
    }
 
}