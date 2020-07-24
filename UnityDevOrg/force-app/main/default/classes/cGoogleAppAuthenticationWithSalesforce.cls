public class cGoogleAppAuthenticationWithSalesforce {
    
    //Client ID to identify the app being used to connect to google drive.
    //for example any app being used to connect google drive for any purpose having these cilent ID and secret
    private string key = '79843965185-qpk3sjema3ojmpp0t3p0m5qdev9u03uh.apps.googleusercontent.com';
    private string secret = 'teD312ki7_nyg8pf0lZBIZcR';
    //After receiving Authentication token for the app , will be redirectedd to this URL and one parameter in the URL will have to receive
    private string redirect_uri = 'https://'+System.Url.getSalesforceBaseUrl().getHost()+'/apex/GoogleDriveIntegration';
    //afetr authentication it will return a token and App Authentication token is stored in this variable
    private string gDriveIdentificationToken;
    //This is the authentication token after username and password
    //After App authentication by app user will have to provide its own google user name and password 
    //which is different from App created for client id and client secret
    //for Example you have one google ID as admin@gmail.com and using this you created one app
    //now you wants to fetch files for user@gmail.com from google drive
    //so Client secret is created by admin@gmail.com and access token is received for user@gmail.com
    private string access_token ;
	private List<String> FileLst;
    public Map<String,String> FileIdAndNameMapFortheAccount{get;set;}
    public String BASE64_ENCODED_BLOB {get;set;}
    public static Integer noOfLoad = 0;
    public String BASE64_ENCODED_BLOB_FINAL;
    
    //visualforce uses below methods
    public cGoogleAppAuthenticationWithSalesforce(ApexPages.StandardController std){
        gDriveIdentificationToken = ApexPages.currentPage().getParameters().get('code');
        
        FileLst=new List<String>();
        FileIdAndNameMapFortheAccount=new Map<String,String>();
        
        if(noOfLoad == 0){
            noOfLoad = noOfLoad++;
            DriveAuth();
        }
        system.debug('noOfLoad-->'+noOfLoad);
        if(gDriveIdentificationToken != '' && gDriveIdentificationToken != null){
            AccessToken();
        }
    }
    
    public PageReference DriveAuth(){
        PageReference pg = new PageReference(new cAuthURIForAPIReq(key, redirect_uri).AuthenticationURI);
        return pg;
    }
    
    public void AccessToken(){
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'code='+gDriveIdentificationToken+'&client_id='+key+'&client_secret='+secret+'&redirect_uri='+redirect_uri+'&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60*1000);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        JSONParser parser = JSON.createParser(res.getBody());
        
        while(parser.nextToken() != null){
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'access_token'){
                parser.nextToken();
                access_token = parser.getText();
                break;
            }
        }
        if(access_token != '' && access_token != null){
            ListFiles();
        }
    }
    
    public PageReference ListFiles(){
        String FolderId = '1qwzYcn31dPV0n-g_nG4pFpGUej12Bliq';
        
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('GET');
        req1.setEndpoint('https://www.googleapis.com/drive/v2/files/'+FolderId+'/children');
        req1.setHeader('content-type', 'application/x-www-form-urlencoded');
        req1.setHeader('Content-length', '0');
        req1.setHeader('Authorization', 'Bearer'+' '+access_token);
        req1.setTimeout(60*1000);
        
        Http h1 = new Http();
        HttpResponse res1 = h1.send(req1);
        JSONParser parserD = JSON.createParser(res1.getBody());
        while (parserD.nextToken() != null) 
        {
            if ((parserD.getCurrentToken() == JSONToken.FIELD_NAME) && (parserD.getText() == 'id'))
            {
                parserD.nextToken();
                FileLst.add(parserD.getText());
            }
        }
       Map<String,String> FileIdAndNameMap=FileProperties();
        for(String s:FileLst)
        {
            FileIdAndNameMapFortheAccount.put(s, FileIdAndNameMap.get(s));
        }
        return null;
    }
    
    public  Map<String,String> FileProperties()
    {
        Map<String,String> FilePropertiesDetails=new Map<String,String>();
        HttpRequest req2 = new HttpRequest();
        req2.setMethod('GET');
        //End point URL for All the files in the drive and its ID,Name value in JSON Response
        req2.setEndpoint('https://www.googleapis.com/drive/v3/files');
        req2.setHeader('content-type', 'application/x-www-form-urlencoded');
        req2.setHeader('Content-length', '0');
        req2.setHeader('Authorization' , 'Bearer'+' '+ access_token);
        req2.setTimeout(60*1000);
        Http h3 = new Http();
        HttpResponse resls = h3.send(req2);
        System.debug('^^^^^'+resls.getBody());
        JSONParser parserDr = JSON.createParser(resls.getBody());
        while (parserDr.nextToken() != null) 
        {   
            String FileName='';
            String FileId='';
            if ((parserDr.getCurrentToken() == JSONToken.FIELD_NAME))
            {
                //First TOKEN is Id
                if((parserDr.getText() == 'id'))
                {
                    parserDr.nextToken();               
                    Fileid=parserDr.getText();
                }
                //Moving to Next Parser
                parserDr.nextToken();
                //Next Token is Name
                if((parserDr.getText() == 'name'))
                {
                    parserDr.nextToken();
                    Filename=parserDr.getText();
                }
                FilePropertiesDetails.put(Fileid, Filename);
            }
        }
        return FilePropertiesDetails;
    }
    // end of methods used by visualforce
    
    //Methods to call while using lightning component
	@AuraEnabled
    public static String getAccessToken(String code){
        system.debug('String code is-->'+code);
        
        string key = '79843965185-i50enj3mfjd8afitvtsmpbdr8lgffc46.apps.googleusercontent.com';
        string secret = 'o044sYZoBg99MfbXC974cuWw';
        //string redirect_uri = 'https://'+System.Url.getSalesforceBaseUrl().getHost()+'/lightning/cmp/c__cRedirectURIComponent';
        string redirect_uri = 'https://ammega--dev.lightning.force.com/c/TestApp.app';
        system.debug('redirect_uri-->'+redirect_uri);
        String access_token;
        String BASE64_ENCODED_BLOB_FINAL;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'code='+code+'&client_id='+key+'&client_secret='+secret+'&redirect_uri='+redirect_uri+'&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60*1000);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        
        if(res.getStatusCode()!=200){
            system.debug('Error in getting access token-->'+res.getStatusCode()+' : '+res.getStatus());
        }
        
        JSONParser parser = JSON.createParser(res.getBody());
        
        while(parser.nextToken() != null){
            system.debug('parser.getText()-->'+parser.getText());
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'access_token'){
                parser.nextToken();
                access_token = parser.getText();
                break;
            }
        }
        if(access_token != '' && access_token != null){
            BASE64_ENCODED_BLOB_FINAL = GetFile(access_token);
        }
        return BASE64_ENCODED_BLOB_FINAL;
    }

    @AuraEnabled
    public static String GetFile(String access_token){
        String FileId = '1HN1DA8jYxRxn9BGxJGbYrKUl4gOANLWA';
        String BASE64_ENCODED_BLOB;
        
        HttpRequest req2 = new HttpRequest();
        req2.setMethod('GET');
        req2.setEndpoint('https://www.googleapis.com/drive/v3/files/'+FileId+'?alt=media');
        req2.setHeader('content-type', 'application/json');
        req2.setHeader('Content-length', '0');
        req2.setHeader('Authorization', 'Bearer'+' '+access_token);
        req2.setTimeout(60*1000);
        
        Http h2 = new Http();
        HttpResponse res2 = h2.send(req2);
        system.debug('Response body with the file-->'+res2.getBody());
        BASE64_ENCODED_BLOB = EncodingUtil.base64Encode(res2.getBodyasBlob());
        return BASE64_ENCODED_BLOB;
    }
}