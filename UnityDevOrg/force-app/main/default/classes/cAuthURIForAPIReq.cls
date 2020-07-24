global class cAuthURIForAPIReq {
    //unused scope that was changed
    global String AuthenticationURI='';
    
    public cAuthURIForAPIReq(String ClientKey, String redirect_uri){
        String key = EncodingUtil.urlEncode(ClientKey, 'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri, 'UTF-8');
        String authuri = 'https://accounts.google.com/o/oauth2/v2/auth?'+
            'response_type=code&'+
            'client_id='+key+'&'+
            'scope=openid%20email%20https://www.googleapis.com/auth/drive%20https://www.googleapis.com/auth/drive.file&'+
            'redirect_uri='+uri+'&'+//oauth2.example.com/callback&
            'state=security_token%3D138r5719ru3e1%26url%3Dhttps%3A%2F%2Foauth2-login-demo.example.com%2FmyHome&'+
            'login_hint=jsmith@example.com&'+
            'access+type=offline';
        AuthenticationURI = authuri;
    }
}