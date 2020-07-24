({
    init : function(component, event, helper) {
        //get base url
        var urlString = window.location.href;
        //var baseURL = urlString.substring(0,urlString.indexOf('/r'));
        var baseURL = urlString.substring(0,urlString.indexOf('/l'));
        
        var ClientKey = '79843965185-i50enj3mfjd8afitvtsmpbdr8lgffc46.apps.googleusercontent.com';
        //var redirect_uri = baseURL+'/cmp/c__cRedirectURIComponent';
        var redirect_uri = baseURL+'/c/TestApp.app';
        
        var authuri = 'https://accounts.google.com/o/oauth2/v2/auth?'+
            'response_type=code&'+
            'client_id='+ClientKey+'&'+
            'scope=openid%20email%20https://www.googleapis.com/auth/drive%20https://www.googleapis.com/auth/drive.file&'+
            'redirect_uri='+redirect_uri+'&'+//oauth2.example.com/callback&
            'state=security_token%3D138r5719ru3e1%26url%3Dhttps%3A%2F%2Foauth2-login-demo.example.com%2FmyHome&'+
            'login_hint=jsmith@example.com&'+
            'access+type=offline';
        window.open(authuri);
    }
})