@isTest
global class HTTPFilePositiveMockCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        string jsonResBody = '{ "label": "Spring \'17",  "url": "/services/data/v39.0","version": "39.0"}';
        //string jsonResBodyError = 'Error: The remote server returned an unexpected response: (502) Proxy Error ( The host was not found. ).';
        res.setBody(jsonResBody);
        //res.setBody(jsonResBodyError);
        res.setStatusCode(200);
        return res;
    }
}