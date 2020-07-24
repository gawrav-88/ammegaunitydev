({
    getResponse : function(component, base) {
        // create a server side action.     
        var action = component.get("c.getAccessToken");
        // set the url parameter for getCalloutResponseContents method (to use as endPoint) 
        action.setParams({
            "code": base
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                //create a pdfViewer component on the go
                $A.createComponent(
                    "c:pdfViewer",
                    {
                        "pdfData": response.getReturnValue()
                    },
                    function(pdfViewer, status, errorMessage){
                        if (status === "SUCCESS") {
                            var pdfContainer = component.get("v.pdfContainer");
                            pdfContainer.push(pdfViewer);
                            component.set("v.pdfContainer", pdfContainer);
                        }
                        else if (status === "INCOMPLETE") {
                            console.log("No response from server or client is offline.")
                        }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                            }
                    }
                );
            }
        });
        
        $A.enqueueAction(action);
    }
})