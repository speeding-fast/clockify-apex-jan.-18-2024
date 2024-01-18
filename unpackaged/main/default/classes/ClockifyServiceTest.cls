@isTest
private class ClockifyServiceTest {


    // Create sample data for ClockifyUser__c, ClockifyProject__c, and ClockifyTask__c
    private static void createSampleData() {
        // Populate with appropriate fields as per your org schema
        ClockifyUser__c user = new ClockifyUser__c(UserId__c = 'testUserID');
        ClockifyProject__c project = new ClockifyProject__c(ProjectId__c = 'sampleProjectId');
        ClockifyTask__c task = new ClockifyTask__c(TaskId__c = 'sampleTaskId');

        insert user;
        insert project;
        insert task;
        // Create a mock Clockify Integration record
        bclockify__Clockify_Integration__c mockIntegration = new bclockify__Clockify_Integration__c(
            Name = 'Mock Integration',
            bclockify__API_Key__c = 'your_mock_api_key',
            bclockify__Endpoint__c = 'https://mock.clockify/api',
            bclockify__Workspace_ID__c = 'mockWorkspaceId',
            bclockify__Active__c = true
        );
        insert mockIntegration;
    }

    @isTest
    static void testQueueableExecution() {
        createSampleData();

        String testUserId = 'testUserID';
        ClockifyService.FetchTimeEntriesJob job = new ClockifyService.FetchTimeEntriesJob(testUserId);

        String responseBody = '[{"id": "sampleId", "description": "sampleDescription", "userId": "testUserID", "projectId": "sampleProjectId", "taskId": "sampleTaskId", "timeInterval": {"start": "2023-01-01T00:00:00Z", "endDateTime": "2023-01-01T01:00:00Z", "duration": "PT1H"}}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        List<ClockifyService.Parameters> paramsList = new List<ClockifyService.Parameters>();
        ClockifyService.Parameters params = new ClockifyService.Parameters();
        params.pUserID = 'TestUser123';
        paramsList.add(params);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Add assertions
        List<ClockifyTimeEntry__c> entries = [SELECT Id, description__c, Clockify_User__c, Clockify_Project__c, Clockify_Task__c FROM ClockifyTimeEntry__c];
        System.assertEquals(1, entries.size(), 'Expected one time entry to be created.');
        System.assertEquals('sampleDescription', entries[0].description__c, 'Description does not match expected value.');
        System.assertNotEquals(null, entries[0].Clockify_User__c, 'Expected a valid user reference.');
        System.assertNotEquals(null, entries[0].Clockify_Project__c, 'Expected a valid project reference.');
        System.assertNotEquals(null, entries[0].Clockify_Task__c, 'Expected a valid task reference.');
    }

    @isTest
    static void testApiErrorScenario() {
        createSampleData();

        String testUserId = 'testUserID';
        ClockifyService.FetchTimeEntriesJob job = new ClockifyService.FetchTimeEntriesJob(testUserId);

        String responseBody = '{"error": "Some error from Clockify API."}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 500)); // 500 is an example error code


        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Add assertions - no entry should be created in this case
        List<ClockifyTimeEntry__c> entries = [SELECT Id FROM ClockifyTimeEntry__c];
        System.assertEquals(0, entries.size(), 'No entries should be created for an API error.');
    }
}