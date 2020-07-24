@isTest
global class HTTPPosStatusMockWithNegBodyCallout implements HttpCalloutMock{
	global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        string jsonResBody = 'Not successful';
        res.setBody(jsonResBody);
        res.setStatusCode(200);
        return res;
    }
}