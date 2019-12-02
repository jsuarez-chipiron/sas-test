({
    onWorkAccepted : function(cmp, evt, helper) {
        var workItemId = evt.getParam('workItemId');
        if(workItemId.startsWith('570')){
            let transcriptSet = cmp.get("v.transcriptWaitingForTab");
            transcriptSet.push(workItemId);
            cmp.set("v.transcriptWaitingForTab",transcriptSet);
        }
    }, 
    
    onTabCreated : function(cmp, evt, helper){
        let rootTabId = evt.getParam("tabId");
        let workspaceAPI = cmp.find("workspace");
		workspaceAPI.getTabInfo({tabId: rootTabId}).then(function(tabInfo){
            if(helper.findAndRemoveTranscriptWaitingForTab(cmp,helper,tabInfo.recordId)){
                let action = cmp.get("c.retrieveRelatedCaseId");
                action.setParams({transcriptId : tabInfo.recordId});
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state=="SUCCESS"){
                        console.log(state);
                        let result = response.getReturnValue();
                        if(result!=null)workspaceAPI.openSubtab({parentTabId: rootTabId,recordId:result,focus:false});
                    }
                    else {
                        helper.showErrorToast("Chat Error","Failed to retrieve the related case from the transcript, Server.");
                    }
                });
                $A.enqueueAction(action);
            }
        }).catch(function(error){
            helper.showErrorToast("Chat Error","Failed to get info of recently opened tab : "+error);
        });
    }
})