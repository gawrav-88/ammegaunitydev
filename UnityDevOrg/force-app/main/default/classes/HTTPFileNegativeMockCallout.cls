@isTest
global class HTTPFileNegativeMockCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        string jsonResBody = '';
        res.setBody(jsonResBody);
        res.setStatusCode(500);
        return res;
    }
}