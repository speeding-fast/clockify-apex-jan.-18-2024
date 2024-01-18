// Helper class to generate mock HTTP responses
public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseBody);
        res.setStatusCode(statusCode);
        return res;
    }
    
    private Integer statusCode;
    private String responseBody;

    public MockHttpResponseGenerator(String responseBody, Integer statusCode) {
        this.responseBody = responseBody;
        this.statusCode = statusCode;
    }
}