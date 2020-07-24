public class testvikePDF{

public String getpdf(){
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:testvike');
req.setMethod('GET');
Http http = new Http();
HTTPResponse res = http.send(req);

system.debug(res);
system.debug(EncodingUtil.base64Encode(res.getBodyAsBlob()));

ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        //cv.ContentDocumentId = contentDocumentId;
        cv.VersionData = res.getBodyAsBlob();
        cv.Title = 'testvike';
        cv.PathOnClient = 'testvike.pdf';

        insert cv;
system.debug(cv);
return 'data:application/pdf;base64,'+EncodingUtil.base64Encode(res.getBodyAsBlob());
}
}