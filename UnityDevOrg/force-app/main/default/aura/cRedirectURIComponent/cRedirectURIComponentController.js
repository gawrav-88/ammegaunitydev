({
	doInit : function(component, event, helper) {
        var base = component.get("v.codeReceived");
		helper.getResponse(component, base);
	}
})