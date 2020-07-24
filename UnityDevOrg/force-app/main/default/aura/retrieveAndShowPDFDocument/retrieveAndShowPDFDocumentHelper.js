({
    showDocument: function(component, recordId){
        var navService = component.find("navService");      
        
        var pageReference = {             
            type: 'standard__recordPage',             
            attributes: {             
                recordId: recordId,         
                objectApiName: 'ContentDocument',             
                actionName: 'view'         
            }     
        };
      
        navService.navigate(pageReference); 
    },

    showToast: function (title, type, message) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'title': title,
            'type': type,
            'message': message
        });
        toastEvent.fire();
    }
})