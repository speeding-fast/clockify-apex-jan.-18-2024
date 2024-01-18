@isTest
private class clockifyGetUsersTest {
    @isTest
    static void testClockifyGetUsers() {
        // Create a mock Clockify Integration record
        bclockify__Clockify_Integration__c mockIntegration = new bclockify__Clockify_Integration__c(
            Name = 'Mock Integration',
            bclockify__API_Key__c = 'your_mock_api_key',
            bclockify__Endpoint__c = 'https://mock.clockify/api',
            bclockify__Workspace_ID__c = 'mockWorkspaceId',
            bclockify__Active__c = true
        );
        insert mockIntegration;

        // Create test data
        String workspaceId = 'TestWorkspaceId';
        ClockifyGetUsers.User testUser = new ClockifyGetUsers.User();
        testUser.id = 'TestId';
        testUser.name = 'Test User';
        testUser.email = 'testuser@example.com';
        String responseBody = JSON.serialize(new List<ClockifyGetUsers.User>{ testUser });

        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));

        // Call the Queueable Apex
        Test.startTest();
        ClockifyGetUsers getUsersJob = new ClockifyGetUsers(workspaceId);
        System.enqueueJob(getUsersJob);
        Test.stopTest();

        // Verify the result
        List<ClockifyUser__c> clockifyUsers = [SELECT Id, Name, UserId__c, Email__c FROM ClockifyUser__c];
        System.assertEquals(1, clockifyUsers.size(), 'Expected one ClockifyUser__c record to be created.');

        ClockifyUser__c user = clockifyUsers[0];
        System.assertEquals('Test User', user.Name, 'Unexpected user name.');
        System.assertEquals('TestId', user.UserId__c, 'Unexpected user ID.');
        System.assertEquals('testuser@example.com', user.Email__c, 'Unexpected email.');
    }
}