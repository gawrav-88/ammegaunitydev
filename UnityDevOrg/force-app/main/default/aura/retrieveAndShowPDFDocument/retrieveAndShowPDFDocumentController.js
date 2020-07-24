({
    init : function(component, event, helper) {
        var action = component.get('c.getDocumentId');

        action.setParams({
            'currentRecordId': component.get('v.recordId'),
        });

        action.setCallback(this, function (response) {

            if (response.getState() === 'SUCCESS') {
                var documentId = response.getReturnValue();
                component.set('v.loaded', true);
                component.set('v.documentId', documentId);

                helper.showDocument(component, documentId);
            } else {
                var errors = response.getError();
                if (!Array.isArray(errors) || !errors.length){
                    helper.showToast('Error occured', 'error', 'Oops. Something went wrong');
                } else {
                    helper.showToast('Error occured', 'error', errors[0].message);
                }
            }
        });

        $A.enqueueAction(action);
    }
})